extends Node
## Reproducible Art V3 runtime capture harness.
##
## Usage:
##   godot --path . res://tools/capture_gameplay.tscn -- wave
##   godot --path . res://tools/capture_gameplay.tscn -- boss
##   godot --path . res://tools/capture_gameplay.tscn -- lineup
##   godot --path . res://tools/capture_gameplay.tscn -- combat

const MAIN := preload("res://scenes/main.tscn")


func _ready() -> void:
	var main := MAIN.instantiate() as Main
	add_child(main)
	for _frame in 12:
		await get_tree().process_frame

	var kind := "wave"
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		kind = args[0]
	var coordinator := main.coordinator()
	var capture_delay := 30
	if kind == "combat":
		var player := coordinator.player()
		player.global_position = Vector2(360.0, 304.0)
		var live := coordinator.live_enemies()
		for index in live.size():
			if index == 0:
				live[index].global_position = Vector2(380.0, 304.0)
				live[index].acquire_target(null)
			else:
				live[index].queue_free()
		for _frame in 2:
			await get_tree().physics_frame
		Input.action_press(&"light_attack")
		for _frame in 2:
			await get_tree().physics_frame
		Input.action_release(&"light_attack")
		for _frame in 8:
			await get_tree().physics_frame
		capture_delay = 1
	elif kind == "lineup":
		var player := coordinator.player()
		player.global_position = Vector2(300.0, 304.0)
		player.camera.position.x = 180.0
		main.get_node("Arena/Props/FortressGate").visible = false
		var live := coordinator.live_enemies()
		for index in live.size():
			if index == 0:
				live[index].global_position = Vector2(560.0, 304.0)
				live[index].acquire_target(null)
			else:
				live[index].queue_free()
		var melee := (load("res://actors/enemies/ghost_melee.tscn") as PackedScene).instantiate() as EnemyBase
		main.get_node("Actors").add_child(melee)
		melee.global_position = Vector2(430.0, 304.0)
		melee.initialize(load("res://data/actors/ghost_melee.tres") as EnemyConfig, player)
		melee.acquire_target(null)
		coordinator.begin_boss()
		coordinator.boss().global_position = Vector2(700.0, 304.0)
		coordinator.boss().acquire_target(null)
	elif kind == "boss":
		coordinator.player().global_position = Vector2(650.0, 304.0)
		coordinator.begin_boss()
	else:
		coordinator.player().global_position = Vector2(360.0, 304.0)

	for _frame in capture_delay:
		await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	var output := "res://docs/screenshots/art_v3_%s.png" % kind
	var error := image.save_png(output)
	if error != OK:
		push_error("Could not write %s: %s" % [output, error_string(error)])
		get_tree().quit(1)
		return
	print("Wrote %s" % output)
	get_tree().quit()
