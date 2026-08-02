class_name BossActor
extends EnemyBase
## Prototype Boss — 镇关鬼将, the Gate Guardian Ghost General.
##
## Deliberately thin: it is an EnemyBase with boss-scale numbers, its own
## lifecycle events and a health bar. There is no second combat system, no
## second state machine and no phase controller in M1.
##
## Why only one attack: `assets/boss/` ships exactly one attack sheet
## (boss_attack.png, 5 frames). The Prototype Development Pack asks for three
## moves and two phases, and the M1 brief gates the second move on the art
## supporting it. It does not, so the charge and the ground slam are left to
## Codex X04 rather than faked by replaying the run cycle. See
## docs/AI_HANDOFF.md, "Asset integration gaps".
##
## Extension point for X04: add moves as EnemyConfig-driven AttackDefinitions
## selected by an AttackScheduler here. Do not modify EnemyBase or
## CombatResolver to do it.

signal defeated(boss: BossActor)

const ACTIVE_FIRST_FRAME := 4
const ACTIVE_LAST_FRAME := 5

var _death_source_id: StringName = &"unknown"
var _boss_death_published: bool = false


func _ready() -> void:
	super._ready()
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.frame_changed.connect(_sync_attack_window)

func start_encounter() -> void:
	EventBus.boss_started.emit(
		EventBus.context({"actor_id": actor_id(), "max_hp": max_hp()})
	)

func _publish_death(source_id: StringName) -> void:
	# EnemyBase owns idempotent death. Completion waits for the authored
	# collapse so the victory screen cannot cover its first frame.
	_death_source_id = source_id


func _enter_state(next: int) -> void:
	match next:
		State.IDLE:
			sprite.play(&"gate_warden_idle")
		State.CHASE:
			sprite.play(&"gate_warden_walk")
		State.WINDUP:
			attack_hitbox.set_active(false)
			sprite.modulate = Color.WHITE
			sprite.play(&"gate_warden_attack_1")
			sprite.frame = 0
		State.ATTACK:
			_sync_attack_window()
		State.RECOVER:
			attack_hitbox.set_active(false)
		State.HURT:
			attack_hitbox.set_active(false)
			sprite.play(&"gate_warden_hurt")
			sprite.frame = 0
		State.DEAD:
			attack_hitbox.set_active(false)
			sprite.play(&"gate_warden_death")
			sprite.frame = 0


func _exit_state(_previous: int) -> void:
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
			if sprite.frame >= ACTIVE_FIRST_FRAME:
				change_state(State.ATTACK)
		State.ATTACK:
			_decelerate(delta)
			if sprite.frame > ACTIVE_LAST_FRAME:
				change_state(State.RECOVER)
		State.RECOVER:
			_decelerate(delta)
			if not sprite.is_playing():
				_cooldown = config.attack_cooldown
				change_state(State.IDLE)
		State.HURT:
			_decelerate(delta, 400.0)
			if not sprite.is_playing():
				change_state(State.CHASE if _target_in_range(config.detection_range) else State.IDLE)
		State.DEAD:
			pass


func _sync_attack_window() -> void:
	var active := (
		not _is_dead
		and sprite.animation == &"gate_warden_attack_1"
		and sprite.frame >= ACTIVE_FIRST_FRAME
		and sprite.frame <= ACTIVE_LAST_FRAME
	)
	attack_hitbox.set_active(active)


func _on_animation_finished() -> void:
	if _state != State.DEAD or _boss_death_published:
		return
	_boss_death_published = true
	EventBus.boss_died.emit(
		EventBus.context({"actor_id": actor_id(), "source_id": _death_source_id})
	)
	defeated.emit(self)
