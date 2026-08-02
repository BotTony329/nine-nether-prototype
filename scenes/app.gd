class_name App
extends Node
## Top-level loop: Ghost Market → run → run end → Ghost Market.
##
## The composition root for everything outside a run. It owns the meta profile
## and the save file, decides which scene is on screen, and is the only place
## the two halves of the game meet. `Main` knows nothing about the market;
## `GhostMarket` knows nothing about combat.
##
## Run-end pipeline (docs/GHOST_MARKET_LOOP.md), identical for death and
## victory because both arrive on the same signal:
##
##   RunCoordinator.run_finished(result)
##     → MetaState.record_run  (prices the run, banks the ash, moves counters)
##     → MetaSave.save_state
##     → result screen dismissed
##     → Ghost Market
##
## Duplicate end requests are ignored: `_run_recorded` is raised on the first
## and lowered only when the next run starts.
##
## Exactly one child scene exists at a time. Hiding the idle one is not an
## option: both scenes present their UI on CanvasLayers, and a CanvasLayer does
## not inherit visibility from a parent Node2D, so a "hidden" market would keep
## drawing over the run.

const MARKET_SCENE := "res://scenes/ghost_market.tscn"
const RUN_SCENE := "res://scenes/main.tscn"
const CONFIG_PATH := "res://data/meta_config.tres"

@export var market_scene: PackedScene
@export var run_scene: PackedScene
@export var meta_config: MetaConfig

var _save: MetaSave
var _meta: MetaState
var _market: GhostMarket
var _run: Main
var _last_result: RunResult
var _run_recorded: bool = false

func _ready() -> void:
	if market_scene == null:
		market_scene = load(MARKET_SCENE)
	if run_scene == null:
		run_scene = load(RUN_SCENE)
	if meta_config == null:
		meta_config = load(CONFIG_PATH)
	if _save == null:
		_save = MetaSave.new()
	_meta = _save.load_state()
	open_market()


## Redirects the profile to another file. Tests call this before the node
## enters the tree so they never touch the player's real save.
func use_save(save: MetaSave) -> void:
	_save = save

func meta() -> MetaState:
	return _meta

func market() -> GhostMarket:
	return _market

func run() -> Main:
	return _run

func last_result() -> RunResult:
	return _last_result


# --- navigation -------------------------------------------------------------

func open_market() -> void:
	_close_run()
	if _market == null:
		_market = market_scene.instantiate()
		_market.start_run_requested.connect(start_run)
		_market.buy_tempered_blade_requested.connect(buy_tempered_blade)
		_market.reset_save_requested.connect(reset_save)
		add_child(_market)
	_market.show_profile(_meta, meta_config, _last_result)


func start_run() -> void:
	if _run != null:
		return
	_run_recorded = false
	_close_market()
	_run = run_scene.instantiate()
	# Assigned before the scene enters the tree, so the coordinator already has
	# the bonus when it builds the run's RunState. autostart is off because the
	# market owns the run's lifecycle: Main's standalone restart-in-place would
	# otherwise fire alongside the return to the market.
	_run.autostart = false
	_run.meta_attack_bonus = _meta.attack_bonus(meta_config)
	add_child(_run)
	_run.coordinator().run_finished.connect(_on_run_finished)
	_run.result_screen().dismissed.connect(_on_result_dismissed)
	_run.coordinator().start_run(RNGService.run_seed())


# --- market commands --------------------------------------------------------

func buy_tempered_blade() -> void:
	if not _meta.buy_tempered_blade(meta_config):
		return
	_save.save_state(_meta)
	_refresh_market()


func reset_save() -> void:
	_meta = _save.reset()
	_last_result = null
	_refresh_market()


func _refresh_market() -> void:
	if _market != null:
		_market.show_profile(_meta, meta_config, _last_result)


# --- run end ----------------------------------------------------------------

## Banks the run immediately rather than on dismissal: a player who quits at the
## result screen should still keep what they earned.
func _on_run_finished(result: RunResult) -> void:
	if _run_recorded:
		return
	_run_recorded = true
	_meta.record_run(result, meta_config)
	_save.save_state(_meta)
	_last_result = result


func _on_result_dismissed(_result: RunResult) -> void:
	open_market()


func _close_run() -> void:
	if _run == null:
		return
	# Unpause first: a run abandoned during the sacrifice panel leaves the tree
	# paused, and the market would come up frozen.
	get_tree().paused = false
	remove_child(_run)
	_run.queue_free()
	_run = null


func _close_market() -> void:
	if _market == null:
		return
	remove_child(_market)
	_market.queue_free()
	_market = null
