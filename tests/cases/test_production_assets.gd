extends TestCase
## Art V3 production validation: declared metadata, frame resources, scene-local
## foot alignment, transparency, and removal of live actor placeholders.

const ACTORS := {
	"player": {
		"scene": "res://actors/player/player.tscn",
		"frames": "res://assets_v3/godot/player_frames.tres",
		"map": "res://assets_v3/production/player/frame_map.json",
		"counts": {&"player_idle": 4, &"player_run": 6, &"player_jump": 2, &"player_fall": 2, &"player_light_attack_1": 8, &"player_hurt": 2, &"player_death": 6},
	},
	"ghost_melee": {
		"scene": "res://actors/enemies/ghost_melee.tscn",
		"frames": "res://assets_v3/godot/melee_ghost_frames.tres",
		"map": "res://assets_v3/production/ghost_melee/frame_map.json",
		"counts": {&"melee_ghost_idle": 4, &"melee_ghost_walk": 6, &"melee_ghost_attack": 8, &"melee_ghost_hurt": 2, &"melee_ghost_death": 4},
	},
	"ghost_archer": {
		"scene": "res://actors/enemies/ghost_archer.tscn",
		"frames": "res://assets_v3/godot/ghost_archer_frames.tres",
		"map": "res://assets_v3/production/ghost_archer/frame_map.json",
		"counts": {&"ghost_archer_idle": 4, &"ghost_archer_retreat": 6, &"ghost_archer_aim": 6, &"ghost_archer_shoot": 4, &"ghost_archer_hurt": 2, &"ghost_archer_death": 4},
	},
	"gate_warden": {
		"scene": "res://actors/boss/boss.tscn",
		"frames": "res://assets_v3/godot/gate_warden_frames.tres",
		"map": "res://assets_v3/production/gate_warden/frame_map.json",
		"counts": {&"gate_warden_idle": 4, &"gate_warden_walk": 6, &"gate_warden_attack_1": 10, &"gate_warden_hurt": 2, &"gate_warden_death": 8},
	},
}


func test_actor_frame_maps_match_sprite_resources() -> void:
	for actor_name: String in ACTORS:
		var spec: Dictionary = ACTORS[actor_name]
		var metadata := _read_json(spec["map"])
		assert_not_null(metadata, "%s frame map parses" % actor_name)
		var frame_size := Vector2i(metadata["frame_size"][0], metadata["frame_size"][1])
		var frames := load(spec["frames"]) as SpriteFrames
		assert_not_null(frames, "%s SpriteFrames loads" % actor_name)
		for animation: StringName in spec["counts"]:
			assert_true(frames.has_animation(animation), "%s has %s" % [actor_name, animation])
			assert_equal(frames.get_frame_count(animation), spec["counts"][animation], "%s %s frame count" % [actor_name, animation])
			var texture := frames.get_frame_texture(animation, 0)
			assert_equal(texture.get_size(), Vector2(frame_size), "%s %s uses declared frame size" % [actor_name, animation])
			assert_true(texture is AtlasTexture, "%s %s uses an atlas frame" % [actor_name, animation])
			assert_true((texture as AtlasTexture).atlas.resource_path.begins_with("res://assets_v3/production/"), "%s %s resolves to V3 art" % [actor_name, animation])


func test_declared_foot_positions_land_on_actor_origins() -> void:
	for actor_name: String in ACTORS:
		var spec: Dictionary = ACTORS[actor_name]
		var metadata := _read_json(spec["map"])
		var scene := load(spec["scene"]) as PackedScene
		var actor := scene.instantiate() as Node2D
		var sprite := actor.get_node("Sprite") as AnimatedSprite2D
		var frame_height := float(metadata["frame_size"][1])
		var foot_y := float(metadata["foot_position"][1])
		var visual_foot_y := sprite.position.y + (foot_y - frame_height * 0.5) * sprite.scale.y
		assert_almost(visual_foot_y, 0.0, "%s visible foot meets stable actor origin" % actor_name, 0.01)
		actor.free()


func test_every_production_frame_is_anchored_to_declared_baseline() -> void:
	for actor_name: String in ACTORS:
		var spec: Dictionary = ACTORS[actor_name]
		var metadata := _read_json(spec["map"])
		var frame_width := int(metadata["frame_size"][0])
		var frame_height := int(metadata["frame_size"][1])
		var foot_y := int(metadata["foot_position"][1])
		for animation: String in metadata["animations"]:
			var path := "res://assets_v3/production/%s/%s_%s.png" % [actor_name, actor_name, animation]
			var image := Image.new()
			assert_equal(image.load(ProjectSettings.globalize_path(path)), OK, "%s loads" % path)
			var count := int(metadata["animations"][animation]["frames"])
			for frame_index in count:
				var frame := image.get_region(Rect2i(frame_index * frame_width, 0, frame_width, frame_height))
				var used := frame.get_used_rect()
				assert_equal(used.end.y, foot_y, "%s %s frame %d reaches declared foot baseline" % [actor_name, animation, frame_index])


func test_production_pngs_are_rgba_and_have_transparent_margins() -> void:
	var paths := [
		"res://assets_v3/production/player/player_idle.png",
		"res://assets_v3/production/ghost_melee/ghost_melee_idle.png",
		"res://assets_v3/production/ghost_archer/ghost_archer_idle.png",
		"res://assets_v3/production/gate_warden/gate_warden_idle.png",
		"res://assets_v3/production/effects/slash.png",
		"res://assets_v3/production/icons/icon_hp.png",
		"res://assets_v3/production/projectiles/ghost_arrow.png",
	]
	for path: String in paths:
		var image := Image.new()
		assert_equal(image.load(ProjectSettings.globalize_path(path)), OK, "%s loads" % path)
		assert_true(image.detect_alpha() != Image.ALPHA_NONE, "%s carries alpha" % path)
		assert_equal(image.get_pixel(0, 0).a, 0.0, "%s has a transparent margin" % path)


func test_live_scenes_reference_v3_production_art() -> void:
	var arrow := (load("res://actors/enemies/ghost_arrow.tscn") as PackedScene).instantiate()
	assert_not_null(arrow.get_node_or_null("FallbackVisual"), "develop emergency fallback remains available")
	assert_false((arrow.get_node("FallbackVisual") as CanvasItem).visible, "polygon arrow fallback is hidden")
	var arrow_visual := arrow.get_node("Visual") as Sprite2D
	assert_true(arrow_visual.texture.resource_path.begins_with("res://assets_v3/production/"), "arrow uses V3 texture")
	arrow.free()

	var arena := (load("res://scenes/arena.tscn") as PackedScene).instantiate()
	for node_path: String in ["Terrain/Floor/Surface", "Terrain/LeftWall/Surface", "Props/FortressGate"]:
		var visual := arena.get_node(node_path) as Sprite2D
		assert_true(visual.texture.resource_path.begins_with("res://assets_v3/production/"), "%s uses V3 texture" % node_path)
	assert_not_null(arena.get_node_or_null("Props/GhostFireLeft"), "V3 ghost fire is present")
	arena.free()

	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	assert_not_null(main.get_node_or_null("CombatFeedback"), "one V3 combat-feedback observer is present")
	assert_null(main.get_node_or_null("CombatEffects"), "legacy hit observer is not duplicated")
	var feedback_script := main.get_node("CombatFeedback").get_script() as Script
	var effects: Dictionary = feedback_script.get_script_constant_map()["EFFECTS"]
	for effect_name: StringName in [&"slash", &"hit", &"blood", &"death"]:
		var texture: Texture2D = effects[effect_name]["texture"]
		assert_true(texture.resource_path.begins_with("res://assets_v3/production/"), "%s feedback maps to V3" % effect_name)
	var hud := main.get_node("UIRoot/Hud")
	assert_true((hud.get_node("Player/Icon") as TextureRect).texture.resource_path.begins_with("res://assets_v3/production/"), "player HUD uses V3 HP icon")
	assert_true((hud.get_node("Boss/Icon") as TextureRect).texture.resource_path.begins_with("res://assets_v3/production/"), "Boss HUD uses V3 icon")
	assert_null(hud.get_node_or_null("Player/StaminaIcon"), "obsolete V2 stamina icon is absent")
	assert_null(hud.get_node_or_null("Player/AttackIcon"), "obsolete V2 attack icon is absent")
	assert_null(hud.get_node_or_null("Player/IntegrityIcon"), "obsolete V2 integrity icon is absent")
	assert_null(hud.get_node_or_null("Player/ImbalanceIcon"), "obsolete V2 imbalance icon is absent")
	main.free()


func test_live_actor_scenes_have_no_legacy_visual_paths() -> void:
	var paths := [
		"res://actors/player/player.tscn",
		"res://actors/enemies/ghost_melee.tscn",
		"res://actors/enemies/ghost_archer.tscn",
		"res://actors/enemies/ghost_arrow.tscn",
		"res://actors/boss/boss.tscn",
	]
	for path: String in paths:
		var file := FileAccess.open(path, FileAccess.READ)
		assert_not_null(file, "%s opens" % path)
		if file == null:
			continue
		var source := file.get_as_text()
		assert_false(source.contains("res://assets_v2/"), "%s has no Art V2 visual reference" % path)
		assert_false(source.contains("res://assets/player/") or source.contains("res://assets/enemy/") or source.contains("res://assets/boss/"), "%s has no Art V1 actor reference" % path)


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}
