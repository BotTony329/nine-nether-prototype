class_name SacrificePanel
extends CanvasLayer
## Sacrifice preview and confirmation.
##
## The panel calls SacrificeService.preview, which runs the real transaction on
## a clone, and renders the numbers that came back. It never computes a benefit
## or a cost itself, and on confirm it hands the definition to RunCoordinator
## rather than applying anything — the rule "UI is an observer" only holds if
## the preview and the apply are the same code, which they are.
##
## Codex X05 replaces this with the A/B/C three-slot card layout. The contract
## it must keep: preview through the service, confirm through the coordinator.

@onready var _title: Label = $Root/Panel/Title
@onready var _body: Label = $Root/Panel/Body
@onready var _warnings: Label = $Root/Panel/Warnings
@onready var _confirm_button: Button = $Root/Panel/Confirm

var _coordinator: RunCoordinator
var _definition: SacrificeDefinition

func bind(coordinator: RunCoordinator) -> void:
	_coordinator = coordinator
	coordinator.sacrifice_offered.connect(show_offer)
	# Visibility follows the phase rather than the confirm button, so the panel
	# also closes when the sacrifice is applied from the debug panel or a test.
	coordinator.phase_changed.connect(_on_phase_changed)

func _ready() -> void:
	# The run is paused while this panel is up, so it must keep processing.
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_confirm_button.pressed.connect(_on_confirmed)

func show_offer(definition: SacrificeDefinition) -> void:
	_definition = definition
	var preview := GameData.sacrifices.preview(_coordinator.state(), definition)
	_title.text = definition.display_name
	_body.text = _format_preview(definition, preview)
	_warnings.text = "\n".join(preview.warnings)
	visible = true
	_confirm_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"confirm"):
		_on_confirmed()
		get_viewport().set_input_as_handled()

func _on_phase_changed(phase: StringName) -> void:
	if phase != RunCoordinator.PHASE_SACRIFICE:
		visible = false


func _on_confirmed() -> void:
	if not visible or _definition == null:
		return
	visible = false
	_coordinator.confirm_sacrifice(_definition)

func _format_preview(definition: SacrificeDefinition, preview: SacrificeResult) -> String:
	if not preview.ok:
		return "Unavailable: %s" % preview.failure_reason
	return (
		"%s\n\nGAIN\n  Attack additive  %+.2f\n  Damage multiplier  x%.3f\n"
		+ "  Estimated DPS  %.1f → %.1f\n\nCOST\n  Max lifespan  %.0f → %.0f\n"
		+ "  Effective HP  %.0f → %.0f\n  Structural integrity  %.3f → %.3f\n"
		+ "  Imbalance  %.0f → %.0f"
	) % [
		definition.short_text,
		definition.reward_additive,
		1.0 + preview.gain,
		preview.before["dps_estimate"], preview.after["dps_estimate"],
		preview.before["max_hp"], preview.after["max_hp"],
		preview.before["effective_hp"], preview.after["effective_hp"],
		preview.before["integrity"], preview.after["integrity"],
		preview.before["imbalance"], preview.after["imbalance"],
	]
