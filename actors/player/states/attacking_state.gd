class_name AttackingState
extends PlayerState
## Light attack: wind-up, active window, recovery. Timings and the stamina cost
## (0 by design — see research report 6.1) come from BalanceConfig.
##
## The hitbox is only live during the active window, so the swing's reach in
## time is data, not an animation coincidence.

enum Phase { WINDUP, ACTIVE, RECOVERY }

var _phase: int = Phase.WINDUP
var _elapsed: float = 0.0

func id() -> StringName:
	return ATTACKING

func enter() -> void:
	_phase = Phase.WINDUP
	_elapsed = 0.0
	player.play(&"attack")
	player.sprite.frame = 0
	player.spend_stamina(player.balance().light_attack_stamina_cost)

func exit() -> void:
	player.attack_hitbox.set_active(false)

func physics_update(delta: float) -> StringName:
	player.apply_gravity(delta)
	# Committed: the swing does not steer, but momentum is bled off so the
	# player does not slide through the whole animation.
	player.decelerate(delta)
	_elapsed += delta

	var balance := player.balance()
	match _phase:
		Phase.WINDUP:
			if _elapsed >= balance.light_attack_windup:
				_phase = Phase.ACTIVE
				_elapsed = 0.0
				player.attack_hitbox.set_active(true)
		Phase.ACTIVE:
			if _elapsed >= balance.light_attack_active:
				_phase = Phase.RECOVERY
				_elapsed = 0.0
				player.attack_hitbox.set_active(false)
		Phase.RECOVERY:
			if _elapsed >= balance.light_attack_recovery:
				return GROUNDED if player.is_on_floor() else AIRBORNE
	return &""
