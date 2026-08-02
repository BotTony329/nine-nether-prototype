class_name DerivedStats
extends RefCounted
## Read-only projections of RunState used by the HUD, the sacrifice preview and
## telemetry. Takes primitives rather than a RunState so that RunState can
## depend on it without a class-level cycle.

## Research report section 5.2. Armour is an equivalent-life model, so each
## point buys roughly linear EHP instead of exploding at high values.
static func effective_hp(max_hp: float, armour: float) -> float:
	return max_hp * (1.0 + armour / 100.0)

## Fraction of raw damage that survives armour mitigation.
static func mitigation_factor(armour: float) -> float:
	return 100.0 / (100.0 + maxf(0.0, armour))

## Section 5.3, without uptime: a comparable number for "how sharp is the
## blade", not a simulation. `offence` comes from RunState.offence_snapshot().
static func dps_estimate(offence: Dictionary, balance: BalanceConfig) -> float:
	var crit_rate: float = SoftCaps.crit_rate(float(offence["crit_rate"]), balance)
	var crit_damage: float = SoftCaps.crit_damage(float(offence["crit_damage"]), balance)
	var attack_speed: float = SoftCaps.attack_speed(float(offence["attack_speed"]), balance)
	var more_product: float = SoftCaps.more_product(float(offence["more_product"]), balance)
	var crit_expectation: float = 1.0 + crit_rate * (crit_damage - 1.0)
	return (
		float(offence["attack"])
		* attack_speed
		* (1.0 + float(offence["additive_sum"]))
		* more_product
		* crit_expectation
	)
