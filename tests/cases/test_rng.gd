extends TestCase
## RNGService determinism and stream isolation.

func _sequence(stream: StringName, count: int) -> Array[float]:
	var values: Array[float] = []
	for _i in range(count):
		values.append(RNGService.randf(stream))
	return values


func test_same_seed_reproduces_the_same_sequence() -> void:
	RNGService.configure(20260802)
	var first := _sequence(RNGService.STREAM_SACRIFICE, 24)
	RNGService.configure(20260802)
	var second := _sequence(RNGService.STREAM_SACRIFICE, 24)
	assert_equal(first, second, "identical seeds produce identical draws")


func test_different_seeds_diverge() -> void:
	RNGService.configure(1)
	var first := _sequence(RNGService.STREAM_SACRIFICE, 8)
	RNGService.configure(2)
	var second := _sequence(RNGService.STREAM_SACRIFICE, 8)
	assert_true(first != second, "a different seed produces a different sequence")


func test_streams_are_independent() -> void:
	# Draining one stream must not shift another: this is what stops an extra
	# loot roll from changing which sacrifices appear.
	RNGService.configure(4242)
	var baseline := _sequence(RNGService.STREAM_SACRIFICE, 6)

	RNGService.configure(4242)
	for _i in range(50):
		RNGService.randf(RNGService.STREAM_COMBAT)
	var after_noise := _sequence(RNGService.STREAM_SACRIFICE, 6)

	assert_equal(after_noise, baseline, "combat draws do not perturb the sacrifice stream")


func test_streams_with_different_names_differ() -> void:
	RNGService.configure(99)
	var sacrifice := _sequence(RNGService.STREAM_SACRIFICE, 6)
	RNGService.configure(99)
	var spawn := _sequence(RNGService.STREAM_SPAWN, 6)
	assert_true(sacrifice != spawn, "stream name is mixed into the derived seed")


func test_randi_range_stays_within_bounds_and_is_reproducible() -> void:
	RNGService.configure(7)
	var first: Array[int] = []
	for _i in range(40):
		var value := RNGService.randi_range(RNGService.STREAM_SPAWN, 3, 9)
		assert_true(value >= 3 and value <= 9, "value %d is inside [3, 9]" % value)
		first.append(value)
	RNGService.configure(7)
	var second: Array[int] = []
	for _i in range(40):
		second.append(RNGService.randi_range(RNGService.STREAM_SPAWN, 3, 9))
	assert_equal(first, second, "integer draws replay identically")
