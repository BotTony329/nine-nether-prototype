extends TestCase
## The sacrifice transaction: preview honesty, rollback, and the shipped card.

var balance: BalanceConfig
var service: SacrificeService
var state: RunState

func before_each() -> void:
	balance = make_balance()
	service = SacrificeService.new(balance)
	state = RunState.create(balance, 7)

func _shipped() -> SacrificeDefinition:
	return GameData.definition(RunCoordinator.M1_SACRIFICE_ID)

## A definition built in memory, so a test can describe the exact shape it needs
## without adding a card to the shipped library.
func _definition(overrides: Dictionary = {}) -> SacrificeDefinition:
	var definition := SacrificeDefinition.new()
	definition.id = &"test_card"
	definition.display_name = "Test Card"
	definition.strength = 2
	definition.roles = [SacrificeDefinition.ROLE_CONTINUATION] as Array[StringName]
	definition.tags = [&"attack"] as Array[StringName]
	definition.cost_max_hp_multiplier = 0.85
	definition.reward_additive = 0.18
	definition.reward_generic_more = true
	for key in overrides:
		definition.set(key, overrides[key])
	return definition


func test_preview_does_not_touch_the_real_state() -> void:
	var digest := state.snapshot_hash()
	var preview := service.preview(state, _shipped())
	assert_true(preview.ok, "the shipped card previews cleanly")
	assert_equal(state.snapshot_hash(), digest, "preview ran on a clone")


func test_apply_matches_the_preview_it_showed() -> void:
	var definition := _shipped()
	var preview := service.preview(state, definition)
	var applied := service.apply(state, definition)
	assert_true(applied.ok, "apply succeeded")
	assert_true(preview.matches(applied), "preview and apply describe the same transaction")
	assert_almost(preview.gain, applied.gain, "gain is identical", 1e-9)
	for key in preview.deltas:
		assert_almost(
			float(applied.deltas[key]), float(preview.deltas[key]),
			"delta %s matches the preview" % key, 1e-9
		)


func test_shipped_card_trades_structure_for_damage() -> void:
	var before := state.snapshot()
	var result := service.apply(state, _shipped())
	assert_true(result.ok, "apply succeeded")
	assert_less(state.max_hp(), float(before["max_hp"]), "max lifespan falls")
	assert_less(state.integrity(), float(before["integrity"]), "structural integrity falls")
	assert_less(state.effective_hp(), float(before["effective_hp"]), "effective HP falls")
	assert_greater(state.additive_sum(), float(before["additive_sum"]), "attack additive rises")
	assert_greater(state.more_product(), float(before["more_product"]), "damage multiplier rises")
	assert_greater(state.dps_estimate(), float(before["dps_estimate"]), "estimated DPS rises")
	assert_greater(state.imbalance(), float(before["imbalance"]), "imbalance rises")


func test_shipped_card_values_come_from_the_data_file() -> void:
	var definition := _shipped()
	assert_not_null(definition, "the shipped card loads from res://data/sacrifices")
	service.apply(state, definition)
	assert_almost(
		state.max_hp(), balance.base_max_hp * definition.cost_max_hp_multiplier,
		"max HP uses the multiplier from the .tres, not a literal in script", 1e-6
	)
	assert_almost(
		state.additive_sum(), definition.reward_additive,
		"additive reward comes from the .tres", 1e-6
	)
	assert_almost(
		state.imbalance(), definition.imbalance_flat,
		"authored imbalance wins over the derived formula", 1e-6
	)


func test_reward_is_priced_after_the_cost() -> void:
	# G = g_S * (0.55 + 1.45 * D) * Q, with D taken from post-cost integrity.
	var definition := _shipped()
	var result := service.apply(state, definition)
	var integrity_after_cost := IntegrityService.compute(
		{
			"max_hp": balance.base_max_hp * definition.cost_max_hp_multiplier,
			"max_stamina": balance.base_max_stamina,
			"armour": balance.base_armour,
			"stamina_recovery": balance.base_stamina_recovery,
			"major_locks": 0,
			"action_taxes": 0,
		},
		balance
	)
	var deficiency := pow(1.0 - integrity_after_cost, balance.deficiency_exponent)
	var expected := balance.strength_gain[definition.strength] * (
		balance.reward_base + balance.reward_slope * deficiency
	)
	assert_almost(result.gain, expected, "gain uses post-cost integrity", 1e-6)


func test_a_more_broken_body_buys_a_bigger_reward() -> void:
	var healthy := RunState.create(balance, 1)
	var broken := RunState.create(balance, 1)
	broken.scale_max_stamina(0.4)
	broken.set_armour(0.0)

	var healthy_gain := service.preview(healthy, _definition()).gain
	var broken_gain := service.preview(broken, _definition()).gain
	assert_greater(broken_gain, healthy_gain, "the sharper trade needs a more damaged body")


func test_failed_transaction_rolls_the_state_back_whole() -> void:
	# Already damaged, so an integrity component is below its cap and can move.
	state.scale_max_hp(0.5)
	# A cost multiplier above 1 *raises* max HP, which no sacrifice may do.
	var malformed := _definition({"cost_max_hp_multiplier": 1.5})
	var digest := state.snapshot_hash()
	var result := service.apply(state, malformed)
	assert_false(result.ok, "a sacrifice that restores integrity is rejected")
	assert_equal(state.snapshot_hash(), digest, "no half-applied state survives the failure")
	assert_true(state.sacrifice_history().is_empty(), "a rejected card is not recorded")


func test_the_same_card_cannot_be_taken_twice() -> void:
	assert_true(service.apply(state, _shipped()).ok, "first take succeeds")
	var second := service.apply(state, _shipped())
	assert_false(second.ok, "second take is rejected")
	assert_equal(second.failure_reason, "already taken", "with a readable reason")


func test_exclusive_groups_and_prerequisites_gate_offers() -> void:
	var gated := _definition({"prerequisite_min_sacrifices": 2})
	assert_false(bool(service.can_offer(state, gated)["ok"]), "prerequisite blocks the offer")

	var locked := _definition({
		"cost_structural_locks": [&"a", &"b", &"c"] as Array[StringName],
	})
	assert_false(bool(service.can_offer(state, locked)["ok"]), "lock budget blocks the offer")


func test_shipped_library_is_valid_data() -> void:
	var definitions := GameData.all_definitions()
	assert_greater(float(definitions.size()), 0.0, "the library is not empty")
	var seen: Array[StringName] = []
	for definition in definitions:
		for problem in definition.validate():
			fail(problem)
		assert_false(seen.has(definition.id), "duplicate sacrifice id %s" % definition.id)
		seen.append(definition.id)
