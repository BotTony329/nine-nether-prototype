class_name Hitbox
extends Area2D
## Dealing half of a damage exchange. Emits `hit_actor` once per actor per
## swing; the *attacker* decides what that hit means by building a
## DamageContext. The hitbox itself knows nothing about damage numbers.
##
## Physics layer: `player_hitbox` or `enemy_hitbox`. Mask: the opposing
## hurtbox layer.
##
## `monitoring` stays on for the node's whole life and activity is gated by
## `set_active`, because toggling `monitoring` mid-frame makes Godot drop
## overlaps that began on the same frame.

signal hit_actor(actor: Node)

var _active: bool = false
var _already_hit: Array[Node] = []

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func is_active() -> bool:
	return _active

## Opens or closes the active window. Opening clears the per-swing memory and
## immediately resolves anything already inside the box, so a target standing on
## top of the attacker is not skipped.
func set_active(value: bool) -> void:
	if _active == value:
		return
	_active = value
	if not _active:
		return
	_already_hit.clear()
	for area in get_overlapping_areas():
		_try_hit(area)

func _on_area_entered(area: Area2D) -> void:
	_try_hit(area)

func _try_hit(area: Area2D) -> void:
	if not _active or not (area is Hurtbox):
		return
	var target: Node = (area as Hurtbox).actor()
	if target == null or _already_hit.has(target):
		return
	_already_hit.append(target)
	hit_actor.emit(target)
