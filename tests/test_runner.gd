extends Node
## Headless test entry point.
##
##     godot --headless --path . res://tests/test_runner.tscn
##
## Runs as a scene rather than via `--script` on purpose: a MainLoop script is
## compiled before the autoload singletons are registered, so any class that
## names EventBus or RNGService fails to compile and the whole graph silently
## degrades to null services. Booting a scene means the run behaves exactly like
## the game does.
##
## Discovers every res://tests/cases/*.gd, runs each `test_*` method on a fresh
## instance, and exits non-zero if any assertion failed.

const CASE_DIR := "res://tests/cases"

var _total: int = 0
var _failed: int = 0
var _assertions: int = 0
var _failed_names: Array[String] = []

func _ready() -> void:
	_run_all()

func _run_all() -> void:
	await get_tree().process_frame

	var script_paths := _discover_cases()
	if script_paths.is_empty():
		push_error("No test cases found in %s" % CASE_DIR)
		get_tree().quit(1)
		return

	for path in script_paths:
		await _run_case(path)

	print("")
	print("──────────────────────────────────────────────")
	print("%d tests, %d assertions, %d failed" % [_total, _assertions, _failed])
	for name in _failed_names:
		print("  failed: %s" % name)
	print("──────────────────────────────────────────────")
	get_tree().quit(1 if _failed > 0 else 0)

func _discover_cases() -> Array[String]:
	var paths: Array[String] = []
	var dir := DirAccess.open(CASE_DIR)
	if dir == null:
		return paths
	for file_name in dir.get_files():
		var script_name := file_name.trim_suffix(".remap")
		if script_name.ends_with(".gd"):
			paths.append("%s/%s" % [CASE_DIR, script_name])
	paths.sort()
	return paths

func _run_case(path: String) -> void:
	var script: GDScript = load(path)
	if script == null:
		push_error("Cannot load test case %s" % path)
		_failed += 1
		return
	print("\n%s" % path.get_file())
	var probe: TestCase = script.new()
	for method_name in probe.method_names():
		var instance: TestCase = script.new()
		instance.tree = get_tree()
		_total += 1
		instance.before_each()
		# Works for both plain and coroutine test methods in Godot 4.
		await instance.call(method_name)
		await instance.after_each()
		_assertions += instance.assertions
		if instance.failures.is_empty():
			print("  ok    %s" % method_name)
		else:
			_failed += 1
			_failed_names.append("%s::%s" % [path.get_file(), method_name])
			print("  FAIL  %s" % method_name)
			for failure in instance.failures:
				print("          %s" % failure)
