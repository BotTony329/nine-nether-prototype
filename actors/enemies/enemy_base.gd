class_name EnemyBase
extends CharacterBody2D
## Shared contract for every hostile actor, including the Boss.
##
## Contract (frozen — see docs/INTERFACES.md):
##   initialize / acquire_target / change_state / receive_damage / die
##
## Rules a concrete enemy must not break:
##   * Damage is resolved by CombatResolver. Do not compute it here or in a
##     subclass — build a DamageContext and let the resolver answer.
##   * `die` is idempotent. A second hit landing in the same frame, or a DoT
##     tick arriving after death, must not fire a second death event.
##   * Enemies never touch RunState's structural values or the sacrifice
##     system. They ask the target for its armour and current HP, nothing more.
##
## Implements the Damageable shape: actor_id / armour / current_hp /
## receive_damage.

signal died(enemy: EnemyBase)

enum State { IDLE, CHASE, WINDUP, ATTACK, RECOVER, HURT, DEAD }

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var attack_hitbox: Hitbox = $AttackHitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var body_shape: CollisionShape2D = $Body

var config: EnemyConfig

var _current_hp: float = 0.0
var _state: int = State.IDLE
var _state_elapsed: float = 0.0
var _cooldown: float = 0.0
var _facing: int = -1
var _target: Node2D
var _is_dead: bool = false
var _initialised: bool = false


func _ready() -> void:
	attack_hitbox.hit_actor.connect(_on_attack_connected)
	attack_hitbox.set_active(false)


## Must be called before the enemy takes its first physics step. Spawners do
## this immediately after `add_child`.
func initialize(enemy_config: EnemyConfig, target: Node2D) -> void:
	config = enemy_config
	_current_hp = config.max_hp
	_target = target
	_initialised = true
	change_state(State.IDLE)


func acquire_target(target: Node2D) -> void:
	_target = target


func actor_id() -> StringName:
	return config.actor_id if config != null else &"enemy"

func armour() -> float:
	return config.armour if config != null else 0.0

func current_hp() -> float:
	return _current_hp

func max_hp() -> float:
	return config.max_hp if config != null else 0.0

func hp_ratio() -> float:
	if config == null or config.max_hp <= 0.0:
		return 0.0
	return clampf(_current_hp / config.max_hp, 0.0, 1.0)

func is_dead() -> bool:
	return _is_dead

func state() -> int:
	return _state


func _physics_process(delta: float) -> void:
	if not _initialised:
		return
	if _is_dead:
		# A corpse has no body collider, so running gravity and move_and_slide
		# would drop it through the floor while the death animation plays.
		_state_elapsed += delta
		if _state_elapsed >= config.death_duration:
			queue_free()
		return
	_apply_gravity(delta)
	_cooldown = maxf(0.0, _cooldown - delta)
	_state_elapsed += delta
	_update_state(delta)
	move_and_slide()


## Single entry point for transitions, so enter-effects cannot be skipped.
func change_state(next: int) -> void:
	if _state == next:
		return
	_exit_state(_state)
	_state = next
	_state_elapsed = 0.0
	_enter_state(next)


## Resolves one incoming attack and applies the result. Returns the result so
## the attacker can report it — the attacker does not get to decide the number.
func receive_damage(context: DamageContext) -> DamageResult:
	var result := GameData.combat.resolve(context)
	if _is_dead:
		result.final_damage = 0.0
		result.is_lethal = false
		return result
	_current_hp = maxf(0.0, _current_hp - result.final_damage)
	if _current_hp <= 0.0:
		die(context.source_id)
	else:
		change_state(State.HURT)
	return result


## Idempotent. The `_is_dead` guard is the reason a second lethal hit in the
## same frame cannot produce two death events or two sets of rewards.
func die(source_id: StringName = &"unknown") -> void:
	if _is_dead:
		return
	_is_dead = true
	_current_hp = 0.0
	velocity = Vector2.ZERO
	attack_hitbox.set_active(false)
	hurtbox.set_deferred(&"monitorable", false)
	body_shape.set_deferred(&"disabled", true)
	change_state(State.DEAD)
	_publish_death(source_id)
	died.emit(self)


# --- internals --------------------------------------------------------------

func _publish_death(source_id: StringName) -> void:
	EventBus.enemy_died.emit(
		EventBus.context({"actor_id": actor_id(), "source_id": source_id})
	)


func _apply_gravity(delta: float) -> void:
	velocity.y = minf(velocity.y + config.gravity * delta, config.max_fall_speed)


func _enter_state(next: int) -> void:
	match next:
		State.IDLE:
			_play(&"idle")
		State.CHASE:
			_play(&"run")
		State.WINDUP:
			_play(&"attack")
			sprite.frame = 0
			sprite.pause()
			sprite.modulate = config.telegraph_tint
		State.ATTACK:
			sprite.modulate = Color.WHITE
			sprite.play(&"attack")
			attack_hitbox.set_active(true)
		State.RECOVER:
			attack_hitbox.set_active(false)
		State.HURT:
			_play(&"hurt")
			sprite.frame = 0
		State.DEAD:
			_play(&"death")
			sprite.frame = 0


func _exit_state(previous: int) -> void:
	if previous == State.WINDUP:
		sprite.modulate = Color.WHITE
	if previous == State.ATTACK:
		attack_hitbox.set_active(false)


func _update_state(delta: float) -> void:
	match _state:
		State.IDLE:
			_decelerate(delta)
			if _target_in_range(config.detection_range):
				change_state(State.CHASE)
		State.CHASE:
			_chase(delta)
		State.WINDUP:
			_decelerate(delta)
			_face_target()
			if _state_elapsed >= config.attack_windup:
				change_state(State.ATTACK)
		State.ATTACK:
			_decelerate(delta)
			if _state_elapsed >= config.attack_active:
				change_state(State.RECOVER)
		State.RECOVER:
			_decelerate(delta)
			if _state_elapsed >= config.attack_recovery:
				_cooldown = config.attack_cooldown
				change_state(State.IDLE)
		State.HURT:
			_decelerate(delta, 400.0)
			if _state_elapsed >= config.hurt_duration:
				change_state(State.CHASE if _target_in_range(config.detection_range) else State.IDLE)
		State.DEAD:
			pass


func _chase(delta: float) -> void:
	if not _target_in_range(config.detection_range):
		change_state(State.IDLE)
		return
	_face_target()
	var distance := _distance_to_target()
	if distance <= config.attack_range and _cooldown <= 0.0:
		change_state(State.WINDUP)
		return
	if distance <= config.preferred_gap:
		_decelerate(delta)
		return
	velocity.x = _facing * config.move_speed


func _decelerate(delta: float, rate: float = 600.0) -> void:
	velocity.x = move_toward(velocity.x, 0.0, rate * delta)


func _distance_to_target() -> float:
	if _target == null:
		return INF
	return absf(_target.global_position.x - global_position.x)


func _target_in_range(range_px: float) -> bool:
	if _target == null or not is_instance_valid(_target):
		return false
	return global_position.distance_to(_target.global_position) <= range_px


func _face_target() -> void:
	if _target == null:
		return
	var direction := signi(int(_target.global_position.x - global_position.x))
	if direction == 0:
		return
	_facing = direction
	# Every sheet in assets/ is authored facing right (docs/ART_SPEC.md).
	sprite.flip_h = _facing < 0
	attack_hitbox.scale.x = absf(attack_hitbox.scale.x) * _facing


func _play(animation: StringName) -> void:
	if sprite.animation != animation or not sprite.is_playing():
		sprite.play(animation)


func _on_attack_connected(target: Node) -> void:
	if _is_dead or not target.has_method("receive_damage"):
		return
	var context := DamageContext.new()
	context.source_id = actor_id()
	context.target_id = target.call("actor_id")
	context.base_damage = config.attack_damage
	context.skill_multiplier = config.attack_skill_multiplier
	context.crit_allowed = false
	context.target_armour = float(target.call("armour"))
	context.target_current_hp = float(target.call("current_hp"))
	context.tags = [&"melee"] as Array[StringName]
	target.call("receive_damage", context)
