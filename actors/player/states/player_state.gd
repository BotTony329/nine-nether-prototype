class_name PlayerState
extends RefCounted
## Base class for the player's action states.
##
## Contract (frozen — see docs/INTERFACES.md): a state changes the player by
## calling the helpers on Player, and requests a transition by returning the
## next state id from `physics_update`. Returning `&""` means "stay". No state
## writes another state's fields, and nothing outside the machine calls
## `enter`/`exit`.
##
## To add a state (Dodge, Exhausted, SameDeath are the planned ones), subclass
## this, register the id in PlayerStateMachine, and give an existing state a
## reason to return the new id. Nothing else needs to change.

const GROUNDED := &"grounded"
const AIRBORNE := &"airborne"
const ATTACKING := &"attacking"
const HURT := &"hurt"
const DEAD := &"dead"

var player: Player

func _init(owner_player: Player) -> void:
	player = owner_player

func id() -> StringName:
	return &"unknown"

func enter() -> void:
	pass

func exit() -> void:
	pass

## Returns the next state id, or &"" to stay in this state.
func physics_update(_delta: float) -> StringName:
	return &""

## Shared transition test: any state that allows attacking uses this, so the
## rule lives in one place.
func wants_attack() -> bool:
	return player.input_enabled and Input.is_action_just_pressed(&"light_attack")
