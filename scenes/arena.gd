class_name Arena
extends Node2D
## One fixed combat arena. No procedural generation in the prototype — the
## point of a fixed space is that two runs with the same seed are comparable.
##
## The arena owns geometry and markers only. It does not spawn anything and
## does not know what a wave is; RunCoordinator asks it where things go.

## World-space bounds the player camera is clamped to.
@export var camera_bounds: Rect2 = Rect2(0.0, 0.0, 1024.0, 360.0)

@onready var player_spawn: Marker2D = $Spawns/PlayerSpawn
@onready var boss_spawn: Marker2D = $Spawns/BossSpawn
@onready var _enemy_spawn_root: Node2D = $Spawns/EnemySpawns

func enemy_spawn_points() -> Array[Marker2D]:
	var points: Array[Marker2D] = []
	for child in _enemy_spawn_root.get_children():
		if child is Marker2D:
			points.append(child)
	return points

func apply_camera_bounds(camera: Camera2D) -> void:
	camera.limit_left = int(camera_bounds.position.x)
	camera.limit_top = int(camera_bounds.position.y)
	camera.limit_right = int(camera_bounds.position.x + camera_bounds.size.x)
	camera.limit_bottom = int(camera_bounds.position.y + camera_bounds.size.y)
