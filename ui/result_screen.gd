class_name ResultScreen
extends CanvasLayer
## End-of-run screen for both outcomes. Restart is requested from the
## coordinator; the screen does not reset anything itself.

@onready var _title: Label = $Root/Title
@onready var _summary: Label = $Root/Summary
@onready var _restart_button: Button = $Root/Restart

var _coordinator: RunCoordinator

func bind(coordinator: RunCoordinator) -> void:
	_coordinator = coordinator
	coordinator.run_finished.connect(show_outcome)
	coordinator.state_ready.connect(func(_state: RunState) -> void: visible = false)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_restart_button.pressed.connect(_on_restart)

func show_outcome(outcome: StringName) -> void:
	var state := _coordinator.state()
	var victory := outcome == RunState.STATUS_VICTORY
	if not victory:
		var player := _coordinator.player()
		if (
			player != null
			and player.sprite.animation == &"player_death"
			and player.sprite.is_playing()
		):
			await player.sprite.animation_finished
	# Not 同归: the same-death mechanic is not implemented in M1, so a win here
	# is an ordinary victory and the screen must not claim otherwise.
	_title.text = "VICTORY" if victory else "DEATH"
	_title.modulate = Color(0.706, 0.392, 0.118) if victory else Color(0.831, 0.353, 0.294)
	_summary.text = (
		"Seed  %d\nSacrifices  %d\nAttack  %.1f    Estimated DPS  %.1f\n"
		+ "Max lifespan  %.0f    Effective HP  %.0f\nIntegrity  %.3f    Imbalance  %.0f"
	) % [
		state.run_seed(),
		state.sacrifice_history().size(),
		state.attack(),
		state.dps_estimate(),
		state.max_hp(),
		state.effective_hp(),
		state.integrity(),
		state.imbalance(),
	]
	visible = true
	_restart_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed(&"confirm") or event.is_action_pressed(&"restart_run")):
		_on_restart()
		get_viewport().set_input_as_handled()

func _on_restart() -> void:
	if not visible:
		return
	visible = false
	_coordinator.restart_run()
