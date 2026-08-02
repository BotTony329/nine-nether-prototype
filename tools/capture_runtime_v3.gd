extends Node
## Captures the real M2 application path for runtime Art V3 evidence.
##
## Usage:
##   godot --path . res://tools/capture_runtime_v3.tscn -- market
##   godot --path . res://tools/capture_runtime_v3.tscn -- combat
##   godot --path . res://tools/capture_runtime_v3.tscn -- boss

const APP := preload("res://scenes/app.tscn")
const CAPTURE_SAVE := "user://runtime_art_capture_meta.json"

var _save := MetaSave.new(CAPTURE_SAVE)


func _ready() -> void:
	_save.reset()
	var app := APP.instantiate() as App
	app.use_save(_save)
	add_child(app)
	await _frames(12)

	var kind := "market"
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		kind = args[0]

	if kind != "market":
		app.start_run()
		await _frames(12)
		var coordinator := app.run().coordinator()
		var player := coordinator.player()
		player.global_position = Vector2(330.0, 304.0)
		if kind == "boss":
			for enemy: EnemyBase in coordinator.live_enemies():
				enemy.queue_free()
			await _frames(2)
			coordinator.begin_boss()
			await _frames(4)
			coordinator.boss().global_position = Vector2(430.0, 304.0)
			coordinator.boss().acquire_target(null)
		else:
			var enemies := coordinator.live_enemies()
			for index in enemies.size():
				if index == 0:
					enemies[index].global_position = Vector2(410.0, 304.0)
					enemies[index].acquire_target(null)
				else:
					enemies[index].queue_free()
		await _frames(20)

	var output := "res://docs/screenshots/runtime_%s_v3.png" % kind
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(output)
	_save.reset()
	if error != OK:
		push_error("Could not write %s: %s" % [output, error_string(error)])
		get_tree().quit(1)
		return
	print("Wrote %s" % output)
	get_tree().quit()


func _frames(count: int) -> void:
	for _frame in count:
		await get_tree().process_frame
