class_name IntegrityService
extends RefCounted
## Structural integrity I — research report section 5.4.
##
## I = clamp(0.34h + 0.24s + 0.16a + 0.14r + 0.12f, 0, 1)
##
## The service reads *only* structural values. Current HP and current stamina
## are deliberately absent: the original design mixed them in, which produced a
## "take damage → sacrifices get better → heal → sacrifice again" arbitrage
## loop. Integrity answers "how much of my original body is gone", never "how
## hurt am I right now".
##
## Each component is capped at 1, so ordinary buffs cannot push integrity above
## the intact-body ceiling and cannot launder away a sacrifice.

## `structural` comes from RunState.structural_snapshot().
static func compute(structural: Dictionary, balance: BalanceConfig) -> float:
	var components := components_of(structural, balance)
	var total: float = (
		balance.integrity_weight_hp * components["h"]
		+ balance.integrity_weight_stamina * components["s"]
		+ balance.integrity_weight_armour * components["a"]
		+ balance.integrity_weight_recovery * components["r"]
		+ balance.integrity_weight_freedom * components["f"]
	)
	return clampf(total, 0.0, 1.0)

## Individual components, exposed so the sacrifice cost score and the debug
## panel can show which part of the body was spent.
static func components_of(structural: Dictionary, balance: BalanceConfig) -> Dictionary:
	var armour_now: float = 1.0 + float(structural["armour"]) / 100.0
	var armour_base: float = 1.0 + balance.base_armour / 100.0
	return {
		"h": _ratio(float(structural["max_hp"]), balance.base_max_hp),
		"s": _ratio(float(structural["max_stamina"]), balance.base_max_stamina),
		"a": _ratio(armour_now, armour_base),
		"r": _ratio(float(structural["stamina_recovery"]), balance.base_stamina_recovery),
		"f": maxf(
			0.0,
			1.0
			- balance.integrity_major_lock_penalty * float(structural["major_locks"])
			- balance.integrity_action_tax_penalty * float(structural["action_taxes"])
		),
	}

static func _ratio(current: float, baseline: float) -> float:
	if baseline <= 0.0:
		return 1.0
	return minf(1.0, current / baseline)
