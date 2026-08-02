class_name Hurtbox
extends Area2D
## Receiving half of a damage exchange. Sits on the damageable actor and points
## back at it, so a Hitbox can find who to hurt without guessing at the scene
## structure.
##
## Physics layer: `player_hurtbox` or `enemy_hurtbox`. Mask stays empty —
## hurtboxes are detected, they do not detect.

## Relative to this node. Defaults to the parent, which is the usual layout.
@export var actor_path: NodePath = ^".."

func actor() -> Node:
	return get_node_or_null(actor_path)
