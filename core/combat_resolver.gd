class_name CombatResolver
extends RefCounted
## The one and only damage pipeline — research report section 5.3.
##
##   raw = ATK * SkillMult * (1 + AddSum) * MoreProd * CondProd
##   crit applies after the buckets, armour after crit
##   taken = raw * 100 / (100 + ARM_eff) * vulnerability
##
## Contract (frozen — see docs/INTERFACES.md): Player, Enemy, Boss, HUD and the
## sacrifice preview all call `resolve`. Re-deriving damage anywhere else is a
## defect, not an optimisation — the preview and the hit must agree exactly.

var _balance: BalanceConfig
## Supplies the crit roll when a context does not pin one. Injected so tests can
## make crits deterministic without seeding the global RNG.
var _roll_provider: Callable

func _init(balance: BalanceConfig, roll_provider: Callable = Callable()) -> void:
	_balance = balance
	_roll_provider = roll_provider if roll_provider.is_valid() else _default_roll

func resolve(ctx: DamageContext) -> DamageResult:
	var result := DamageResult.new()
	result.source_id = ctx.source_id
	result.target_id = ctx.target_id

	var additive_sum := ctx.additive_sum()
	var more_product := SoftCaps.more_product(ctx.more_product(), _balance)
	var conditional_product := ctx.conditional_product()

	var pre_crit: float = (
		ctx.base_damage
		* ctx.skill_multiplier
		* (1.0 + additive_sum)
		* more_product
		* conditional_product
	)

	var crit_rate := SoftCaps.crit_rate(ctx.crit_rate, _balance)
	var crit_damage := SoftCaps.crit_damage(ctx.crit_damage, _balance)
	var is_critical := _decide_crit(ctx, crit_rate)
	var crit_multiplier := crit_damage if is_critical else 1.0
	var raw := pre_crit * crit_multiplier

	var effective_armour := maxf(0.0, ctx.target_armour - ctx.armour_penetration)
	var mitigation_factor := DerivedStats.mitigation_factor(effective_armour)
	var final_damage := maxf(0.0, raw * mitigation_factor * ctx.vulnerability)

	result.raw_damage = raw
	result.final_damage = final_damage
	result.is_critical = is_critical
	result.mitigation = raw - final_damage
	result.is_lethal = final_damage >= ctx.target_current_hp and ctx.target_current_hp > 0.0
	result.breakdown = {
		"base_damage": ctx.base_damage,
		"skill_multiplier": ctx.skill_multiplier,
		"additive_sum": additive_sum,
		"more_product": more_product,
		"conditional_product": conditional_product,
		"pre_crit": pre_crit,
		"crit_rate_effective": crit_rate,
		"crit_damage_effective": crit_damage,
		"crit_multiplier": crit_multiplier,
		"effective_armour": effective_armour,
		"mitigation_factor": mitigation_factor,
		"vulnerability": ctx.vulnerability,
		"final_damage": final_damage,
	}
	return result

## Builds the player's outgoing context from RunState, so the player's numbers
## come from one place instead of being reassembled at each call site.
func player_attack_context(
	state: RunState,
	target_id: StringName,
	target_armour: float,
	target_current_hp: float,
	skill_multiplier: float
) -> DamageContext:
	var ctx := DamageContext.new()
	ctx.source_id = &"player"
	ctx.target_id = target_id
	ctx.base_damage = state.attack()
	ctx.skill_multiplier = skill_multiplier
	ctx.additive_modifiers = [state.additive_sum()] as Array[float]
	ctx.more_modifiers = [state.more_product() - 1.0] as Array[float]
	ctx.crit_allowed = true
	ctx.crit_rate = state.crit_rate()
	ctx.crit_damage = state.crit_damage()
	ctx.target_armour = target_armour
	ctx.target_current_hp = target_current_hp
	ctx.tags = [&"melee"] as Array[StringName]
	# "Guttering candle" band: momentary, so it lives in the conditional bucket
	# rather than anywhere near structural integrity (section 6.4).
	if state.is_guttering():
		ctx.conditional_modifiers.append(_balance.guttering_more_multiplier - 1.0)
	return ctx

func _decide_crit(ctx: DamageContext, effective_crit_rate: float) -> bool:
	if not ctx.crit_allowed:
		return false
	if ctx.force_crit == 1:
		return true
	if ctx.force_crit == 0:
		return false
	var roll: float = ctx.crit_roll if ctx.crit_roll >= 0.0 else float(_roll_provider.call())
	return roll < effective_crit_rate

func _default_roll() -> float:
	return RNGService.randf(RNGService.STREAM_COMBAT)
