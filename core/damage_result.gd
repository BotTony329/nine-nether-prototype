class_name DamageResult
extends RefCounted
## Output of CombatResolver. The only object combat, preview and telemetry read
## damage numbers from.

var source_id: StringName = &"unknown"
var target_id: StringName = &"unknown"
## Damage after all buckets and crit, before armour.
var raw_damage: float = 0.0
## Damage actually applied to the target.
var final_damage: float = 0.0
var is_critical: bool = false
## raw_damage - final_damage, i.e. what armour and mitigation absorbed.
var mitigation: float = 0.0
var is_lethal: bool = false
## Per-stage values, so a wrong number can be traced to the bucket that made it.
var breakdown: Dictionary = {}

func to_dictionary() -> Dictionary:
	return {
		"source_id": source_id,
		"target_id": target_id,
		"raw_damage": raw_damage,
		"final_damage": final_damage,
		"is_critical": is_critical,
		"mitigation": mitigation,
		"is_lethal": is_lethal,
		"breakdown": breakdown.duplicate(),
	}
