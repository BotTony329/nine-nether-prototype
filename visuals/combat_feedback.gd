extends Node
## Presentation-only observer for confirmed combat events.
##
## This node never calculates or applies damage.  It consumes the frozen
## EventBus payload after CombatResolver has completed, then creates transient
## visual/audio-timing feedback only.

const EFFECTS := {
	&"slash": {
		"texture": preload("res://assets_v3/production/effects/slash.png"),
		"frame_size": Vector2i(96, 64), "frames": 4, "fps": 12.0,
	},
	&"hit": {
		"texture": preload("res://assets_v3/production/effects/hit.png"),
		"frame_size": Vector2i(64, 64), "frames": 4, "fps": 16.0,
	},
	&"blood": {
		"texture": preload("res://assets_v3/production/effects/blood.png"),
		"frame_size": Vector2i(96, 64), "frames": 4, "fps": 14.0,
	},
	&"death": {
		"texture": preload("res://assets_v3/production/effects/death.png"),
		"frame_size": Vector2i(64, 80), "frames": 6, "fps": 10.0,
	},
}

var _hit_stop_active := false


func _ready() -> void:
	EventBus.hit_dealt.connect(_on_hit)
	EventBus.hit_taken.connect(_on_hit)
	EventBus.enemy_died.connect(_on_death)
	EventBus.boss_died.connect(_on_death)
	EventBus.player_died.connect(_on_player_death)


func _exit_tree() -> void:
	# A run restart or scene transition can destroy this observer while the
	# unscaled timer is pending.  Never let presentation timing leak globally.
	if _hit_stop_active:
		Engine.time_scale = 1.0
		_hit_stop_active = false


func _on_hit(payload: Dictionary) -> void:
	if float(payload.get("final_damage", 0.0)) <= 0.0:
		return
	var target := _find_actor(StringName(payload.get("target_id", &"unknown")))
	if target == null:
		return
	var point := target.global_position + Vector2(0.0, -18.0)
	_spawn_effect(&"slash", point + Vector2(-8.0, 0.0), 0.52)
	_spawn_effect(&"hit", point, 0.52)
	_spawn_effect(&"blood", point + Vector2(5.0, 2.0), 0.42)
	_spawn_damage_number(point, float(payload["final_damage"]), bool(payload.get("is_critical", false)))
	_flash_actor(target)
	_shake_camera()
	_start_hit_stop()


func _on_death(payload: Dictionary) -> void:
	var actor := _find_actor(StringName(payload.get("actor_id", &"unknown")))
	if actor != null:
		_spawn_effect(&"death", actor.global_position + Vector2(0.0, -16.0), 0.62)


func _on_player_death(_payload: Dictionary) -> void:
	var player := _find_actor(&"player")
	if player != null:
		_spawn_effect(&"death", player.global_position + Vector2(0.0, -16.0), 0.62)


func _spawn_effect(effect_name: StringName, world_position: Vector2, visual_scale: float) -> void:
	var spec: Dictionary = EFFECTS[effect_name]
	var frames := SpriteFrames.new()
	frames.add_animation(&"effect")
	frames.set_animation_loop(&"effect", false)
	frames.set_animation_speed(&"effect", float(spec["fps"]))
	for index in int(spec["frames"]):
		var atlas := AtlasTexture.new()
		atlas.atlas = spec["texture"]
		var frame_size: Vector2i = spec["frame_size"]
		atlas.region = Rect2(index * frame_size.x, 0, frame_size.x, frame_size.y)
		frames.add_frame(&"effect", atlas)
	var effect := AnimatedSprite2D.new()
	effect.sprite_frames = frames
	effect.animation = &"effect"
	effect.global_position = world_position
	effect.scale = Vector2.ONE * visual_scale
	effect.z_index = 20
	add_child(effect)
	effect.animation_finished.connect(effect.queue_free)
	effect.play()


func _spawn_damage_number(world_position: Vector2, amount: float, critical: bool) -> void:
	var label := Label.new()
	label.text = str(roundi(amount))
	label.global_position = world_position + Vector2(-8.0, -6.0)
	label.z_index = 24
	label.add_theme_font_size_override("font_size", 10 if not critical else 12)
	label.add_theme_color_override("font_color", Color("f1d79b") if not critical else Color("fff0ae"))
	label.add_theme_color_override("font_outline_color", Color("251c24"))
	label.add_theme_constant_override("outline_size", 2)
	add_child(label)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0.0, -18.0), 0.42)
	tween.tween_property(label, "modulate:a", 0.0, 0.42).set_delay(0.12)
	tween.chain().tween_callback(label.queue_free)


func _flash_actor(actor: Node) -> void:
	var sprite := actor.get_node_or_null("Sprite") as CanvasItem
	if sprite == null:
		return
	var original := sprite.modulate
	sprite.modulate = Color(1.0, 0.58, 0.5, original.a)
	create_tween().tween_property(sprite, "modulate", original, 0.09)


func _shake_camera() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var original := camera.offset
	var tween := create_tween()
	tween.tween_property(camera, "offset", original + Vector2(2.0, -1.0), 0.025)
	tween.tween_property(camera, "offset", original + Vector2(-1.0, 1.0), 0.025)
	tween.tween_property(camera, "offset", original, 0.035)


func _start_hit_stop() -> void:
	if _hit_stop_active:
		return
	_hit_stop_active = true
	Engine.time_scale = 0.12
	await get_tree().create_timer(0.035, true, false, true).timeout
	Engine.time_scale = 1.0
	_hit_stop_active = false


func _find_actor(wanted_id: StringName) -> Node2D:
	for node in get_tree().get_nodes_in_group(&"combat_actor"):
		if node.has_method("actor_id") and node.call("actor_id") == wanted_id:
			return node as Node2D
	# Existing actors predate the presentation group, so retain a read-only
	# fallback that discovers the same Damageable contract recursively.
	for node in get_tree().root.find_children("*", "Node2D", true, false):
		if node.has_method("actor_id") and node.call("actor_id") == wanted_id:
			return node as Node2D
	return null
