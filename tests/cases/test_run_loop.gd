extends TestCase
## End-to-end: the M1 loop, plus the scene smoke checks.
##
## This case is the one that would notice if the game stopped being playable —
## it drives the real Main scene through wave, sacrifice, boss, victory,
## restart and death.

const MAIN_SCENE := "res://scenes/main.tscn"
const CRITICAL_SCENES := [
	"res://scenes/main.tscn",
	"res://scenes/arena.tscn",
	"res://actors/player/player.tscn",
	"res://actors/enemies/enemy_base.tscn",
	"res://actors/enemies/ghost_melee.tscn",
	"res://actors/enemies/ghost_archer.tscn",
	"res://actors/enemies/ghost_arrow.tscn",
	"res://actors/boss/boss.tscn",
	"res://ui/hud.tscn",
	"res://ui/sacrifice_panel.tscn",
	"res://ui/result_screen.tscn",
	"res://ui/debug_panel.tscn",
]

var _main: Main

func after_each() -> void:
	tree.paused = false
	if _main != null and is_instance_valid(_main):
		_main.queue_free()
	_main = null

func _launch() -> RunCoordinator:
	_main = (load(MAIN_SCENE) as PackedScene).instantiate()
	tree.root.add_child(_main)
	await step_physics(2)
	return _main.coordinator()

func _clear_wave(coordinator: RunCoordinator) -> void:
	for enemy in coordinator.live_enemies():
		enemy.die(&"test")
	await step_physics(2)


func test_critical_scenes_instantiate_without_missing_dependencies() -> void:
	for path in CRITICAL_SCENES:
		var packed: PackedScene = load(path)
		assert_not_null(packed, "%s loads" % path)
		if packed == null:
			continue
		var instance := packed.instantiate()
		assert_not_null(instance, "%s instantiates" % path)
		if instance != null:
			instance.free()


func test_main_scene_boots_into_a_playable_wave() -> void:
	var coordinator := await _launch()
	assert_equal(coordinator.phase(), RunCoordinator.PHASE_WAVE, "boots straight into the wave")
	assert_not_null(coordinator.player(), "a player exists")
	assert_equal(
		coordinator.live_enemies().size(), GameData.balance.wave_enemy_count,
		"the wave spawned the configured number of enemies"
	)
	var state := coordinator.state()
	assert_almost(state.current_hp(), state.max_hp(), "the player starts intact")
	assert_equal(state.run_status(), RunState.STATUS_ACTIVE, "run is active")


func test_player_light_attack_damages_an_enemy_through_the_hitbox() -> void:
	var coordinator := await _launch()
	var player := coordinator.player()
	var enemy := coordinator.live_enemies()[0]
	enemy.acquire_target(null)
	enemy.global_position = player.global_position + Vector2(20.0, 0.0)
	await step_physics(2)
	var before := enemy.current_hp()

	Input.action_press(&"light_attack")
	await step_physics(2)
	Input.action_release(&"light_attack")
	# Long enough to cover wind-up plus the active window.
	await step_physics(30)

	assert_less(enemy.current_hp(), before, "the swing actually connected")


func test_clearing_the_wave_offers_the_sacrifice() -> void:
	var coordinator := await _launch()
	await _clear_wave(coordinator)
	assert_equal(coordinator.phase(), RunCoordinator.PHASE_SACRIFICE, "wave clear offers a choice")
	assert_true(tree.paused, "the run pauses while the player decides")
	assert_not_null(coordinator.offered_sacrifice(), "a card is on offer")


func test_full_loop_reaches_victory_and_restarts() -> void:
	var coordinator := await _launch()
	await _clear_wave(coordinator)

	var before := coordinator.state().snapshot()
	coordinator.confirm_sacrifice(coordinator.offered_sacrifice())
	await step_physics(2)

	assert_false(tree.paused, "confirming resumes the run")
	assert_equal(coordinator.phase(), RunCoordinator.PHASE_BOSS, "the boss follows the sacrifice")
	assert_not_null(coordinator.boss(), "the boss exists")

	var state := coordinator.state()
	assert_less(state.max_hp(), float(before["max_hp"]), "structurally weaker")
	assert_greater(state.dps_estimate(), float(before["dps_estimate"]), "offensively stronger")
	assert_greater(state.imbalance(), float(before["imbalance"]), "imbalance rose")

	coordinator.boss().die(&"test")
	await step_physics(2)
	assert_equal(coordinator.phase(), RunCoordinator.PHASE_RESULT, "the run ends")
	assert_equal(coordinator.state().run_status(), RunState.STATUS_VICTORY, "as a victory")

	coordinator.restart_run()
	await step_physics(2)
	var restarted := coordinator.state()
	assert_equal(coordinator.phase(), RunCoordinator.PHASE_WAVE, "restart returns to the wave")
	assert_almost(restarted.max_hp(), GameData.balance.base_max_hp, "structure is restored")
	assert_true(restarted.sacrifice_history().is_empty(), "the sacrifice history is cleared")
	assert_equal(
		coordinator.live_enemies().size(), GameData.balance.wave_enemy_count,
		"a fresh wave spawned"
	)


func test_player_death_ends_the_run_as_a_defeat() -> void:
	var coordinator := await _launch()
	coordinator.debug_damage(10000.0)
	await step_physics(2)
	assert_false(coordinator.state().is_alive(), "the player is dead")
	assert_equal(coordinator.player().state_id(), PlayerState.DEAD, "player parked in DEAD")
	assert_equal(coordinator.phase(), RunCoordinator.PHASE_RESULT, "the run ended")
	assert_equal(coordinator.state().run_status(), RunState.STATUS_DEFEAT, "as a defeat")


func test_restart_with_the_same_seed_reproduces_the_run_setup() -> void:
	var coordinator := await _launch()
	var seed_before := coordinator.state().run_seed()
	var digest := coordinator.state().snapshot_hash()
	coordinator.restart_run(true)
	await step_physics(2)
	assert_equal(coordinator.state().run_seed(), seed_before, "the seed is reused")
	assert_equal(coordinator.state().snapshot_hash(), digest, "the opening state is identical")


func test_debug_commands_route_through_the_coordinator() -> void:
	var coordinator := await _launch()
	var state := coordinator.state()

	coordinator.debug_damage(20.0)
	await step_physics(2)
	assert_less(state.current_hp(), state.max_hp(), "debug damage landed")

	coordinator.debug_heal(1000.0)
	assert_almost(state.current_hp(), state.max_hp(), "debug heal tops the player up")

	var enemies_before := coordinator.live_enemies().size()
	coordinator.debug_spawn_reference_enemy()
	assert_equal(
		coordinator.live_enemies().size(), enemies_before + 1, "debug spawn added an enemy"
	)
	assert_true(
		coordinator.live_enemies()[-1] is GhostArcher,
		"the injected debug enemy is the Ghost Archer"
	)

	var digest := state.snapshot_hash()
	var preview := coordinator.debug_preview_sacrifice()
	assert_true(preview.ok, "debug preview succeeds")
	assert_equal(state.snapshot_hash(), digest, "debug preview did not mutate the run")

	var applied := coordinator.debug_apply_sacrifice()
	assert_true(applied.ok, "debug apply succeeds")
	assert_true(preview.matches(applied), "the debug preview matched the debug apply")

	coordinator.begin_boss()
	await step_physics(2)
	assert_equal(coordinator.phase(), RunCoordinator.PHASE_BOSS, "debug can start the boss")
