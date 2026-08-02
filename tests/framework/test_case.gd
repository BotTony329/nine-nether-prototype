class_name TestCase
extends RefCounted
## Minimal assertion base for the headless suite.
##
## Why not GUT or gdUnit4: the Prototype Development Pack requires the project
## to run and test straight after clone with no extra downloads (A2). Vendoring
## a plugin for a dozen asserts would cost more than it saves. If the suite
## outgrows this — parameterised cases, fixtures, mocking — swap in a real
## framework rather than growing this file.

var failures: Array[String] = []
var assertions: int = 0
## Injected by the runner. Tests that need real frames await tree.process_frame
## or tree.physics_frame.
var tree: SceneTree

## Test methods are discovered by name: anything starting with `test_`.
func method_names() -> Array[String]:
	var names: Array[String] = []
	for method in get_method_list():
		var method_name: String = method["name"]
		if method_name.begins_with("test_"):
			names.append(method_name)
	names.sort()
	return names

## Per-test setup hook.
func before_each() -> void:
	pass

func after_each() -> void:
	pass

## Advances the engine by `count` physics frames. Only the integration case
## needs this; unit tests should not.
func step_physics(count: int) -> void:
	for _i in range(count):
		await tree.physics_frame

## Steps physics until `condition` returns true, up to `max_frames`. Returns
## whether it became true, so a caller can assert rather than hang.
func wait_for(condition: Callable, max_frames: int = 240) -> bool:
	for _i in range(max_frames):
		if bool(condition.call()):
			return true
		await tree.physics_frame
	return bool(condition.call())

## A BalanceConfig detached from the shipped resource, so a test can retune a
## value without leaking the change into the next test.
func make_balance() -> BalanceConfig:
	return (load(GameData.BALANCE_PATH) as BalanceConfig).duplicate(true)

func fail(message: String) -> void:
	failures.append(message)

func check(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		fail(message)

func assert_true(condition: bool, message: String) -> void:
	check(condition, "expected true — %s" % message)

func assert_false(condition: bool, message: String) -> void:
	check(not condition, "expected false — %s" % message)

func assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	check(actual == expected, "expected %s, got %s — %s" % [expected, actual, message])

func assert_almost(actual: float, expected: float, message: String, tolerance: float = 1e-6) -> void:
	check(
		absf(actual - expected) <= tolerance,
		"expected %.9f, got %.9f (tolerance %.9f) — %s" % [expected, actual, tolerance, message]
	)

func assert_greater(actual: float, threshold: float, message: String) -> void:
	check(actual > threshold, "expected > %.6f, got %.6f — %s" % [threshold, actual, message])

func assert_less(actual: float, threshold: float, message: String) -> void:
	check(actual < threshold, "expected < %.6f, got %.6f — %s" % [threshold, actual, message])

func assert_null(value: Variant, message: String) -> void:
	check(value == null, "expected null, got %s — %s" % [value, message])

func assert_not_null(value: Variant, message: String) -> void:
	check(value != null, "expected non-null — %s" % message)
