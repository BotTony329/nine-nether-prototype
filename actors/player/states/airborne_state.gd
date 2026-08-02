class_name AirborneState
extends PlayerState
## Rising or falling. Air control is reduced but attacking stays available so
## the player is never fully passive mid-jump.

func id() -> StringName:
	return AIRBORNE

func enter() -> void:
	player.play(&"player_jump")

func physics_update(delta: float) -> StringName:
	player.apply_gravity(delta)
	player.apply_horizontal_input(player.balance().player_air_control)
	player.play(&"player_jump" if player.velocity.y < 0.0 else &"player_fall")

	if wants_attack():
		return ATTACKING
	if player.is_on_floor():
		return GROUNDED
	return &""
