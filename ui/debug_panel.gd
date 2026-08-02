class_name DebugPanel
extends CanvasLayer
## Development-only inspector and command surface.
##
## Every command is a call into RunCoordinator, so debug tooling exercises the
## same code paths as play. Nothing here reaches into RunState, an actor's
## internals, or a private field — a debug button that takes a shortcut is a
## debug button that hides the bug you are hunting.
##
## Keys: F1 panel · F2 heal · F3 damage · F4 spawn enemy · F5 start boss
##       F6 preview sacrifice · F7 apply sacrifice · F8 hitboxes · R restart

const HEAL_AMOUNT := 25.0
const DAMAGE_AMOUNT := 15.0
const GHOST_ARCHER_SCENE := preload("res://actors/enemies/ghost_archer.tscn")
const GHOST_ARCHER_CONFIG := preload("res://data/actors/ghost_archer.tres")

@onready var _panel: Panel = $Root/Panel
@onready var _readout: Label = $Root/Panel/Readout
@onready var _log_label: Label = $Root/Panel/Log

var _coordinator: RunCoordinator
var _overlay: DebugShapeOverlay
var _last_message: String = "F1 toggles this panel."

func bind(coordinator: RunCoordinator, overlay: DebugShapeOverlay) -> void:
	_coordinator = coordinator
	_overlay = overlay

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# The readout starts closed so it cannot sit on top of the sacrifice card;
	# the key hint below it stays visible so F1 is discoverable.
	_panel.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed(&"debug_toggle_panel"):
		_panel.visible = not _panel.visible
	elif event.is_action_pressed(&"debug_heal_player"):
		_coordinator.debug_heal(HEAL_AMOUNT)
		_note("healed %.0f" % HEAL_AMOUNT)
	elif event.is_action_pressed(&"debug_damage_player"):
		_coordinator.debug_damage(DAMAGE_AMOUNT)
		_note("damaged %.0f" % DAMAGE_AMOUNT)
	elif event.is_action_pressed(&"debug_spawn_enemy"):
		spawn_ghost_archer_for_debug()
		_note("spawned Ghost Archer")
	elif event.is_action_pressed(&"debug_start_boss"):
		_coordinator.begin_boss()
		_note("boss encounter started")
	elif event.is_action_pressed(&"debug_preview_sacrifice"):
		_note(_describe(_coordinator.debug_preview_sacrifice(), "preview"))
	elif event.is_action_pressed(&"debug_apply_sacrifice"):
		_note(_describe(_coordinator.debug_apply_sacrifice(), "applied"))
	elif event.is_action_pressed(&"debug_toggle_hitboxes"):
		_overlay.toggle()
		_note("hitboxes %s" % ("on" if _overlay.is_enabled() else "off"))
	elif event.is_action_pressed(&"restart_run"):
		_coordinator.restart_run()
		_note("run restarted")
	else:
		return
	get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if not _panel.visible or _coordinator == null:
		return
	var state := _coordinator.state()
	if state == null:
		return
	var player := _coordinator.player()
	_readout.text = (
		"seed        %d\nphase       %s\nplayer      %s\nstatus      %s\n"
		+ "hp          %.1f / %.1f\nstamina     %.1f / %.1f\n"
		+ "attack      %.2f   add %.2f   more x%.3f\n"
		+ "armour      %.1f   recovery %.1f\n"
		+ "integrity   %.4f\nimbalance   %.1f\nEHP         %.1f\nDPS est.    %.1f\n"
		+ "locks       %d   taxes %d\nsacrifices  %s\nsnapshot    %s"
	) % [
		state.run_seed(),
		_coordinator.phase(),
		player.state_id() if player != null else &"none",
		state.run_status(),
		state.current_hp(), state.max_hp(),
		state.current_stamina(), state.max_stamina(),
		state.attack(), state.additive_sum(), state.more_product(),
		state.armour(), state.stamina_recovery(),
		state.integrity(),
		state.imbalance(),
		state.effective_hp(),
		state.dps_estimate(),
		state.structural_locks().size(), state.action_taxes().size(),
		str(state.sacrifice_history()),
		state.snapshot_hash(),
	]
	_log_label.text = _last_message

func _describe(result: SacrificeResult, verb: String) -> String:
	if not result.ok:
		return "%s failed: %s" % [verb, result.failure_reason]
	return "%s %s: HP %+.1f, DPS %+.1f, I %+.4f, B %+.0f" % [
		verb,
		result.definition_id,
		result.deltas["max_hp"],
		result.deltas["dps_estimate"],
		result.deltas["integrity"],
		result.deltas["imbalance"],
	]

func _note(message: String) -> void:
	_last_message = message
	print("[debug] ", message)


func spawn_ghost_archer_for_debug() -> void:
	# Keep the existing coordinator-owned spawn/list/death path. Its scene and
	# config are injected public composition properties, so the debug command can
	# select X02 without reaching into private coordinator state.
	var previous_scene := _coordinator.enemy_scene
	var previous_config := _coordinator.enemy_config
	_coordinator.enemy_scene = GHOST_ARCHER_SCENE
	_coordinator.enemy_config = GHOST_ARCHER_CONFIG
	_coordinator.debug_spawn_reference_enemy()
	_coordinator.enemy_scene = previous_scene
	_coordinator.enemy_config = previous_config
