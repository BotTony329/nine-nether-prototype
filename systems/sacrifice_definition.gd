class_name SacrificeDefinition
extends Resource
## Data-driven description of one sacrifice. Content lives in
## res://data/sacrifices/*.tres; this file only declares the shape.
##
## Field groups follow Prototype Development Pack A8 (标识 / 分类 / 生成 /
## 代价 / 收益 / 触发 / 显示).

const ROLE_CONTINUATION := &"CONTINUATION"
const ROLE_RISK_ESCALATION := &"RISK_ESCALATION"
const ROLE_PIVOT_STABILIZE := &"PIVOT_STABILIZE"

@export_group("Identity")
@export var id: StringName = &""
@export var display_name: String = ""
## S1..S5. Drives the base gain coefficient g_S and the imbalance factor.
@export_range(1, 5) var strength: int = 1
@export var rarity: StringName = &"common"

@export_group("Classification")
@export var tags: Array[StringName] = []
@export var roles: Array[StringName] = []
## At most one owned sacrifice per non-empty group.
@export var exclusive_group: StringName = &""

@export_group("Generation")
@export var base_weight: float = 100.0
@export var prerequisite_min_sacrifices: int = 0
@export var banned_with: Array[StringName] = []

@export_group("Costs")
## Multipliers applied to structural stats. 1.0 means untouched.
@export var cost_max_hp_multiplier: float = 1.0
@export var cost_max_stamina_multiplier: float = 1.0
@export var cost_armour_multiplier: float = 1.0
@export var cost_stamina_recovery_multiplier: float = 1.0
## Rule locks (healing disabled, block removed, ...) and action taxes
## (dodge costs more, exhaustion lasts longer, ...).
@export var cost_structural_locks: Array[StringName] = []
@export var cost_action_taxes: Array[StringName] = []
## Authored imbalance. When > 0 this wins over the derived cost formula; see
## ADR-005. 0 falls back to dB = C * (0.75 + 0.05 * S).
@export var imbalance_flat: float = 0.0

@export_group("Rewards")
@export var reward_additive: float = 0.0
## When true the generic More bucket is multiplied by (1 + G), G from the
## saturating reward curve (research report 5.5).
@export var reward_generic_more: bool = false
@export var reward_crit_rate: float = 0.0
@export var reward_crit_damage: float = 0.0
@export var reward_attack_speed_multiplier: float = 1.0

@export_group("Triggers")
## Declarative only in M1 — nothing consumes these yet. Kept in the schema so
## card data authored by Codex X06 does not need a migration.
@export var triggers: Array = []

@export_group("Display")
@export var short_text: String = ""
@export var preview_template: String = ""
## low / medium / high — the sacrifice UI must not bury a high warning.
@export var warning_level: StringName = &"low"


## Static data validation, used by the data test. Returns human-readable
## problems; empty means valid.
func validate() -> Array[String]:
	var problems: Array[String] = []
	if String(id).is_empty():
		problems.append("missing id")
	if display_name.is_empty():
		problems.append("%s: missing display_name" % id)
	if strength < 1 or strength > 5:
		problems.append("%s: strength %d out of range 1..5" % [id, strength])
	if roles.is_empty():
		problems.append("%s: needs at least one role" % id)
	for role in roles:
		if role not in [ROLE_CONTINUATION, ROLE_RISK_ESCALATION, ROLE_PIVOT_STABILIZE]:
			problems.append("%s: unknown role %s" % [id, role])
	if not _has_any_cost():
		problems.append("%s: has no cost — every power has a price" % id)
	if not _has_any_reward():
		problems.append("%s: has no reward" % id)
	if warning_level not in [&"low", &"medium", &"high"]:
		problems.append("%s: unknown warning_level %s" % [id, warning_level])
	return problems

func _has_any_cost() -> bool:
	return (
		not is_equal_approx(cost_max_hp_multiplier, 1.0)
		or not is_equal_approx(cost_max_stamina_multiplier, 1.0)
		or not is_equal_approx(cost_armour_multiplier, 1.0)
		or not is_equal_approx(cost_stamina_recovery_multiplier, 1.0)
		or not cost_structural_locks.is_empty()
		or not cost_action_taxes.is_empty()
	)

func _has_any_reward() -> bool:
	return (
		not is_zero_approx(reward_additive)
		or reward_generic_more
		or not is_zero_approx(reward_crit_rate)
		or not is_zero_approx(reward_crit_damage)
		or not is_equal_approx(reward_attack_speed_multiplier, 1.0)
	)
