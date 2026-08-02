class_name AttackingState
extends PlayerState
## V2 light attack. The authored frame map is authoritative:
## startup 0–3, active 4–5, recovery 6–7.

const ACTIVE_FIRST_FRAME := 4
const ACTIVE_LAST_FRAME := 5

func id() -> StringName:
	return ATTACKING

func enter() -> void:
	player.attack_hitbox.set_active(false)
	if not player.sprite.frame_changed.is_connected(_sync_attack_window):
		player.sprite.frame_changed.connect(_sync_attack_window)
	player.play(&"player_light_attack_1")
	player.sprite.frame = 0
	player.spend_stamina(player.balance().light_attack_stamina_cost)

func exit() -> void:
	if player.sprite.frame_changed.is_connected(_sync_attack_window):
		player.sprite.frame_changed.disconnect(_sync_attack_window)
	player.attack_hitbox.set_active(false)

func physics_update(delta: float) -> StringName:
	player.apply_gravity(delta)
	# Committed: the swing does not steer, but momentum is bled off so the
	# player does not slide through the whole animation.
	player.decelerate(delta)
	_sync_attack_window()
	if player.animation_finished():
		return GROUNDED if player.is_on_floor() else AIRBORNE
	return &""


func _sync_attack_window() -> void:
	var active := (
		player.sprite.animation == &"player_light_attack_1"
		and player.sprite.frame >= ACTIVE_FIRST_FRAME
		and player.sprite.frame <= ACTIVE_LAST_FRAME
	)
	player.attack_hitbox.set_active(active)
