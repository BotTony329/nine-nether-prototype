class_name DamageContext
extends RefCounted
## Input to CombatResolver. Everything the resolver needs, so it never has to
## reach back into a scene node or an autoload for gameplay values.
##
## Contract (frozen — see docs/INTERFACES.md): to add a new damage source,
## populate a context. Do not add a second damage path.

var source_id: StringName = &"unknown"
var target_id: StringName = &"unknown"

## Weapon or attack base value before any bucket is applied.
var base_damage: float = 0.0
## Per-move scalar (light attack 1.0, heavy > 1.0, ...).
var skill_multiplier: float = 1.0

## Bucket 1: everything sums, then multiplies once as (1 + sum).
var additive_modifiers: Array[float] = []
## Bucket 2: a small number of explicitly-"more" effects, multiplied together.
var more_modifiers: Array[float] = []
## Bucket 3: situational effects (low HP, perfect dodge, backstab).
var conditional_modifiers: Array[float] = []

## Critical rules.
var crit_allowed: bool = true
var crit_rate: float = 0.0
var crit_damage: float = 1.0
## -1 draws from the combat RNG stream; 0.0..1.0 supplies a fixed roll. Tests
## and replays set this so a crit is never an untestable coin flip.
var crit_roll: float = -1.0
## Overrides the roll entirely: 1 forces a crit, 0 forbids one, -1 is normal.
var force_crit: int = -1

## Armour interaction. Penetration is subtracted before mitigation.
var target_armour: float = 0.0
var armour_penetration: float = 0.0
## > 1.0 means the target takes extra damage.
var vulnerability: float = 1.0

## Target HP at resolve time, used to mark the result lethal.
var target_current_hp: float = 0.0

var tags: Array[StringName] = []
var metadata: Dictionary = {}


func additive_sum() -> float:
	var total := 0.0
	for value in additive_modifiers:
		total += value
	return total

func more_product() -> float:
	var product := 1.0
	for value in more_modifiers:
		product *= (1.0 + value)
	return product

func conditional_product() -> float:
	var product := 1.0
	for value in conditional_modifiers:
		product *= (1.0 + value)
	return product
