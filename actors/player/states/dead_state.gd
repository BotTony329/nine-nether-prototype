class_name DeadState
extends PlayerState
## Terminal. The run is over; RunCoordinator decides what happens next.

func id() -> StringName:
	return DEAD

func enter() -> void:
	player.input_enabled = false
	player.velocity = Vector2.ZERO
	player.attack_hitbox.set_active(false)
	player.play(&"player_death")
	player.sprite.frame = 0

func physics_update(delta: float) -> StringName:
	player.apply_gravity(delta)
	player.decelerate(delta)
	return &""
