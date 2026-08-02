class_name GhostArcher
extends EnemyBase
## Concrete ranged enemy. EnemyBase's frozen states map to:
## IDLE=patrol, CHASE=spacing/reposition, WINDUP=aim, ATTACK=shoot,
## RECOVER=post-shot recovery/cooldown.

signal arrow_fired(arrow: GhostArrow)

@export var archer_config: GhostArcherConfig

var _patrol_origin_x: float
var _patrol_direction: int = 1


func _ready() -> void:
	super._ready()
	# This archetype deals damage only through GhostArrow.
	attack_hitbox.collision_mask = 0
	attack_hitbox.set_active(false)


func initialize(enemy_config: EnemyConfig, target: Node2D) -> void:
	_patrol_origin_x = global_position.x
	super.initialize(enemy_config, target)


func _enter_state(next: int) -> void:
	super._enter_state(next)
	if next == State.ATTACK:
		attack_hitbox.set_active(false)
		_shoot()


func _update_state(delta: float) -> void:
	match _state:
		State.IDLE:
			_patrol()
			if _target_in_range(config.detection_range):
				change_state(State.CHASE)
		State.CHASE:
			_update_spacing(delta)
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
				change_state(State.CHASE if _target_in_range(config.detection_range) else State.IDLE)
		State.HURT:
			_decelerate(delta)
			if _state_elapsed >= config.hurt_duration:
				change_state(State.CHASE if _target_in_range(config.detection_range) else State.IDLE)
		State.DEAD:
			pass


func _patrol() -> void:
	if archer_config == null:
		velocity.x = 0.0
		return
	if is_on_wall() or absf(global_position.x - _patrol_origin_x) >= archer_config.patrol_radius:
		_patrol_direction *= -1
	_facing = _patrol_direction
	sprite.flip_h = _facing < 0
	velocity.x = _facing * config.move_speed * archer_config.patrol_speed_multiplier


func _update_spacing(delta: float) -> void:
	if archer_config == null or not _target_in_range(config.detection_range):
		change_state(State.IDLE)
		return
	_face_target()
	var distance := _distance_to_target()
	if distance < archer_config.retreat_distance:
		velocity.x = -_facing * config.move_speed
		return
	if distance > archer_config.preferred_distance:
		velocity.x = _facing * config.move_speed
		return
	_decelerate(delta)
	if distance <= config.attack_range and _cooldown <= 0.0:
		change_state(State.WINDUP)


func _shoot() -> void:
	if _is_dead or archer_config == null or archer_config.projectile_scene == null:
		return
	if _target == null or not is_instance_valid(_target):
		return
	var arrow := archer_config.projectile_scene.instantiate() as GhostArrow
	if arrow == null:
		return
	var spawn_offset := archer_config.projectile_spawn_offset
	spawn_offset.x *= _facing
	var spawn_position := global_position + spawn_offset
	var direction := (_target.global_position - spawn_position).normalized()
	arrow.configure(
		actor_id(),
		self,
		direction,
		config.attack_damage,
		config.attack_skill_multiplier,
		archer_config.projectile_speed,
		archer_config.projectile_lifetime
	)
	get_parent().add_child(arrow)
	arrow.global_position = spawn_position
	arrow_fired.emit(arrow)
