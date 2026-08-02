extends TestCase
## CombatResolver — the bucket pipeline, crit rules, armour and lethality.

var balance: BalanceConfig
var resolver: CombatResolver

func before_each() -> void:
	balance = make_balance()
	resolver = CombatResolver.new(balance)

func _context(base: float, armour: float = 0.0, target_hp: float = 1000.0) -> DamageContext:
	var context := DamageContext.new()
	context.source_id = &"test_source"
	context.target_id = &"test_target"
	context.base_damage = base
	context.target_armour = armour
	context.target_current_hp = target_hp
	context.force_crit = 0
	return context


func test_normal_damage_applies_every_bucket_in_order() -> void:
	var context := _context(10.0)
	context.skill_multiplier = 2.0
	context.additive_modifiers = [0.25, 0.25] as Array[float]
	context.more_modifiers = [0.5] as Array[float]
	context.conditional_modifiers = [0.2] as Array[float]
	var result := resolver.resolve(context)
	# 10 * 2 * (1 + 0.5) * 1.5 * 1.2
	assert_almost(result.raw_damage, 54.0, "raw damage follows base->add->more->cond", 1e-4)
	assert_almost(result.final_damage, 54.0, "no armour means no mitigation", 1e-4)


func test_armour_mitigates_by_equivalent_life_model() -> void:
	var result := resolver.resolve(_context(100.0, 100.0))
	# 100 * 100 / (100 + 100)
	assert_almost(result.final_damage, 50.0, "100 armour halves incoming damage", 1e-4)
	assert_almost(result.mitigation, 50.0, "mitigation is raw minus final", 1e-4)


func test_armour_penetration_reduces_effective_armour() -> void:
	var context := _context(100.0, 100.0)
	context.armour_penetration = 60.0
	var result := resolver.resolve(context)
	assert_almost(result.breakdown["effective_armour"], 40.0, "penetration subtracts", 1e-6)
	assert_almost(result.final_damage, 100.0 * 100.0 / 140.0, "mitigation uses effective armour", 1e-4)


func test_forced_critical_multiplies_by_crit_damage() -> void:
	var context := _context(10.0)
	context.crit_damage = 2.5
	context.force_crit = 1
	var result := resolver.resolve(context)
	assert_true(result.is_critical, "force_crit = 1 always crits")
	assert_almost(result.final_damage, 25.0, "crit multiplies by crit damage", 1e-4)


func test_forbidden_critical_never_crits_even_at_full_rate() -> void:
	var context := _context(10.0)
	context.crit_rate = 1.0
	context.crit_damage = 5.0
	context.force_crit = 0
	assert_false(resolver.resolve(context).is_critical, "force_crit = 0 suppresses the roll")


func test_pinned_roll_makes_crit_deterministic() -> void:
	var context := _context(10.0)
	context.crit_rate = 0.30
	context.crit_damage = 2.0
	context.force_crit = -1

	context.crit_roll = 0.29
	assert_true(resolver.resolve(context).is_critical, "roll below rate crits")

	context.crit_roll = 0.31
	assert_false(resolver.resolve(context).is_critical, "roll above rate does not crit")


func test_crit_rate_is_hard_capped_and_crit_damage_is_soft_capped() -> void:
	var context := _context(10.0)
	context.crit_rate = 0.99
	context.crit_damage = 6.5
	context.crit_roll = 0.85
	var result := resolver.resolve(context)
	assert_false(result.is_critical, "0.85 is above the 0.80 hard cap so no crit")
	assert_almost(
		result.breakdown["crit_damage_effective"],
		4.5 + (6.5 - 4.5) * 0.35,
		"crit damage compresses past the soft cap",
		1e-6
	)


func test_more_product_is_soft_capped() -> void:
	var context := _context(1.0)
	context.more_modifiers = [19.0] as Array[float]  # raw product 20
	var result := resolver.resolve(context)
	assert_almost(
		result.breakdown["more_product"],
		12.0 + (20.0 - 12.0) * 0.30,
		"more product compresses past 12",
		1e-6
	)


func test_lethal_is_flagged_only_when_the_hit_finishes_the_target() -> void:
	assert_true(resolver.resolve(_context(30.0, 0.0, 30.0)).is_lethal, "exactly lethal counts")
	assert_true(resolver.resolve(_context(31.0, 0.0, 30.0)).is_lethal, "overkill counts")
	assert_false(resolver.resolve(_context(29.9, 0.0, 30.0)).is_lethal, "a survivable hit does not")


func test_breakdown_reproduces_the_final_number() -> void:
	var context := _context(12.0, 25.0)
	context.skill_multiplier = 1.4
	context.additive_modifiers = [0.3] as Array[float]
	context.more_modifiers = [0.25] as Array[float]
	context.conditional_modifiers = [0.1] as Array[float]
	context.crit_damage = 2.0
	context.force_crit = 1
	var result := resolver.resolve(context)
	var breakdown := result.breakdown
	var recomputed: float = (
		float(breakdown["base_damage"])
		* float(breakdown["skill_multiplier"])
		* (1.0 + float(breakdown["additive_sum"]))
		* float(breakdown["more_product"])
		* float(breakdown["conditional_product"])
		* float(breakdown["crit_multiplier"])
		* float(breakdown["mitigation_factor"])
		* float(breakdown["vulnerability"])
	)
	assert_almost(recomputed, result.final_damage, "breakdown multiplies back to final damage", 1e-6)
