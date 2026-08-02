class_name Player
extends CharacterBody2D
## Player actor. Holds movement, animation and hit resolution; the decision of
## *which* of those to run belongs to the state machine in states/.
##
## The player has no HP of its own. Current and maximum lifespan live in
## RunState, which is injected by RunCoordinator via `setup`. That keeps one
## authoritative copy of the run's numbers and means a sacrifice applied from
## the UI is visible here without any syncing.

const ACTOR_ID := &"player"

signal died

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var attack_hitbox: Hitbox = $AttackHitbox
@onready var camera: Camera2D = $Camera

var input_enabled: bool = true

var _run_state: RunState
var _balance: BalanceConfig
var _machine: PlayerStateMachine
var _facing: int = 1
var _invulnerable_for: float = 0.0
var _stamina_delay_for: float = 0.0
var _spawn_point: Vector2 = Vector2.ZERO

func _ready() -> void:
	attack_hitbox.hit_actor.connect(_on_attack_connected)
	attack_hitbox.set_active(false)

## Injects the run this player belongs to. Must be called before the first
## physics frame; RunCoordinator does it at spawn time.
func setup(run_state: RunState, balance: BalanceConfig) -> void:
	_run_state = run_state
	_balance = balance
	_spawn_point = global_position
	_machine = PlayerStateMachine.new(self)

func run_state() -> RunState:
	return _run_state

func balance() -> BalanceConfig:
	return _balance

func facing() -> int:
	return _facing

func state_id() -> StringName:
	return _machine.current_id() if _machine != null else &"uninitialised"

func is_dead() -> bool:
	return _run_state != null and not _run_state.is_alive()

func is_invulnerable() -> bool:
	return _invulnerable_for > 0.0


func _physics_process(delta: float) -> void:
	if _machine == null:
		return
	_invulnerable_for = maxf(0.0, _invulnerable_for - delta)
	_tick_stamina(delta)
	_machine.physics_update(delta)
	move_and_slide()


# --- shared movement helpers used by the states -----------------------------

func apply_gravity(delta: float) -> void:
	velocity.y = minf(
		velocity.y + _balance.player_gravity * delta, _balance.player_max_fall_speed
	)

## `control` scales the input authority: 1.0 on the ground, less in the air.
func apply_horizontal_input(control: float = 1.0) -> void:
	var direction := input_direction()
	velocity.x = direction * _balance.player_move_speed * control
	if direction != 0:
		set_facing(direction)

func input_direction() -> int:
	if not input_enabled:
		return 0
	return int(Input.get_axis(&"move_left", &"move_right"))

func set_facing(direction: int) -> void:
	if direction == 0:
		return
	_facing = signi(direction)
	sprite.flip_h = _facing < 0
	# The attack box is authored facing right; mirror it with the sprite.
	attack_hitbox.scale.x = absf(attack_hitbox.scale.x) * _facing

func jump() -> void:
	velocity.y = _balance.player_jump_velocity

func decelerate(delta: float, rate: float = 600.0) -> void:
	velocity.x = move_toward(velocity.x, 0.0, rate * delta)

func play(animation: StringName) -> void:
	if sprite.animation != animation:
		sprite.play(animation)

func animation_finished() -> bool:
	return not sprite.is_playing()


# --- Damageable shape -------------------------------------------------------
# Mirrors EnemyBase so an attacker can hit either side without special-casing.

func actor_id() -> StringName:
	return ACTOR_ID

func armour() -> float:
	return _run_state.armour() if _run_state != null else 0.0

func current_hp() -> float:
	return _run_state.current_hp() if _run_state != null else 0.0


## Resolves one incoming attack. `context` is built by the attacker; this method
## does not invent damage, it only applies what CombatResolver returned.
func receive_damage(context: DamageContext) -> DamageResult:
	var result := GameData.combat.resolve(context)
	if is_dead() or is_invulnerable():
		result.final_damage = 0.0
		result.is_lethal = false
		return result
	_run_state.apply_damage(result.final_damage)
	_invulnerable_for = _balance.player_invulnerable_after_hit
	EventBus.hit_taken.emit(EventBus.context(result.to_dictionary()))
	if _run_state.is_alive():
		_machine.on_hurt(context.source_id)
	else:
		_machine.on_death()
		EventBus.player_died.emit(EventBus.context({"source_id": context.source_id}))
		died.emit()
	return result

func knockback_from(source_position: Vector2) -> void:
	var direction := signf(global_position.x - source_position.x)
	if is_zero_approx(direction):
		direction = -_facing
	velocity.x = direction * _balance.player_hurt_knockback

## Debug-only teleport back to the spawn marker without restarting the run.
func return_to_spawn() -> void:
	global_position = _spawn_point
	velocity = Vector2.ZERO


func _on_attack_connected(target: Node) -> void:
	if not target.has_method("receive_damage"):
		return
	var context := GameData.combat.player_attack_context(
		_run_state,
		target.call("actor_id"),
		float(target.call("armour")),
		float(target.call("current_hp")),
		_balance.light_attack_skill_multiplier
	)
	var result: DamageResult = target.call("receive_damage", context)
	EventBus.hit_dealt.emit(EventBus.context(result.to_dictionary()))


## Stamina is a structural resource in M1: nothing spends it yet (light attack
## costs 0 by design, section 6.1) but it regenerates and the HUD shows it, so
## a sacrifice that cuts max stamina is visible immediately. Dodge and heavy
## attack, the first real consumers, are Codex work.
func _tick_stamina(delta: float) -> void:
	if _run_state == null:
		return
	_stamina_delay_for = maxf(0.0, _stamina_delay_for - delta)
	if _stamina_delay_for > 0.0:
		return
	_run_state.regenerate_stamina(_run_state.stamina_recovery() * delta)

func spend_stamina(amount: float) -> void:
	if amount <= 0.0:
		return
	_run_state.spend_stamina(amount)
	_stamina_delay_for = _balance.stamina_recovery_delay
