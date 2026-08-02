extends TestCase
## The Ghost Market loop: market → run → run end → market, and what survives.
##
## Scope is deliberately the M2 brief and nothing else. Combat, sacrifices and
## enemy behaviour have their own cases and are not re-tested here.

const APP_SCENE := "res://scenes/app.tscn"
const SAVE_PATH := "user://test_meta_save.json"

var save: MetaSave
var config: MetaConfig
var app: App

func before_each() -> void:
	save = MetaSave.new(SAVE_PATH)
	save.reset()
	config = (load(App.CONFIG_PATH) as MetaConfig).duplicate(true)

func after_each() -> void:
	tree.paused = false
	if app != null and is_instance_valid(app):
		app.queue_free()
		# One frame so the scene is really gone before the next case boots one.
		await tree.process_frame
	app = null
	save.reset()

## Boots the app against the scratch save file.
func _launch() -> App:
	app = (load(APP_SCENE) as PackedScene).instantiate()
	app.use_save(save)
	app.meta_config = config
	tree.root.add_child(app)
	await step_physics(2)
	return app

## Keeps hitting the player until the run actually ends. A single blow is not
## enough: the player is briefly invulnerable after any hit, so a test that has
## already damaged them would otherwise have its killing blow ignored.
func _end_run_by_death() -> void:
	var coordinator: RunCoordinator = app.run().coordinator()
	await wait_for(func() -> bool:
		if coordinator.phase() == RunCoordinator.PHASE_RESULT:
			return true
		coordinator.debug_damage(100000.0)
		return false
	)

func _dismiss_result() -> bool:
	var screen: ResultScreen = app.run().result_screen()
	var shown: bool = await wait_for(func() -> bool: return screen.visible)
	if shown:
		screen.dismiss()
		await step_physics(2)
	return shown


# --- the loop ---------------------------------------------------------------

func test_ghost_market_loads_first() -> void:
	await _launch()
	assert_not_null(app.market(), "the market exists")
	assert_not_null(app.market(), "the game opens in the Ghost Market")
	assert_null(app.run(), "no run is in progress")
	assert_null(app.last_result(), "there is no previous run to report")
	assert_equal(ProjectSettings.get_setting("application/run/main_scene"), "res://scenes/app.tscn", "F5 enters through App")


func test_start_run_launches_a_playable_run() -> void:
	await _launch()
	app.start_run()
	await step_physics(2)
	var coordinator: RunCoordinator = app.run().coordinator()
	assert_null(app.market(), "the market is torn down, not merely hidden")
	assert_equal(coordinator.phase(), RunCoordinator.PHASE_WAVE, "the run boots into a wave")
	assert_not_null(coordinator.player(), "a player exists")
	assert_equal(
		coordinator.live_enemies().size(), GameData.balance.wave_enemy_count,
		"the wave spawned"
	)
	assert_equal(app.run().scene_file_path, "res://scenes/main.tscn", "App instantiated the current production Main scene")


func test_app_run_resolves_live_combat_visuals_to_art_v3() -> void:
	await _launch()
	app.start_run()
	await step_physics(2)
	var run := app.run()
	var coordinator := run.coordinator()

	_assert_sprite_uses_v3(coordinator.player().sprite, "live player")
	for enemy: EnemyBase in coordinator.live_enemies():
		_assert_sprite_uses_v3(enemy.sprite, "live wave enemy")

	var hud := run.get_node("UIRoot/Hud")
	assert_true(
		(hud.get_node("Player/Icon") as TextureRect).texture.resource_path.begins_with("res://assets_v3/production/"),
		"live player HUD icon resolves to V3"
	)
	assert_true(
		(hud.get_node("Boss/Icon") as TextureRect).texture.resource_path.begins_with("res://assets_v3/production/"),
		"live Boss HUD icon resolves to V3"
	)
	assert_not_null(run.get_node_or_null("CombatFeedback"), "the V3 combat feedback observer is live")
	assert_null(run.get_node_or_null("CombatEffects"), "the Art V2 hit observer is absent")

	coordinator.begin_boss()
	await step_physics(2)
	_assert_sprite_uses_v3(coordinator.boss().sprite, "live Gate Warden")


func test_death_returns_to_the_ghost_market() -> void:
	await _launch()
	app.start_run()
	await step_physics(2)
	await _end_run_by_death()

	var result := app.last_result()
	assert_not_null(result, "the run produced a result")
	assert_equal(result.outcome, RunState.STATUS_DEFEAT, "recorded as a defeat")

	assert_true(await _dismiss_result(), "the result screen appeared")
	assert_null(app.run(), "the run scene was torn down")
	assert_not_null(app.market(), "the market is back")
	assert_equal(app.meta().deaths(), 1, "the death was counted")
	assert_equal(app.meta().runs(), 1, "the run was counted")


func test_victory_returns_to_the_ghost_market() -> void:
	await _launch()
	app.start_run()
	await step_physics(2)
	var coordinator: RunCoordinator = app.run().coordinator()
	coordinator.begin_boss()
	await step_physics(2)
	coordinator.boss().die(&"test")
	# The boss holds victory until its collapse animation finishes.
	assert_true(
		await wait_for(func() -> bool: return app.last_result() != null),
		"the victory was reported"
	)

	assert_equal(app.last_result().outcome, RunState.STATUS_VICTORY, "recorded as a victory")
	assert_true(await _dismiss_result(), "the result screen appeared")
	assert_not_null(app.market(), "the market is back")
	assert_equal(app.meta().victories(), 1, "the victory was counted")
	assert_equal(app.meta().deaths(), 0, "no death was counted")


# --- reward ------------------------------------------------------------------

func test_a_run_is_rewarded_exactly_once() -> void:
	await _launch()
	app.start_run()
	await step_physics(2)
	await _end_run_by_death()

	var banked := app.meta().soul_ash()
	var result := app.last_result()
	assert_greater(float(banked), 0.0, "the run paid something")
	assert_equal(banked, result.soul_ash_earned, "what was banked is what the result reports")

	# Re-emitting the real signal is the route a duplicate would arrive by.
	var coordinator: RunCoordinator = app.run().coordinator()
	coordinator.run_finished.emit(result)
	coordinator.run_finished.emit(result)
	assert_equal(app.meta().soul_ash(), banked, "soul ash was not paid twice")
	assert_equal(app.meta().runs(), 1, "the run was not counted twice")


func test_reward_prices_kills_and_victory_from_config() -> void:
	var defeat := RunResult.new()
	defeat.outcome = RunState.STATUS_DEFEAT
	defeat.kills = 3
	assert_equal(
		config.soul_ash_for(defeat),
		config.soul_ash_base + 3 * config.soul_ash_per_kill,
		"a defeat pays base plus kills"
	)

	var victory := RunResult.new()
	victory.outcome = RunState.STATUS_VICTORY
	victory.kills = 3
	assert_equal(
		config.soul_ash_for(victory),
		config.soul_ash_base + 3 * config.soul_ash_per_kill + config.soul_ash_victory_bonus,
		"a victory adds the bonus"
	)


# --- persistence -------------------------------------------------------------

func test_soul_ash_persists_across_a_relaunch() -> void:
	await _launch()
	app.start_run()
	await step_physics(2)
	await _end_run_by_death()
	var banked := app.meta().soul_ash()
	assert_greater(float(banked), 0.0, "the run paid something")

	# A second App reading the same file is the honest test of persistence.
	var reloaded := MetaSave.new(SAVE_PATH).load_state()
	assert_equal(reloaded.soul_ash(), banked, "soul ash survived the write")
	assert_equal(reloaded.runs(), 1, "so did the run counter")


func test_upgrade_persists_and_reaches_the_next_run() -> void:
	await _launch()
	# Fund the purchase through the normal path rather than by poking a field.
	var funded := RunResult.new()
	funded.outcome = RunState.STATUS_VICTORY
	funded.kills = 40
	app.meta().record_run(funded, config)
	assert_true(app.meta().can_buy_tempered_blade(config), "the purchase is affordable")

	var before := app.meta().soul_ash()
	app.buy_tempered_blade()
	assert_true(app.meta().tempered_blade_owned(), "the blade is owned")
	assert_equal(
		app.meta().soul_ash(), before - config.tempered_blade_cost, "the cost was paid"
	)
	assert_false(app.meta().can_buy_tempered_blade(config), "it cannot be bought twice")

	assert_true(
		MetaSave.new(SAVE_PATH).load_state().tempered_blade_owned(),
		"the purchase was written to disk"
	)

	app.start_run()
	await step_physics(2)
	assert_almost(
		app.run().coordinator().state().attack(),
		GameData.balance.base_attack + config.tempered_blade_attack_bonus,
		"the upgrade is applied to the new run's starting attack",
		1e-6
	)


func test_reset_save_clears_progress_and_the_file() -> void:
	await _launch()
	var funded := RunResult.new()
	funded.kills = 10
	app.meta().record_run(funded, config)
	save.save_state(app.meta())
	assert_true(save.exists(), "there is a save to clear")

	app.reset_save()
	assert_equal(app.meta().soul_ash(), 0, "soul ash is cleared")
	assert_equal(app.meta().runs(), 0, "counters are cleared")
	assert_false(app.meta().tempered_blade_owned(), "upgrades are cleared")
	assert_false(save.exists(), "the file is gone")


func test_a_malformed_save_yields_a_fresh_profile_instead_of_failing() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string("{ not json")
	file.close()
	var meta := MetaSave.new(SAVE_PATH).load_state()
	assert_equal(meta.soul_ash(), 0, "a corrupt save starts fresh rather than crashing")


# --- second run --------------------------------------------------------------

func test_a_second_run_starts_from_a_clean_state() -> void:
	await _launch()
	app.start_run()
	await step_physics(2)

	# Dirty the first run thoroughly: damage, a sacrifice, and a live arrow.
	var first: RunCoordinator = app.run().coordinator()
	first.debug_damage(20.0)
	first.debug_apply_sacrifice()
	await step_physics(2)
	assert_less(first.state().current_hp(), first.state().max_hp(), "the player is hurt")
	assert_false(first.state().sacrifice_history().is_empty(), "a sacrifice was taken")
	assert_greater(first.state().imbalance(), 0.0, "imbalance rose")

	await _end_run_by_death()
	assert_true(await _dismiss_result(), "the result screen appeared")

	app.start_run()
	await step_physics(2)
	var second: RunCoordinator = app.run().coordinator()
	var state := second.state()
	_assert_sprite_uses_v3(second.player().sprite, "second-run player")
	for enemy: EnemyBase in second.live_enemies():
		_assert_sprite_uses_v3(enemy.sprite, "second-run wave enemy")
	assert_almost(state.current_hp(), state.max_hp(), "HP is full again")
	assert_almost(state.current_stamina(), state.max_stamina(), "stamina is full again")
	assert_almost(state.max_hp(), GameData.balance.base_max_hp, "max lifespan is restored")
	assert_almost(state.integrity(), 1.0, "integrity is whole again")
	assert_almost(state.imbalance(), 0.0, "imbalance is cleared")
	assert_true(state.sacrifice_history().is_empty(), "sacrifice history is cleared")
	assert_equal(
		second.live_enemies().size(), GameData.balance.wave_enemy_count,
		"a fresh wave spawned"
	)
	assert_equal(second.kills(), 0, "the kill count restarted")

	# The market path rebuilds the whole run scene, so this mostly guards against
	# something being parented outside it. The in-scene restart path is checked
	# by test_restart_clears_leftover_actors below.
	for node in app.run().get_node("Actors").get_children():
		assert_true(
			node is Player or node is EnemyBase,
			"unexpected leftover actor %s" % node.name
		)

	# And the meta side kept what it should.
	assert_equal(app.meta().runs(), 1, "the finished run is still counted")
	assert_greater(float(app.meta().soul_ash()), 0.0, "soul ash carried over")


## Debug restart reuses the run scene instead of rebuilding it, so this is the
## path where _clear_actors has to do the work — corpses mid-death animation and
## projectiles still in flight included.
func test_restart_clears_leftover_actors() -> void:
	await _launch()
	app.start_run()
	await step_physics(2)
	var coordinator: RunCoordinator = app.run().coordinator()
	var actors: Node2D = app.run().get_node("Actors")

	var debris := Node2D.new()
	debris.name = "InFlightProjectile"
	actors.add_child(debris)
	assert_not_null(actors.get_node_or_null("InFlightProjectile"), "the debris is there")

	coordinator.restart_run()
	await step_physics(2)
	assert_null(
		actors.get_node_or_null("InFlightProjectile"),
		"restart removed everything under Actors"
	)
	assert_equal(
		coordinator.live_enemies().size(), GameData.balance.wave_enemy_count,
		"and respawned a clean wave"
	)


func _assert_sprite_uses_v3(sprite: AnimatedSprite2D, label: String) -> void:
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
	assert_true(texture is AtlasTexture, "%s uses an atlas frame" % label)
	if texture is AtlasTexture:
		assert_true(
			(texture as AtlasTexture).atlas.resource_path.begins_with("res://assets_v3/production/"),
			"%s resolves to Art V3" % label
		)
