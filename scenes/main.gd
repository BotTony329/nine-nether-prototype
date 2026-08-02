class_name Main
extends Node2D
## Composition root for one run. Builds the object graph and starts the run.
##
## Wiring lives here rather than inside each node so that every dependency is
## visible in one place, and so no observer can miss the opening `state_ready`
## by binding after the coordinator has already started.
##
## Two ways in, both real:
##   * `app.tscn` sets `meta_attack_bonus`, leaves `autostart` on, and listens
##     for `run_finished` / `ResultScreen.dismissed` to close the Ghost Market
##     loop.
##   * Pressing F6 on this scene in the editor plays a run with no meta layer,
##     which is how a combat change gets tested without going through the shop.
## Set `autostart = false` to hold the run until the owner calls `start_run`.

@export var autostart: bool = true

## Flat starting attack from meta progression. Assign before the scene enters
## the tree; the coordinator reads it when the run is created.
var meta_attack_bonus: float = 0.0

@onready var _coordinator: RunCoordinator = $RunCoordinator
@onready var _hud: Hud = $UIRoot/Hud
@onready var _sacrifice_panel: SacrificePanel = $UIRoot/SacrificePanel
@onready var _result_screen: ResultScreen = $UIRoot/ResultScreen
@onready var _debug_panel: DebugPanel = $DebugRoot/DebugPanel
@onready var _debug_shapes: DebugShapeOverlay = $DebugRoot/DebugShapes

func _ready() -> void:
	_hud.bind(_coordinator)
	_sacrifice_panel.bind(_coordinator)
	_result_screen.bind(_coordinator)
	_debug_panel.bind(_coordinator, _debug_shapes)
	_coordinator.meta_attack_bonus = meta_attack_bonus
	if autostart:
		# Standalone: there is no Ghost Market to return to, so dismissing the
		# result screen restarts in place.
		_result_screen.dismissed.connect(
			func(_result: RunResult) -> void: _coordinator.restart_run()
		)
		_coordinator.start_run(RNGService.run_seed())

func coordinator() -> RunCoordinator:
	return _coordinator

func result_screen() -> ResultScreen:
	return _result_screen
