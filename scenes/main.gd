class_name Main
extends Node2D
## Composition root. Builds the object graph and starts the run.
##
## Wiring lives here rather than inside each node so that every dependency is
## visible in one place, and so no observer can miss the opening `state_ready`
## by binding after the coordinator has already started.

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
	_coordinator.start_run(RNGService.run_seed())

func coordinator() -> RunCoordinator:
	return _coordinator
