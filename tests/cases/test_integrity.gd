extends TestCase
## IntegrityService and the structural/momentary split.
##
## The first test is the one that matters most: it is the bug the research
## report was written to fix.

var balance: BalanceConfig
var state: RunState

func before_each() -> void:
	balance = make_balance()
	state = RunState.create(balance, 1)


func test_intact_run_starts_at_full_integrity() -> void:
	assert_almost(state.integrity(), 1.0, "a fresh body is whole")


func test_current_hp_changes_do_not_move_integrity() -> void:
	var before := state.integrity()
	state.apply_damage(70.0)
	assert_almost(state.integrity(), before, "taking damage is momentary, not structural")
	assert_almost(state.hp_ratio(), 0.30, "the damage did land", 1e-6)
	state.heal(70.0)
	assert_almost(state.integrity(), before, "healing does not restore structure either")


func test_current_stamina_changes_do_not_move_integrity() -> void:
	var before := state.integrity()
	state.spend_stamina(80.0)
	assert_almost(state.integrity(), before, "spending stamina is momentary")


func test_max_hp_loss_lowers_integrity_by_its_weight() -> void:
	state.scale_max_hp(0.85)
	# h drops 0.15, weighted 0.34
	assert_almost(state.integrity(), 1.0 - 0.34 * 0.15, "integrity falls by weight * component drop", 1e-6)


func test_every_structural_stat_lowers_integrity() -> void:
	var checks := {
		"max stamina": func() -> void: state.scale_max_stamina(0.5),
		"armour": func() -> void: state.set_armour(0.0),
		"recovery": func() -> void: state.set_stamina_recovery(6.0),
		"lock": func() -> void: state.add_structural_lock(&"no_healing"),
		"tax": func() -> void: state.add_action_tax(&"dodge_costs_more"),
	}
	for label in checks:
		var fresh := RunState.create(balance, 1)
		state = fresh
		(checks[label] as Callable).call()
		assert_less(state.integrity(), 1.0, "%s should reduce integrity" % label)


func test_buffs_cannot_push_integrity_above_the_intact_ceiling() -> void:
	state.scale_max_hp(3.0)
	state.set_armour(500.0)
	state.set_stamina_recovery(90.0)
	assert_almost(state.integrity(), 1.0, "components are capped at 1 — no laundering a sacrifice")


func test_a_buff_cannot_offset_a_structural_loss() -> void:
	state.scale_max_hp(0.5)
	var wounded := state.integrity()
	state.set_armour(400.0)
	assert_almost(state.integrity(), wounded, "over-capped armour cannot repay lost lifespan")


func test_structural_floors_are_respected() -> void:
	for _i in range(40):
		state.scale_max_hp(0.5)
		state.scale_max_stamina(0.5)
	assert_almost(state.max_hp(), balance.min_max_hp, "max HP stops at the floor")
	assert_almost(state.max_stamina(), balance.min_max_stamina, "max stamina stops at the floor")


func test_snapshot_restore_round_trips_exactly() -> void:
	state.scale_max_hp(0.7)
	state.add_additive(0.25)
	state.multiply_more(1.4)
	state.add_imbalance(31.0)
	state.record_sacrifice(&"probe", [&"attack"] as Array[StringName])
	state.apply_damage(12.0)
	var snapshot := state.snapshot()
	var digest := state.snapshot_hash()

	state.scale_max_hp(0.1)
	state.add_imbalance(50.0)
	assert_true(state.snapshot_hash() != digest, "the disturbance actually changed the state")

	state.restore(snapshot)
	assert_equal(state.snapshot_hash(), digest, "restore reproduces the exact snapshot")
	assert_almost(state.integrity(), float(snapshot["integrity"]), "restore recomputes derived values")


func test_clone_is_detached_from_the_original() -> void:
	var copy := state.clone()
	copy.scale_max_hp(0.1)
	copy.add_imbalance(99.0)
	assert_almost(state.max_hp(), balance.base_max_hp, "the original max HP is untouched")
	assert_almost(state.imbalance(), 0.0, "the original imbalance is untouched")


func test_effective_hp_follows_the_equivalent_life_model() -> void:
	assert_almost(state.effective_hp(), 100.0 * 1.1, "EHP = max HP * (1 + armour/100)", 1e-6)
