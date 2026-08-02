class_name PlayerStateMachine
extends RefCounted
## Owns the player's action states and the transitions between them.
##
## Every transition goes through `_change_to`, so there is exactly one place
## that runs exit/enter and one place to look when a state gets stuck. States
## never call each other.
##
## Extension points (documented for Codex, deliberately not implemented in M1):
##   * Dodge — three phases with i-frames; enter from GROUNDED/AIRBORNE on the
##     dodge action, and gate it on StaminaService once that exists.
##   * Exhausted — enter from anywhere when stamina hits zero; blocks dodge,
##     skill and heavy attack while leaving light attack available.
##   * SameDeath — must be checked *before* DEAD in `on_death`, since it is a
##     lethal-damage interception, not a state the player can walk into.

var _states: Dictionary = {}
var _current: PlayerState

func _init(player: Player) -> void:
	_register(GroundedState.new(player))
	_register(AirborneState.new(player))
	_register(AttackingState.new(player))
	_register(HurtState.new(player))
	_register(DeadState.new(player))
	_current = _states[PlayerState.GROUNDED]
	_current.enter()

func current_id() -> StringName:
	return _current.id()

func physics_update(delta: float) -> void:
	var next: StringName = _current.physics_update(delta)
	if not String(next).is_empty():
		_change_to(next)

## Interruption from outside: taking a survivable hit.
func on_hurt(_source_id: StringName) -> void:
	if _current.id() == PlayerState.DEAD:
		return
	_change_to(PlayerState.HURT)

## Interruption from outside: lethal damage. When SameDeath lands, its
## eligibility check belongs at the top of this method.
func on_death() -> void:
	if _current.id() == PlayerState.DEAD:
		return
	_change_to(PlayerState.DEAD)

func _register(state: PlayerState) -> void:
	_states[state.id()] = state

func _change_to(next_id: StringName) -> void:
	if not _states.has(next_id):
		push_error("PlayerStateMachine: unknown state %s" % next_id)
		return
	if _current.id() == next_id:
		return
	_current.exit()
	_current = _states[next_id]
	_current.enter()
