class_name GhostMarket
extends Node2D
## The hub between runs. Shows what you have, what the last run earned, the one
## upgrade, and the door out.
##
## It reads MetaState and asks — `buy_tempered_blade` and `reset_save` are
## requests to the owner, not writes. Same rule the HUD follows for RunState,
## for the same reason: one place mutates, everything else observes.
##
## The scenery is decoration only. Nothing here reads it, so replacing the
## placeholder brazier with real market art touches this file not at all.

signal start_run_requested
signal buy_tempered_blade_requested
signal reset_save_requested

@onready var _soul_ash: Label = $Ui/Root/Panel/SoulAsh
@onready var _profile: Label = $Ui/Root/Panel/Profile
@onready var _last_run: Label = $Ui/Root/Panel/LastRun
@onready var _upgrade: Label = $Ui/Root/Panel/Upgrade
@onready var _buy_button: Button = $Ui/Root/Panel/Buy
@onready var _start_button: Button = $Ui/Root/Panel/Start
@onready var _reset_button: Button = $Ui/Root/Panel/Reset

var _meta: MetaState
var _config: MetaConfig

func _ready() -> void:
	_buy_button.pressed.connect(func() -> void: buy_tempered_blade_requested.emit())
	_start_button.pressed.connect(func() -> void: start_run_requested.emit())
	_reset_button.pressed.connect(func() -> void: reset_save_requested.emit())

## Renders a profile. Called again after every purchase, reset and returning
## run, so there is one refresh path and no incremental UI state to drift.
func show_profile(meta: MetaState, config: MetaConfig, last_run: RunResult) -> void:
	_meta = meta
	_config = config
	_soul_ash.text = "Soul Ash   %d" % meta.soul_ash()
	_profile.text = "Runs %d    Victories %d    Deaths %d" % [
		meta.runs(), meta.victories(), meta.deaths()
	]
	_last_run.text = (
		"Last run\n  %s" % last_run.summary() if last_run != null
		else "Last run\n  none yet"
	)
	_upgrade.text = (
		"Tempered Blade — +%.1f starting attack, permanent\n  %s"
		% [
			config.tempered_blade_attack_bonus,
			"OWNED" if meta.tempered_blade_owned() else "Cost %d Soul Ash" % config.tempered_blade_cost,
		]
	)
	_buy_button.disabled = not meta.can_buy_tempered_blade(config)
	_buy_button.text = "Owned" if meta.tempered_blade_owned() else "Buy Tempered Blade"
	_start_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"confirm"):
		start_run_requested.emit()
		get_viewport().set_input_as_handled()
