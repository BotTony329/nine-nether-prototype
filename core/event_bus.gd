extends Node
## Global, decoupled notification hub. Autoloaded as `EventBus`.
##
## Contract (frozen — see docs/INTERFACES.md):
##   * Events are for UI, telemetry and decoupled reactions ONLY.
##   * Deterministic core resolution (damage, integrity, sacrifice) uses explicit
##     service calls, never the bus. Do not move a calculation onto a signal.
##   * Listeners must not mutate RunState in a handler; they observe.
##
## Every payload carries the fields produced by `context()` so telemetry can
## correlate events without each emitter inventing its own shape.

signal run_started(payload: Dictionary)
signal run_restarted(payload: Dictionary)
signal hit_dealt(payload: Dictionary)
signal hit_taken(payload: Dictionary)
signal enemy_died(payload: Dictionary)
signal player_died(payload: Dictionary)
signal sacrifice_previewed(payload: Dictionary)
signal sacrifice_applied(payload: Dictionary)
signal boss_started(payload: Dictionary)
signal boss_died(payload: Dictionary)
signal run_completed(payload: Dictionary)

var _run_id: int = 0
var _stage_id: StringName = &"none"

## Called by RunCoordinator when a run begins so later payloads are attributable.
func bind_run(run_id: int) -> void:
	_run_id = run_id

func set_stage(stage_id: StringName) -> void:
	_stage_id = stage_id

## Builds the common envelope. `extra` is merged in and wins on key collision.
func context(extra: Dictionary = {}) -> Dictionary:
	var payload := {
		"timestamp": Time.get_ticks_msec(),
		"run_id": _run_id,
		"stage_id": _stage_id,
	}
	payload.merge(extra, true)
	return payload
