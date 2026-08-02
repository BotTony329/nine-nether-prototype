class_name SoftCaps
extends RefCounted
## Diminishing-returns curves from research report section 5.7.
##
## Pure float maths, no state. Kept separate from CombatResolver because
## DerivedStats needs the identical curves — two copies of a cap is two places
## for the numbers to drift apart.

## Values at or below `knee` pass through; beyond it only `slope` of the excess
## counts. Continuous at the knee, so no jump when a stat crosses it.
static func compress(value: float, knee: float, slope: float) -> float:
	if value <= knee:
		return value
	return knee + (value - knee) * slope

static func crit_rate(value: float, balance: BalanceConfig) -> float:
	return clampf(value, 0.0, balance.crit_rate_hard_cap)

static func crit_damage(value: float, balance: BalanceConfig) -> float:
	return compress(value, balance.crit_damage_soft_cap, balance.crit_damage_soft_slope)

static func attack_speed(value: float, balance: BalanceConfig) -> float:
	return compress(value, balance.attack_speed_soft_cap, balance.attack_speed_soft_slope)

static func more_product(value: float, balance: BalanceConfig) -> float:
	return compress(value, balance.more_product_soft_cap, balance.more_product_soft_slope)
