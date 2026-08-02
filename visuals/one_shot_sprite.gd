class_name OneShotSprite
extends Sprite2D
## Small self-cleaning frame-strip player for combat feedback only.

var _fps: float = 1.0
var _elapsed: float = 0.0


func configure(source: Texture2D, frame_count: int, fps: float) -> void:
	texture = source
	hframes = frame_count
	_fps = fps
	frame = 0


func _process(delta: float) -> void:
	_elapsed += delta
	frame = mini(int(_elapsed * _fps), hframes - 1)
	if _elapsed >= float(hframes) / _fps:
		queue_free()
