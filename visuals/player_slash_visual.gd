class_name PlayerSlashVisual
extends Sprite2D
## Read-only visual follower for the existing player light attack. It never
## applies damage; the existing Hitbox and CombatResolver remain authoritative.

@export var playback_fps: float = 18.0

var _playing: bool = false
var _elapsed: float = 0.0


func _process(delta: float) -> void:
	var player := get_parent() as Player
	if player == null:
		visible = false
		return
	flip_h = player.facing() < 0
	position.x = absf(position.x) * player.facing()
	if (
		not _playing
		and player.sprite.animation == &"player_light_attack_1"
		and player.sprite.frame == 4
	):
		_playing = true
		_elapsed = 0.0
		frame = 0
		visible = true
	if not _playing:
		return
	_elapsed += delta
	frame = mini(int(_elapsed * playback_fps), hframes - 1)
	if _elapsed >= float(hframes) / playback_fps:
		_playing = false
		visible = false
