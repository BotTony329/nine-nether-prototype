class_name ResultScreen
extends CanvasLayer
## End-of-run screen for both outcomes.
##
## It reports and then steps aside: `dismissed` is the only thing it does. Who
## listens decides what happens next — the Ghost Market loop returns to the
## market, and `main.tscn` played standalone restarts in place. The screen has
## no opinion, which is what lets both work without a mode flag.

signal dismissed(result: RunResult)

@onready var _title: Label = $Root/Title
@onready var _summary: Label = $Root/Summary
@onready var _restart_button: Button = $Root/Restart

var _coordinator: RunCoordinator
var _result: RunResult

func bind(coordinator: RunCoordinator) -> void:
	_coordinator = coordinator
	coordinator.run_finished.connect(show_outcome)
	coordinator.state_ready.connect(func(_state: RunState) -> void: visible = false)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_restart_button.pressed.connect(dismiss)

func result() -> RunResult:
	return _result

func show_outcome(result: RunResult) -> void:
	_result = result
	var state := _coordinator.state()
	if not result.is_victory():
		var player := _coordinator.player()
		if (
			player != null
			and player.sprite.animation == &"player_death"
			and player.sprite.is_playing()
		):
			await player.sprite.animation_finished
	# Not 同归: the same-death mechanic is not implemented yet, so a win here is
	# an ordinary victory and the screen must not claim otherwise.
	_title.text = "VICTORY" if result.is_victory() else "DEATH"
	_title.modulate = (
		Color(0.706, 0.392, 0.118) if result.is_victory() else Color(0.831, 0.353, 0.294)
	)
	_summary.text = (
		"Seed  %d\nTime  %s    Kills  %d    Sacrifices  %d\n"
		+ "Attack  %.1f    Estimated DPS  %.1f\n"
		+ "Max lifespan  %.0f    Effective HP  %.0f\n"
		+ "Integrity  %.3f    Imbalance  %.0f\nSoul Ash earned  %d"
	) % [
		state.run_seed(),
		RunResult.format_duration(result.duration_seconds),
		result.kills,
		result.sacrifices,
		state.attack(),
		state.dps_estimate(),
		state.max_hp(),
		state.effective_hp(),
		result.integrity,
		result.imbalance,
		result.soul_ash_earned,
	]
	visible = true
	_restart_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed(&"confirm") or event.is_action_pressed(&"restart_run")):
		dismiss()
		get_viewport().set_input_as_handled()

## Closes the screen and hands control back. Safe to call when already hidden.
func dismiss() -> void:
	if not visible:
		return
	visible = false
	dismissed.emit(_result)
