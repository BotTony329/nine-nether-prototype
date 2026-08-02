class_name MetaState
extends RefCounted
## Everything that survives a run. Five values and nothing else — the Ghost
## Market is a loop closer in M2, not an economy.
##
## Mirrors RunState's shape deliberately: private fields, reads through getters,
## writes through named commands. UI reads and asks; it does not assign.
##
## Serialisation lives here rather than in MetaSave because the field list and
## its JSON shape are one piece of knowledge. MetaSave owns the file.

var _soul_ash: int = 0
var _runs: int = 0
var _deaths: int = 0
var _victories: int = 0
var _tempered_blade_owned: bool = false


# --- reads ------------------------------------------------------------------
func soul_ash() -> int: return _soul_ash
func runs() -> int: return _runs
func deaths() -> int: return _deaths
func victories() -> int: return _victories
func tempered_blade_owned() -> bool: return _tempered_blade_owned

## Flat attack this profile grants to a new run. The only channel through which
## meta progression touches a run's numbers.
func attack_bonus(config: MetaConfig) -> float:
	return config.tempered_blade_attack_bonus if _tempered_blade_owned else 0.0

func can_buy_tempered_blade(config: MetaConfig) -> bool:
	return not _tempered_blade_owned and _soul_ash >= config.tempered_blade_cost


# --- commands ---------------------------------------------------------------
## Applies a finished run: prices it, banks the ash, and moves the counters.
## Mutates `result.soul_ash_earned` so the result screen and the market both
## show the figure that was actually banked.
func record_run(result: RunResult, config: MetaConfig) -> void:
	result.soul_ash_earned = config.soul_ash_for(result)
	_soul_ash += result.soul_ash_earned
	_runs += 1
	if result.is_victory():
		_victories += 1
	else:
		_deaths += 1

## Returns false and changes nothing when it is unaffordable or already owned.
func buy_tempered_blade(config: MetaConfig) -> bool:
	if not can_buy_tempered_blade(config):
		return false
	_soul_ash -= config.tempered_blade_cost
	_tempered_blade_owned = true
	return true


# --- serialisation ----------------------------------------------------------
func to_dictionary() -> Dictionary:
	return {
		"soul_ash": _soul_ash,
		"runs": _runs,
		"deaths": _deaths,
		"victories": _victories,
		"tempered_blade_owned": _tempered_blade_owned,
	}

## Missing or malformed keys fall back to a fresh profile's value rather than
## throwing: a save written by an older build should cost the player nothing.
static func from_dictionary(data: Dictionary) -> MetaState:
	var meta := MetaState.new()
	meta._soul_ash = maxi(0, int(data.get("soul_ash", 0)))
	meta._runs = maxi(0, int(data.get("runs", 0)))
	meta._deaths = maxi(0, int(data.get("deaths", 0)))
	meta._victories = maxi(0, int(data.get("victories", 0)))
	meta._tempered_blade_owned = bool(data.get("tempered_blade_owned", false))
	return meta
