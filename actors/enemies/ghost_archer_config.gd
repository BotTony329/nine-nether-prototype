class_name GhostArcherConfig
extends Resource
## Data-only spacing and projectile values for the concrete Ghost Archer.
## Base vitals and shared attack timings remain in EnemyConfig.

@export_group("Spacing")
@export var patrol_radius: float
@export var patrol_speed_multiplier: float
@export var preferred_distance: float
@export var retreat_distance: float

@export_group("Projectile")
@export var projectile_scene: PackedScene
@export var projectile_speed: float
@export var projectile_lifetime: float
@export var projectile_spawn_offset: Vector2
