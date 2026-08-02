class_name Hud
extends CanvasLayer
## Read-only run display.
##
## The HUD holds a reference to RunState but only ever calls getters. It has no
## path to a command and never talks to an actor — if something on screen is
## wrong, the bug is upstream in a service, not here.

const FILL_INSET := 1.0
const BAR_INTERIOR_WIDTH := 94.0

@onready var _hp_fill: ColorRect = $Player/HealthBar/Fill
@onready var _stamina_fill: ColorRect = $Player/StaminaBar/Fill
@onready var _stats: Label = $Player/Stats
@onready var _boss_root: Control = $Boss
@onready var _boss_fill: ColorRect = $Boss/BossBar/Fill
@onready var _boss_name: Label = $Boss/Name
@onready var _phase_label: Label = $Phase

var _state: RunState
var _boss: EnemyBase

func bind(coordinator: RunCoordinator) -> void:
	coordinator.state_ready.connect(_on_state_ready)
	coordinator.boss_spawned.connect(_on_boss_spawned)
	coordinator.phase_changed.connect(_on_phase_changed)
	if coordinator.state() != null:
		_on_state_ready(coordinator.state())

func _ready() -> void:
	_boss_root.visible = false

func _process(_delta: float) -> void:
	if _state == null:
		return
	_set_fill(_hp_fill, _state.hp_ratio())
	_set_fill(_stamina_fill, _state.stamina_ratio())
	_stats.text = (
		"ATK %.1f   DPS %.1f\nEHP %.0f   HP %.0f/%.0f\nIntegrity %.3f   Imbalance %.0f"
		% [
			_state.attack(),
			_state.dps_estimate(),
			_state.effective_hp(),
			_state.current_hp(),
			_state.max_hp(),
			_state.integrity(),
			_state.imbalance(),
		]
	)
	if _boss != null and is_instance_valid(_boss):
		_set_fill(_boss_fill, _boss.hp_ratio())

func _on_state_ready(state: RunState) -> void:
	_state = state
	_boss = null
	_boss_root.visible = false

func _on_boss_spawned(boss: BossActor) -> void:
	_boss = boss
	_boss_name.text = boss.config.display_name
	_boss_root.visible = true

func _on_phase_changed(phase: StringName) -> void:
	_phase_label.text = String(phase).to_upper()

func _set_fill(fill: ColorRect, ratio: float) -> void:
	fill.size.x = BAR_INTERIOR_WIDTH * clampf(ratio, 0.0, 1.0)
	fill.visible = fill.size.x > 0.0
