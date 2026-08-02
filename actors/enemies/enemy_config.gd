class_name EnemyConfig
extends Resource
## Stats and timings for one enemy archetype. Instances live in
## res://data/actors/. No enemy script may hardcode these numbers.
##
## Attack timings are the contract the player reads: a wind-up long enough to
## see is the difference between a fair hit and a cheap one.

@export var actor_id: StringName = &"enemy"
@export var display_name: String = ""

@export_group("Vitals")
@export var max_hp: float = 30.0
@export var armour: float = 0.0

@export_group("Movement")
@export var move_speed: float = 46.0
@export var gravity: float = 780.0
@export var max_fall_speed: float = 420.0

@export_group("Perception")
@export var detection_range: float = 180.0
@export var attack_range: float = 65.0
## Distance at which the enemy stops closing, so it does not stand inside the
## player.
@export var preferred_gap: float = 34.0

@export_group("Attack")
@export var attack_damage: float = 8.0
@export var attack_skill_multiplier: float = 1.0
## Readable telegraph. X01 specifies 0.40 / 0.15 / 0.60.
@export var attack_windup: float = 0.40
@export var attack_active: float = 0.15
@export var attack_recovery: float = 0.60
@export var attack_cooldown: float = 0.35

@export_group("Reactions")
@export var hurt_duration: float = 0.18
@export var death_duration: float = 0.6
## Colour the sprite is tinted during wind-up.
@export var telegraph_tint: Color = Color(1.7, 1.1, 1.0)
