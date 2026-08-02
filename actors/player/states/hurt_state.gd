class_name HurtState
extends PlayerState
## Brief stagger after taking a hit. Input is ignored for the duration, which is
## what makes damage cost tempo as well as lifespan.

var _remaining: float = 0.0

func id() -> StringName:
	return HURT

func enter() -> void:
	_remaining = player.balance().player_hurt_duration
	player.play(&"player_hurt")
	player.sprite.frame = 0

func physics_update(delta: float) -> StringName:
	player.apply_gravity(delta)
	player.decelerate(delta, 300.0)
	_remaining -= delta
	if _remaining <= 0.0:
		return GROUNDED if player.is_on_floor() else AIRBORNE
	return &""
