class_name DebugShapeOverlay
extends Node2D
## Draws hit, hurt and body collision rectangles in world space.
##
## Godot only renders collision shapes when the whole run was started with
## debug collision hints, which is not something a key can turn on mid-session.
## Drawing them here makes the F8 toggle actually work while playing.
##
## Every shape in the prototype is a RectangleShape2D; anything else is skipped
## rather than approximated, so the overlay never draws a box that is not there.

const HITBOX_COLOUR := Color(0.9, 0.25, 0.25, 0.85)
const HITBOX_INACTIVE_COLOUR := Color(0.45, 0.2, 0.2, 0.45)
const HURTBOX_COLOUR := Color(0.3, 0.85, 0.45, 0.7)
const BODY_COLOUR := Color(0.6, 0.6, 0.7, 0.5)

var _enabled: bool = false

func _ready() -> void:
	z_index = 100
	visible = false

func is_enabled() -> bool:
	return _enabled

func toggle() -> void:
	set_enabled(not _enabled)

func set_enabled(value: bool) -> void:
	_enabled = value
	visible = value
	queue_redraw()

func _process(_delta: float) -> void:
	if _enabled:
		queue_redraw()

func _draw() -> void:
	if not _enabled:
		return
	_draw_subtree(get_tree().current_scene)

func _draw_subtree(node: Node) -> void:
	if node == null:
		return
	if node is CollisionShape2D:
		_draw_shape(node as CollisionShape2D)
	for child in node.get_children():
		_draw_subtree(child)

func _draw_shape(shape_node: CollisionShape2D) -> void:
	var rectangle := shape_node.shape as RectangleShape2D
	if rectangle == null or shape_node.disabled:
		return
	var half := rectangle.size * 0.5
	var transform := shape_node.global_transform
	var corners := PackedVector2Array([
		to_local(transform * Vector2(-half.x, -half.y)),
		to_local(transform * Vector2(half.x, -half.y)),
		to_local(transform * Vector2(half.x, half.y)),
		to_local(transform * Vector2(-half.x, half.y)),
	])
	corners.append(corners[0])
	draw_polyline(corners, _colour_for(shape_node.get_parent()), 1.0)

func _colour_for(owner_node: Node) -> Color:
	if owner_node is Hitbox:
		return HITBOX_COLOUR if (owner_node as Hitbox).is_active() else HITBOX_INACTIVE_COLOUR
	if owner_node is Hurtbox:
		return HURTBOX_COLOUR
	return BODY_COLOUR
