class_name CombatEffects
extends Node2D
## EventBus observer for confirmed damage feedback. No calculation or gameplay
## mutation occurs here; the existing CombatResolver result is already final.

@export var hit_texture: Texture2D
@export var hit_frames: int = 4
@export var hit_fps: float = 16.0


func _ready() -> void:
	z_index = 20
	EventBus.hit_dealt.connect(_on_hit)
	EventBus.hit_taken.connect(_on_hit)


func _on_hit(payload: Dictionary) -> void:
	if float(payload.get("final_damage", 0.0)) <= 0.0 or hit_texture == null:
		return
	var target := _find_actor(StringName(payload.get("target_id", &"unknown")))
	if target == null:
		return
	var effect := OneShotSprite.new()
	effect.configure(hit_texture, hit_frames, hit_fps)
	add_child(effect)
	effect.global_position = target.global_position + Vector2(0.0, -32.0)


func _find_actor(target_id: StringName) -> Node2D:
	var candidates: Array[Node2D] = []
	_collect_actors(get_tree().current_scene, target_id, candidates)
	if candidates.is_empty():
		return null
	if candidates.size() == 1:
		return candidates[0]
	var players: Array[Node2D] = []
	_collect_actors(get_tree().current_scene, &"player", players)
	var player: Node2D = players[0] if not players.is_empty() else null
	if player == null:
		return candidates[0]
	var closest := candidates[0]
	for candidate in candidates:
		if candidate.global_position.distance_squared_to(player.global_position) < closest.global_position.distance_squared_to(player.global_position):
			closest = candidate
	return closest


func _collect_actors(node: Node, target_id: StringName, output: Array[Node2D]) -> void:
	if node == null:
		return
	if node is Node2D and node.has_method("actor_id") and node.call("actor_id") == target_id:
		output.append(node as Node2D)
	for child in node.get_children():
		_collect_actors(child, target_id, output)
