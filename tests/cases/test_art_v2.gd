extends TestCase
## M1.5 Art V2 resource, state mapping and authored-frame timing coverage.

const MAIN_SCENE := "res://scenes/main.tscn"
const PLAYER_SCENE := "res://actors/player/player.tscn"
const MELEE_SCENE := "res://actors/enemies/ghost_melee.tscn"
const ARCHER_SCENE := "res://actors/enemies/ghost_archer.tscn"
const ARROW_SCENE := "res://actors/enemies/ghost_arrow.tscn"
const BOSS_SCENE := "res://actors/boss/boss.tscn"

var _main: Main
var _spawned: Array[Node] = []


func after_each() -> void:
	Input.action_release(&"move_left")
	Input.action_release(&"move_right")
	Input.action_release(&"jump")
	Input.action_release(&"light_attack")
	if _main != null and is_instance_valid(_main):
		_main.queue_free()
	for node in _spawned:
		if is_instance_valid(node):
			node.queue_free()
	_main = null
	_spawned.clear()


func _launch() -> RunCoordinator:
	_main = (load(MAIN_SCENE) as PackedScene).instantiate()
	tree.root.add_child(_main)
	await step_physics(3)
	return _main.coordinator()


func _spawn_enemy(scene_path: String, config_path: String, target: Node2D) -> EnemyBase:
	var enemy := (load(scene_path) as PackedScene).instantiate() as EnemyBase
	tree.root.add_child(enemy)
	_spawned.append(enemy)
	var enemy_config := (load(config_path) as EnemyConfig).duplicate(true) as EnemyConfig
	enemy_config.gravity = 0.0
	enemy.initialize(enemy_config, target)
	return enemy


func test_all_integrated_v2_resources_load_with_declared_animations() -> void:
	var player_frames := load("res://assets_v2/godot/player_frames.tres") as SpriteFrames
	var melee_frames := load("res://assets_v2/godot/melee_ghost_frames.tres") as SpriteFrames
	var archer_frames := load("res://assets_v2/godot/ghost_archer_frames.tres") as SpriteFrames
	var boss_frames := load("res://assets_v2/godot/gate_warden_frames.tres") as SpriteFrames
	assert_not_null(player_frames, "player SpriteFrames load")
	assert_not_null(melee_frames, "melee ghost SpriteFrames load")
	assert_not_null(archer_frames, "Ghost Archer SpriteFrames load")
	assert_not_null(boss_frames, "Gate Warden SpriteFrames load")
	assert_equal(player_frames.get_frame_count(&"player_light_attack_1"), 8, "player attack has 8 frames")
	assert_equal(melee_frames.get_frame_count(&"melee_ghost_attack"), 8, "melee attack has 8 frames")
	assert_equal(archer_frames.get_frame_count(&"ghost_archer_shoot"), 4, "archer shoot has 4 frames")
	assert_equal(boss_frames.get_frame_count(&"gate_warden_attack_1"), 10, "Boss attack has 10 frames")
	assert_not_null(load("res://assets_v2/projectiles/ghost_fire_arrow.png"), "Ghost Arrow texture imports")
	assert_not_null(load("res://assets_v2/effects/hit.png"), "hit effect imports")
	assert_not_null(load("res://assets_v2/effects/blade_slash.png"), "slash effect imports")


func test_actor_scenes_use_v2_frames_and_stable_foot_offsets() -> void:
	var player := (load(PLAYER_SCENE) as PackedScene).instantiate() as Player
	var melee := (load(MELEE_SCENE) as PackedScene).instantiate() as MeleeGhost
	var archer := (load(ARCHER_SCENE) as PackedScene).instantiate() as GhostArcher
	var boss := (load(BOSS_SCENE) as PackedScene).instantiate() as BossActor
	for actor in [player, melee, archer, boss]:
		tree.root.add_child(actor)
		_spawned.append(actor)
	assert_equal(player.sprite.offset, Vector2(-48, -88), "player feet use V2 baseline")
	assert_equal(melee.sprite.offset, Vector2(-48, -90), "melee feet use V2 baseline")
	assert_equal(archer.sprite.offset, Vector2(-48, -88), "archer feet use V2 baseline")
	assert_equal(boss.sprite.offset, Vector2(-96, -176), "Boss feet use V2 baseline")
	var arrow := (load(ARROW_SCENE) as PackedScene).instantiate() as GhostArrow
	tree.root.add_child(arrow)
	_spawned.append(arrow)
	assert_true(arrow.uses_v2_texture(), "normal projectile rendering uses the supplied V2 texture")
	assert_false(arrow.get_node("FallbackVisual").visible, "procedural fallback is hidden")


func test_player_maps_idle_run_jump_fall_and_attack() -> void:
	var coordinator := await _launch()
	var player := coordinator.player()
	assert_equal(player.sprite.animation, &"player_idle", "grounded rest selects idle")

	Input.action_press(&"move_right")
	await step_physics(3)
	assert_equal(player.sprite.animation, &"player_run", "movement selects run")
	assert_false(player.sprite.flip_h, "right-facing run is not flipped")
	Input.action_release(&"move_right")
	Input.action_press(&"move_left")
	await step_physics(2)
	assert_true(player.sprite.flip_h, "left-facing run flips the sprite")
	Input.action_release(&"move_left")

	Input.action_press(&"jump")
	await step_physics(2)
	Input.action_release(&"jump")
	assert_equal(player.sprite.animation, &"player_jump", "rising selects jump")
	player.velocity.y = 40.0
	await step_physics(2)
	assert_equal(player.sprite.animation, &"player_fall", "descending selects fall")

	Input.action_press(&"light_attack")
	await step_physics(2)
	Input.action_release(&"light_attack")
	assert_equal(player.sprite.animation, &"player_light_attack_1", "current light action selects attack 1")


func test_player_hitbox_matches_only_authored_active_frames() -> void:
	var coordinator := await _launch()
	var player := coordinator.player()
	Input.action_press(&"light_attack")
	await step_physics(2)
	Input.action_release(&"light_attack")
	var saw_startup := false
	var saw_active := false
	var saw_recovery := false
	for _frame in range(45):
		await step_physics(1)
		if player.sprite.animation != &"player_light_attack_1":
			continue
		var authored_active := player.sprite.frame >= 4 and player.sprite.frame <= 5
		assert_equal(player.attack_hitbox.is_active(), authored_active, "hitbox follows attack frame %d" % player.sprite.frame)
		saw_startup = saw_startup or player.sprite.frame < 4
		saw_active = saw_active or authored_active
		saw_recovery = saw_recovery or player.sprite.frame > 5
	assert_true(saw_startup, "startup frames were observed")
	assert_true(saw_active, "active frames were observed")
	assert_true(saw_recovery, "recovery frames were observed")
	assert_false(player.attack_hitbox.is_active(), "hitbox closes after the animation")


func test_player_hurt_and_death_override_locomotion() -> void:
	var coordinator := await _launch()
	var player := coordinator.player()
	coordinator.debug_damage(20.0)
	await step_physics(1)
	assert_equal(player.sprite.animation, &"player_hurt", "hurt overrides locomotion")
	await step_physics(35)
	coordinator.debug_damage(10000.0)
	await step_physics(1)
	assert_equal(player.sprite.animation, &"player_death", "lethal damage selects death")


func test_melee_and_boss_hitboxes_follow_authored_frames() -> void:
	var target := Node2D.new()
	tree.root.add_child(target)
	_spawned.append(target)
	target.global_position = Vector2(40.0, 0.0)
	var melee := _spawn_enemy(MELEE_SCENE, "res://data/actors/ghost_melee.tres", target)
	var saw_melee_active := false
	for _i in range(60):
		await step_physics(1)
		if melee.sprite.animation == &"melee_ghost_attack":
			var expected := melee.sprite.frame >= 4 and melee.sprite.frame <= 5
			assert_equal(melee.attack_hitbox.is_active(), expected, "melee hitbox follows frame map")
			saw_melee_active = saw_melee_active or expected
	assert_true(saw_melee_active, "melee active frames occurred")

	target.global_position = Vector2(60.0, 0.0)
	var boss := _spawn_enemy(BOSS_SCENE, "res://data/actors/boss_gate_guardian.tres", target)
	var saw_boss_active := false
	for _i in range(70):
		await step_physics(1)
		if boss.sprite.animation == &"gate_warden_attack_1":
			var expected := boss.sprite.frame >= 4 and boss.sprite.frame <= 5
			assert_equal(boss.attack_hitbox.is_active(), expected, "Boss hitbox follows frame map")
			saw_boss_active = saw_boss_active or expected
	assert_true(saw_boss_active, "Boss active frames occurred")


func test_debug_collision_overlay_is_off_by_default_and_still_toggles() -> void:
	await _launch()
	var overlay := _main.get_node("DebugRoot/DebugShapes") as DebugShapeOverlay
	assert_false(overlay.is_enabled(), "debug shapes start disabled")
	assert_false(overlay.visible, "no collision geometry appears in normal play")
	overlay.toggle()
	assert_true(overlay.is_enabled(), "existing debug toggle still enables shapes")
	assert_true(overlay.visible, "enabled overlay becomes visible")
