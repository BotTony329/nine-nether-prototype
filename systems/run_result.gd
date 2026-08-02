class_name RunResult
extends RefCounted
## What one run amounted to. Produced once by RunCoordinator when the run ends,
## consumed by the meta layer and by the result screen.
##
## Deliberately a plain value: no behaviour, no references to live nodes. That
## is what lets it survive the run scene being freed, and lets a test build one
## by hand.
##
## `soul_ash_earned` is the one field the run does not know. The run reports
## what happened; MetaConfig prices it. See docs/GHOST_MARKET_LOOP.md.

var outcome: StringName = RunState.STATUS_DEFEAT
var duration_seconds: float = 0.0
var kills: int = 0
var sacrifices: int = 0
var integrity: float = 1.0
var imbalance: float = 0.0
var soul_ash_earned: int = 0

func is_victory() -> bool:
	return outcome == RunState.STATUS_VICTORY

func to_dictionary() -> Dictionary:
	return {
		"outcome": outcome,
		"duration_seconds": duration_seconds,
		"kills": kills,
		"sacrifices": sacrifices,
		"integrity": integrity,
		"imbalance": imbalance,
		"soul_ash_earned": soul_ash_earned,
	}

## Compact one-line summary for the Ghost Market's "latest run" panel.
func summary() -> String:
	return (
		"%s · %s · %s · %s · integrity %.3f · imbalance %.0f · +%d soul ash"
		% [
			String(outcome).to_upper(),
			format_duration(duration_seconds),
			_plural(kills, "kill"),
			_plural(sacrifices, "sacrifice"),
			integrity,
			imbalance,
			soul_ash_earned,
		]
	)

static func _plural(count: int, noun: String) -> String:
	return "%d %s%s" % [count, noun, "" if count == 1 else "s"]

static func format_duration(seconds: float) -> String:
	var total := int(maxf(0.0, seconds))
	return "%d:%02d" % [total / 60, total % 60]
