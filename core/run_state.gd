class_name RunState
extends RefCounted
## Authoritative state for one run.
##
## Contract (frozen — see docs/INTERFACES.md):
##   * Fields are private. Read through getters; write only through the named
##     commands below. UI never calls a command — it observes and asks a
##     service.
##   * Structural values (max HP, max stamina, armour, recovery, locks, taxes)
##     feed structural integrity. Momentary values (current HP, current
##     stamina) never do. This split is the whole reason the class exists:
##     taking a hit must not make the next sacrifice more rewarding.
##   * Every structural mutation ends with `recalculate_derived()`, which is the
##     single place derived values are produced.

const STATUS_IDLE := &"idle"
const STATUS_ACTIVE := &"active"
const STATUS_VICTORY := &"victory"
const STATUS_DEFEAT := &"defeat"

# --- structural -------------------------------------------------------------
var _max_hp: float = 0.0
var _max_stamina: float = 0.0
var _armour: float = 0.0
var _stamina_recovery: float = 0.0
var _attack: float = 0.0
var _crit_rate: float = 0.0
var _crit_damage: float = 0.0
var _attack_speed: float = 0.0
var _additive_sum: float = 0.0
var _more_product: float = 1.0
var _structural_locks: Array[StringName] = []
var _action_taxes: Array[StringName] = []

# --- momentary --------------------------------------------------------------
var _current_hp: float = 0.0
var _current_stamina: float = 0.0

# --- run bookkeeping --------------------------------------------------------
var _integrity: float = 1.0
var _imbalance: float = 0.0
var _effective_hp: float = 0.0
var _dps_estimate: float = 0.0
var _sacrifice_history: Array[StringName] = []
var _build_tags: Dictionary = {}
var _run_seed: int = 0
var _run_status: StringName = STATUS_IDLE

var _balance: BalanceConfig


static func create(balance: BalanceConfig, run_seed: int) -> RunState:
	var state: RunState = RunState.new()
	state._balance = balance
	state._run_seed = run_seed
	state._max_hp = balance.base_max_hp
	state._max_stamina = balance.base_max_stamina
	state._armour = balance.base_armour
	state._stamina_recovery = balance.base_stamina_recovery
	state._attack = balance.base_attack
	state._crit_rate = balance.base_crit_rate
	state._crit_damage = balance.base_crit_damage
	state._attack_speed = balance.base_attack_speed
	state._current_hp = state._max_hp
	state._current_stamina = state._max_stamina
	state.recalculate_derived()
	return state


# --- reads ------------------------------------------------------------------
func balance() -> BalanceConfig: return _balance
func max_hp() -> float: return _max_hp
func current_hp() -> float: return _current_hp
func max_stamina() -> float: return _max_stamina
func current_stamina() -> float: return _current_stamina
func armour() -> float: return _armour
func stamina_recovery() -> float: return _stamina_recovery
func attack() -> float: return _attack
func crit_rate() -> float: return _crit_rate
func crit_damage() -> float: return _crit_damage
func attack_speed() -> float: return _attack_speed
func additive_sum() -> float: return _additive_sum
func more_product() -> float: return _more_product
func structural_locks() -> Array[StringName]: return _structural_locks.duplicate()
func action_taxes() -> Array[StringName]: return _action_taxes.duplicate()
func integrity() -> float: return _integrity
func imbalance() -> float: return _imbalance
func effective_hp() -> float: return _effective_hp
func dps_estimate() -> float: return _dps_estimate
func sacrifice_history() -> Array[StringName]: return _sacrifice_history.duplicate()
func build_tags() -> Dictionary: return _build_tags.duplicate()
func run_seed() -> int: return _run_seed
func run_status() -> StringName: return _run_status
func is_alive() -> bool: return _current_hp > 0.0

func hp_ratio() -> float:
	return 0.0 if _max_hp <= 0.0 else clampf(_current_hp / _max_hp, 0.0, 1.0)

func stamina_ratio() -> float:
	return 0.0 if _max_stamina <= 0.0 else clampf(_current_stamina / _max_stamina, 0.0, 1.0)

## True while the player is in the "guttering candle" band (section 6.4).
## Momentary, deliberately not part of integrity.
func is_guttering() -> bool:
	return hp_ratio() <= _balance.guttering_threshold and is_alive()

func tag_count(tag: StringName) -> int:
	return int(_build_tags.get(tag, 0))

## Structural inputs for IntegrityService. Passing primitives keeps the service
## pure and avoids a class-level cycle between RunState and the service.
func structural_snapshot() -> Dictionary:
	return {
		"max_hp": _max_hp,
		"max_stamina": _max_stamina,
		"armour": _armour,
		"stamina_recovery": _stamina_recovery,
		"major_locks": _structural_locks.size(),
		"action_taxes": _action_taxes.size(),
	}

## Offensive inputs for DerivedStats and CombatResolver, as primitives.
func offence_snapshot() -> Dictionary:
	return {
		"attack": _attack,
		"attack_speed": _attack_speed,
		"additive_sum": _additive_sum,
		"more_product": _more_product,
		"crit_rate": _crit_rate,
		"crit_damage": _crit_damage,
	}


# --- momentary commands -----------------------------------------------------
## Applies already-mitigated damage. Returns the amount actually removed.
func apply_damage(amount: float) -> float:
	var before: float = _current_hp
	_current_hp = maxf(0.0, _current_hp - maxf(0.0, amount))
	return before - _current_hp

## Healing restores current HP only. It can never restore sacrificed structure,
## which is why it does not touch `_max_hp` or trigger a structural recalc.
func heal(amount: float) -> float:
	var before: float = _current_hp
	_current_hp = minf(_max_hp, _current_hp + maxf(0.0, amount))
	return _current_hp - before

func set_current_hp(value: float) -> void:
	_current_hp = clampf(value, 0.0, _max_hp)

func spend_stamina(amount: float) -> void:
	_current_stamina = clampf(_current_stamina - maxf(0.0, amount), 0.0, _max_stamina)

func regenerate_stamina(amount: float) -> void:
	_current_stamina = clampf(_current_stamina + maxf(0.0, amount), 0.0, _max_stamina)

func set_run_status(status: StringName) -> void:
	_run_status = status


# --- structural commands ----------------------------------------------------
# Called by systems/sacrifice_service.gd and by debug tooling. Each one ends in
# recalculate_derived() so no caller can forget.

func scale_max_hp(factor: float) -> void:
	_max_hp = maxf(_balance.min_max_hp, _max_hp * factor)
	_current_hp = minf(_current_hp, _max_hp)
	recalculate_derived()

func scale_max_stamina(factor: float) -> void:
	_max_stamina = maxf(_balance.min_max_stamina, _max_stamina * factor)
	_current_stamina = minf(_current_stamina, _max_stamina)
	recalculate_derived()

func set_armour(value: float) -> void:
	_armour = maxf(_balance.min_armour, value)
	recalculate_derived()

func set_stamina_recovery(value: float) -> void:
	_stamina_recovery = maxf(0.0, value)
	recalculate_derived()

## Flat base attack, used by meta progression at run creation. Offensive, not
## structural, so it does not move integrity — a permanent upgrade must not make
## the body read as more broken or more whole.
func add_flat_attack(value: float) -> void:
	_attack = maxf(0.0, _attack + value)
	recalculate_derived()

func add_additive(value: float) -> void:
	_additive_sum += value
	recalculate_derived()

func multiply_more(factor: float) -> void:
	_more_product *= factor
	recalculate_derived()

func add_crit_rate(value: float) -> void:
	_crit_rate += value
	recalculate_derived()

func add_crit_damage(value: float) -> void:
	_crit_damage += value
	recalculate_derived()

func multiply_attack_speed(factor: float) -> void:
	_attack_speed *= factor
	recalculate_derived()

func add_structural_lock(lock_id: StringName) -> void:
	if not _structural_locks.has(lock_id):
		_structural_locks.append(lock_id)
		recalculate_derived()

func add_action_tax(tax_id: StringName) -> void:
	if not _action_taxes.has(tax_id):
		_action_taxes.append(tax_id)
		recalculate_derived()

func add_imbalance(value: float) -> void:
	_imbalance = clampf(_imbalance + value, 0.0, _balance.imbalance_max)

func record_sacrifice(id: StringName, tags: Array[StringName]) -> void:
	_sacrifice_history.append(id)
	for tag in tags:
		_build_tags[tag] = int(_build_tags.get(tag, 0)) + 1


## The single place derived values are produced. Called by every structural
## command; call it directly only after a bulk restore.
func recalculate_derived() -> void:
	_integrity = IntegrityService.compute(structural_snapshot(), _balance)
	_effective_hp = DerivedStats.effective_hp(_max_hp, _armour)
	_dps_estimate = DerivedStats.dps_estimate(offence_snapshot(), _balance)


# --- snapshots --------------------------------------------------------------
## Immutable value copy, used for preview, rollback, logging and tests.
func snapshot() -> Dictionary:
	return {
		"max_hp": _max_hp,
		"current_hp": _current_hp,
		"max_stamina": _max_stamina,
		"current_stamina": _current_stamina,
		"armour": _armour,
		"stamina_recovery": _stamina_recovery,
		"attack": _attack,
		"crit_rate": _crit_rate,
		"crit_damage": _crit_damage,
		"attack_speed": _attack_speed,
		"additive_sum": _additive_sum,
		"more_product": _more_product,
		"structural_locks": _structural_locks.duplicate(),
		"action_taxes": _action_taxes.duplicate(),
		"integrity": _integrity,
		"imbalance": _imbalance,
		"effective_hp": _effective_hp,
		"dps_estimate": _dps_estimate,
		"sacrifice_history": _sacrifice_history.duplicate(),
		"build_tags": _build_tags.duplicate(),
		"run_seed": _run_seed,
		"run_status": _run_status,
	}

func restore(snap: Dictionary) -> void:
	_max_hp = float(snap["max_hp"])
	_current_hp = float(snap["current_hp"])
	_max_stamina = float(snap["max_stamina"])
	_current_stamina = float(snap["current_stamina"])
	_armour = float(snap["armour"])
	_stamina_recovery = float(snap["stamina_recovery"])
	_attack = float(snap["attack"])
	_crit_rate = float(snap["crit_rate"])
	_crit_damage = float(snap["crit_damage"])
	_attack_speed = float(snap["attack_speed"])
	_additive_sum = float(snap["additive_sum"])
	_more_product = float(snap["more_product"])
	_structural_locks = (snap["structural_locks"] as Array).duplicate()
	_action_taxes = (snap["action_taxes"] as Array).duplicate()
	_imbalance = float(snap["imbalance"])
	_sacrifice_history = (snap["sacrifice_history"] as Array).duplicate()
	_build_tags = (snap["build_tags"] as Dictionary).duplicate()
	_run_seed = int(snap["run_seed"])
	_run_status = snap["run_status"]
	recalculate_derived()

## Detached copy sharing the same BalanceConfig. Mutating the clone cannot
## touch the original — this is what `preview` runs against.
func clone() -> RunState:
	var copy: RunState = RunState.new()
	copy._balance = _balance
	copy.restore(snapshot())
	return copy

## Stable digest of the snapshot, for telemetry correlation and test asserts.
func snapshot_hash() -> String:
	var snap: Dictionary = snapshot()
	var keys: Array = snap.keys()
	keys.sort()
	var parts := PackedStringArray()
	for key in keys:
		parts.append("%s=%s" % [key, snap[key]])
	return "\n".join(parts).sha256_text().substr(0, 16)
