class_name DeathEffect
extends Sprite2D
## Optional overlay that accompanies, but never replaces, an actor's authored
## death animation. The actor owns death timing and removal.

@export var playback_fps: float = 8.0

var _playing: bool = false
var _finished: bool = false
var _elapsed: float = 0.0


func _process(delta: float) -> void:
	var actor := get_parent()
	if actor == null or not actor.has_method("is_dead"):
		return
	if not _playing and not _finished and bool(actor.call("is_dead")):
		_playing = true
		visible = true
		frame = 0
	if not _playing:
		return
	_elapsed += delta
	frame = mini(int(_elapsed * playback_fps), hframes - 1)
	if _elapsed >= float(hframes) / playback_fps:
		_playing = false
		_finished = true
		visible = false
