extends Node
## Deterministic random number source, autoloaded as `RNGService`.
##
## Each subsystem draws from its own named stream so that an extra roll in one
## system cannot shift the sequence another system observes. Given the same
## `run_seed` and the same per-stream call order, results are reproducible.
##
## Contract (frozen — see docs/INTERFACES.md): never call `randi()`/`randf()`
## directly in gameplay code. Always go through a named stream.

const STREAM_SACRIFICE := &"sacrifice"
const STREAM_COMBAT := &"combat"
const STREAM_SPAWN := &"spawn"

var _run_seed: int = 0
var _streams: Dictionary = {}

func _ready() -> void:
	configure(_generate_seed())

func run_seed() -> int:
	return _run_seed

## Re-seeds every stream. Call once per run, before anything draws.
func configure(new_seed: int) -> void:
	_run_seed = new_seed
	_streams.clear()

## Returns the generator for `stream_name`, creating it on first use.
func stream(stream_name: StringName) -> RandomNumberGenerator:
	var existing: RandomNumberGenerator = _streams.get(stream_name)
	if existing != null:
		return existing
	var rng := RandomNumberGenerator.new()
	rng.seed = _derive_seed(_run_seed, stream_name)
	_streams[stream_name] = rng
	return rng

func randf(stream_name: StringName) -> float:
	return stream(stream_name).randf()

func randi_range(stream_name: StringName, from: int, to: int) -> int:
	return stream(stream_name).randi_range(from, to)

## FNV-1a over the stream name, mixed with the run seed.
##
## Godot's built-in `hash()` is not contractually stable across engine versions,
## and a reproducible seed is the entire point of this service, so the mix is
## spelled out here instead.
func _derive_seed(base_seed: int, stream_name: StringName) -> int:
	# FNV-1a 64-bit offset basis (14695981039346656037) as a signed 64-bit int,
	# because GDScript integers are signed and the unsigned literal will not parse.
	var h: int = -3750763034362895579
	const FNV_PRIME: int = 1099511628211
	for byte in String(stream_name).to_utf8_buffer():
		h = (h ^ byte) * FNV_PRIME
	h = (h ^ base_seed) * FNV_PRIME
	return h

func _generate_seed() -> int:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return rng.randi()
