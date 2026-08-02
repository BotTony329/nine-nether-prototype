class_name MeleeGhost
extends EnemyBase
## V2 visual specialization of EnemyBase. The existing AI states and damage
## path remain intact; authored animation frames only gate the existing hitbox.

const ACTIVE_FIRST_FRAME := 4
const ACTIVE_LAST_FRAME := 5


func _ready() -> void:
	super._ready()
	sprite.frame_changed.connect(_sync_attack_window)


func _enter_state(next: int) -> void:
	match next:
		State.IDLE:
			_play(&"melee_ghost_idle")
		State.CHASE:
			_play(&"melee_ghost_walk")
		State.WINDUP:
			attack_hitbox.set_active(false)
			sprite.modulate = Color.WHITE
			sprite.play(&"melee_ghost_attack")
			sprite.frame = 0
		State.ATTACK:
			_sync_attack_window()
		State.RECOVER:
			attack_hitbox.set_active(false)
		State.HURT:
			attack_hitbox.set_active(false)
			sprite.play(&"melee_ghost_hurt")
			sprite.frame = 0
		State.DEAD:
			attack_hitbox.set_active(false)
			sprite.play(&"melee_ghost_death")
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
		and sprite.animation == &"melee_ghost_attack"
		and sprite.frame >= ACTIVE_FIRST_FRAME
		and sprite.frame <= ACTIVE_LAST_FRAME
	)
	attack_hitbox.set_active(active)
