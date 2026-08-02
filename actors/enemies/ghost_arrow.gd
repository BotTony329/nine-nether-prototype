class_name GhostArrow
extends Area2D
## One-hit, non-homing Ghost Archer projectile. It builds a DamageContext and
## delegates damage application to the target's existing Damageable contract.

signal impacted(target: Node)

var _source_id: StringName = &"unknown"
var _owner_actor: Node
var _direction: Vector2 = Vector2.RIGHT
var _speed: float
var _damage: float
var _skill_multiplier: float
var _remaining_lifetime: float
var _has_impacted: bool = false
var _configured: bool = false


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	var visual := get_node_or_null(^"Visual") as Sprite2D
	var fallback := get_node_or_null(^"FallbackVisual") as CanvasItem
	if fallback != null:
		fallback.visible = visual == null or visual.texture == null


func configure(
	source_id: StringName,
	owner_actor: Node,
	direction: Vector2,
	damage: float,
	skill_multiplier: float,
	speed: float,
	lifetime: float
) -> void:
	_source_id = source_id
	_owner_actor = owner_actor
	_direction = direction.normalized()
	_damage = damage
	_skill_multiplier = skill_multiplier
	_speed = speed
	_remaining_lifetime = lifetime
	rotation = _direction.angle()
	_configured = true


func _physics_process(delta: float) -> void:
	if not _configured or _has_impacted:
		return
	global_position += _direction * _speed * delta
	_remaining_lifetime -= delta
	if _remaining_lifetime <= 0.0:
		_expire()


func has_impacted() -> bool:
	return _has_impacted


func uses_v2_texture() -> bool:
	var visual := get_node_or_null(^"Visual") as Sprite2D
	return visual != null and visual.texture != null


func _on_area_entered(area: Area2D) -> void:
	if _has_impacted or not (area is Hurtbox):
		return
	var target := (area as Hurtbox).actor()
	if target == null or target == _owner_actor or not target.has_method("receive_damage"):
		return

	var context := DamageContext.new()
	context.source_id = _source_id
	context.target_id = target.call("actor_id")
	context.base_damage = _damage
	context.skill_multiplier = _skill_multiplier
	context.crit_allowed = false
	context.target_armour = float(target.call("armour"))
	context.target_current_hp = float(target.call("current_hp"))
	context.tags = [&"ranged", &"projectile"] as Array[StringName]
	target.call("receive_damage", context)
	_impact(target)


func _on_body_entered(body: Node2D) -> void:
	if body != _owner_actor:
		_impact(body)


func _impact(target: Node) -> void:
	if _has_impacted:
		return
	_has_impacted = true
	set_deferred(&"monitoring", false)
	set_deferred(&"monitorable", false)
	impacted.emit(target)
	queue_free()


func _expire() -> void:
	if _has_impacted:
		return
	set_deferred(&"monitoring", false)
	set_deferred(&"monitorable", false)
	queue_free()
