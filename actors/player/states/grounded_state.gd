class_name GroundedState
extends PlayerState
## On the floor: idle, run, jump and attack all start here.

func id() -> StringName:
	return GROUNDED

func enter() -> void:
	player.play(&"idle")

func physics_update(delta: float) -> StringName:
	player.apply_gravity(delta)
	player.apply_horizontal_input()

	if wants_attack():
		return ATTACKING
	if player.input_enabled and Input.is_action_just_pressed(&"jump"):
		player.jump()
		return AIRBORNE
	if not player.is_on_floor():
		return AIRBORNE

	player.play(&"run" if player.input_direction() != 0 else &"idle")
	return &""
