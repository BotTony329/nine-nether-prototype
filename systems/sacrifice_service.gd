class_name SacrificeService
extends RefCounted
## The sacrifice transaction — Prototype Development Pack A9.
##
## Ordering is fixed and non-negotiable:
##   validate → snapshot → apply cost → recalculate integrity → apply reward
##   → recalculate derived → apply imbalance → publish → return
##
## The reward is computed from integrity *after* the cost, which is what makes
## "the more broken you are, the sharper the blade" true. Applying reward first
## would quietly change the whole economy.
##
## Contract (frozen — see docs/INTERFACES.md): `preview` and `apply` run the
## identical `_run_transaction`. `preview` runs it on a clone. There is no
## second code path, so a preview cannot lie.

var _balance: BalanceConfig

func _init(balance: BalanceConfig) -> void:
	_balance = balance


## Returns {ok: bool, reason: String}. Pure — inspects, never mutates.
func can_offer(state: RunState, definition: SacrificeDefinition) -> Dictionary:
	if definition == null:
		return {"ok": false, "reason": "no definition"}
	var owned: Array[StringName] = state.sacrifice_history()
	if owned.has(definition.id):
		return {"ok": false, "reason": "already taken"}
	if owned.size() < definition.prerequisite_min_sacrifices:
		return {
			"ok": false,
			"reason": "requires %d prior sacrifices" % definition.prerequisite_min_sacrifices,
		}
	for banned in definition.banned_with:
		if owned.has(banned):
			return {"ok": false, "reason": "excluded by %s" % banned}
	if not String(definition.exclusive_group).is_empty():
		if _group_is_taken(state, definition.exclusive_group):
			return {"ok": false, "reason": "exclusive group %s already used" % definition.exclusive_group}
	var locks_after: int = state.structural_locks().size() + definition.cost_structural_locks.size()
	if locks_after > _balance.max_major_locks:
		return {"ok": false, "reason": "would exceed %d major locks" % _balance.max_major_locks}
	var taxes_after: int = state.action_taxes().size() + definition.cost_action_taxes.size()
	if taxes_after > _balance.max_action_taxes:
		return {"ok": false, "reason": "would exceed %d action taxes" % _balance.max_action_taxes}
	return {"ok": true, "reason": ""}


## Simulates the transaction on a detached copy. `state` is untouched.
func preview(state: RunState, definition: SacrificeDefinition) -> SacrificeResult:
	var result := _run_transaction(state.clone(), definition)
	EventBus.sacrifice_previewed.emit(EventBus.context(result.to_dictionary()))
	return result


## Commits the transaction to `state`. On any failure the state is rolled back
## whole — a half-applied sacrifice is never a valid outcome.
func apply(state: RunState, definition: SacrificeDefinition) -> SacrificeResult:
	var result := _run_transaction(state, definition)
	if result.ok:
		EventBus.sacrifice_applied.emit(EventBus.context(result.to_dictionary()))
	return result


func _run_transaction(state: RunState, definition: SacrificeDefinition) -> SacrificeResult:
	# 1. validate
	var validation: Dictionary = can_offer(state, definition)
	if not bool(validation["ok"]):
		return SacrificeResult.failed(
			definition.id if definition != null else &"", validation["reason"]
		)

	# 2. snapshot (the rollback point)
	var before: Dictionary = state.snapshot()
	var components_before: Dictionary = IntegrityService.components_of(
		state.structural_snapshot(), _balance
	)

	var result := SacrificeResult.new()
	result.definition_id = definition.id
	result.before = before

	# 3. apply cost, 4. integrity recalculates inside each structural command
	var cost_applied: Dictionary = _apply_cost(state, definition)
	if not bool(cost_applied["ok"]):
		state.restore(before)
		return SacrificeResult.failed(definition.id, cost_applied["reason"])

	var components_after: Dictionary = IntegrityService.components_of(
		state.structural_snapshot(), _balance
	)
	result.cost_score = _cost_score(components_before, components_after)

	# 5. apply reward, priced against integrity *after* the cost
	result.gain = _compute_gain(state, definition)
	_apply_reward(state, definition, result.gain)

	# 6. derived values are recalculated by every structural command; this is a
	#    belt-and-braces call for reward paths that touch nothing structural.
	state.recalculate_derived()

	# 7. imbalance
	result.imbalance_delta = _imbalance_delta(definition, result.cost_score)
	state.add_imbalance(result.imbalance_delta)

	state.record_sacrifice(definition.id, definition.tags)

	result.after = state.snapshot()
	result.deltas = _deltas(result.before, result.after)
	result.warnings = _warnings(definition, result)
	result.ok = true
	return result


func _apply_cost(state: RunState, definition: SacrificeDefinition) -> Dictionary:
	if not is_equal_approx(definition.cost_max_hp_multiplier, 1.0):
		state.scale_max_hp(definition.cost_max_hp_multiplier)
	if not is_equal_approx(definition.cost_max_stamina_multiplier, 1.0):
		state.scale_max_stamina(definition.cost_max_stamina_multiplier)
	if not is_equal_approx(definition.cost_armour_multiplier, 1.0):
		state.set_armour(state.armour() * definition.cost_armour_multiplier)
	if not is_equal_approx(definition.cost_stamina_recovery_multiplier, 1.0):
		state.set_stamina_recovery(
			state.stamina_recovery() * definition.cost_stamina_recovery_multiplier
		)
	for lock_id in definition.cost_structural_locks:
		state.add_structural_lock(lock_id)
	for tax_id in definition.cost_action_taxes:
		state.add_action_tax(tax_id)
	return {"ok": true, "reason": ""}


func _apply_reward(state: RunState, definition: SacrificeDefinition, gain: float) -> void:
	if not is_zero_approx(definition.reward_additive):
		state.add_additive(definition.reward_additive)
	if definition.reward_generic_more:
		state.multiply_more(1.0 + gain)
	if not is_zero_approx(definition.reward_crit_rate):
		state.add_crit_rate(definition.reward_crit_rate)
	if not is_zero_approx(definition.reward_crit_damage):
		state.add_crit_damage(definition.reward_crit_damage)
	if not is_equal_approx(definition.reward_attack_speed_multiplier, 1.0):
		state.multiply_attack_speed(definition.reward_attack_speed_multiplier)


## G = g_S * (0.55 + 1.45 * D) * Q, with D = (1 - I)^1.35 (section 5.5).
func _compute_gain(state: RunState, definition: SacrificeDefinition) -> float:
	var deficiency: float = pow(maxf(0.0, 1.0 - state.integrity()), _balance.deficiency_exponent)
	var base_gain: float = _strength_gain(definition.strength)
	var quality: float = _synergy_quality(state, definition)
	return base_gain * (_balance.reward_base + _balance.reward_slope * deficiency) * quality


func _strength_gain(strength: int) -> float:
	var table: PackedFloat32Array = _balance.strength_gain
	var index: int = clampi(strength, 0, table.size() - 1)
	return table[index]


## Q = clamp(1 + 0.12 * N_synergy - 0.08 * N_dilution, 0.85, 1.45).
## Dilution starts once a tag is held four times over (section 9.3).
func _synergy_quality(state: RunState, definition: SacrificeDefinition) -> float:
	var synergy := 0
	var dilution := 0
	for tag in definition.tags:
		var owned: int = state.tag_count(tag)
		if owned > 0:
			synergy += 1
		dilution += maxi(0, owned - 2)
	return clampf(
		1.0 + _balance.synergy_bonus * synergy - _balance.dilution_penalty * dilution,
		_balance.synergy_quality_min,
		_balance.synergy_quality_max
	)


## C_res = 100*dh + 80*ds + 60*da + 50*dr over integrity component drops.
func _cost_score(before: Dictionary, after: Dictionary) -> float:
	return (
		_balance.cost_weight_hp * maxf(0.0, float(before["h"]) - float(after["h"]))
		+ _balance.cost_weight_stamina * maxf(0.0, float(before["s"]) - float(after["s"]))
		+ _balance.cost_weight_armour * maxf(0.0, float(before["a"]) - float(after["a"]))
		+ _balance.cost_weight_recovery * maxf(0.0, float(before["r"]) - float(after["r"]))
	)


func _imbalance_delta(definition: SacrificeDefinition, cost_score: float) -> float:
	if definition.imbalance_flat > 0.0:
		return definition.imbalance_flat
	return cost_score * (
		_balance.imbalance_base_factor + _balance.imbalance_strength_factor * definition.strength
	)


func _deltas(before: Dictionary, after: Dictionary) -> Dictionary:
	var tracked: Array[String] = [
		"max_hp", "current_hp", "max_stamina", "armour", "stamina_recovery",
		"attack", "additive_sum", "more_product", "crit_rate", "crit_damage",
		"attack_speed", "integrity", "imbalance", "effective_hp", "dps_estimate",
	]
	var deltas: Dictionary = {}
	for key in tracked:
		deltas[key] = float(after[key]) - float(before[key])
	return deltas


func _warnings(definition: SacrificeDefinition, result: SacrificeResult) -> Array[String]:
	var warnings: Array[String] = []
	if definition.warning_level == &"high":
		warnings.append("High-risk rule cost")
	for lock_id in definition.cost_structural_locks:
		warnings.append("Permanent rule lock: %s" % lock_id)
	for tax_id in definition.cost_action_taxes:
		warnings.append("Action tax: %s" % tax_id)
	if float(result.deltas.get("effective_hp", 0.0)) < 0.0:
		warnings.append(
			"Effective HP %.1f → %.1f"
			% [result.before["effective_hp"], result.after["effective_hp"]]
		)
	return warnings


func _group_is_taken(state: RunState, group: StringName) -> bool:
	for owned_id in state.sacrifice_history():
		var owned: SacrificeDefinition = GameData.definition(owned_id)
		if owned != null and owned.exclusive_group == group:
			return true
	return false
