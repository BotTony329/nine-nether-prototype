class_name RunCoordinator
extends Node
## Drives one run through its phases and owns the RunState while it lasts.
##
##   BOOT → WAVE → SACRIFICE → BOSS → RESULT → (restart) → WAVE
##
## Everything that mutates the run passes through here: the HUD reads, the
## sacrifice panel asks, the debug panel requests. Keeping the mutations in one
## node is what lets the UI stay an observer.

signal phase_changed(phase: StringName)
signal state_ready(state: RunState)
signal sacrifice_offered(definition: SacrificeDefinition)
signal boss_spawned(boss: BossActor)
signal run_finished(outcome: StringName)

const PHASE_BOOT := &"boot"
const PHASE_WAVE := &"wave"
const PHASE_SACRIFICE := &"sacrifice"
const PHASE_BOSS := &"boss"
const PHASE_RESULT := &"result"

## The single sacrifice offered in M1. Codex X06 replaces this with the
## three-slot generator over the full library; the offer point does not move.
const M1_SACRIFICE_ID := &"severed_lifespan"

@export var player_scene: PackedScene
@export var enemy_scene: PackedScene
@export var boss_scene: PackedScene
@export var enemy_config: EnemyConfig
@export var boss_config: EnemyConfig
@export var arena_path: NodePath
@export var actor_root_path: NodePath

var _arena: Arena
var _actor_root: Node2D
var _state: RunState
var _player: Player
var _boss: BossActor
var _phase: StringName = PHASE_BOOT
var _live_enemies: Array[EnemyBase] = []
var _run_counter: int = 0


## Resolves scene references only. The run is started by Main once every
## observer has bound, so nothing misses the opening `state_ready`.
func _ready() -> void:
	_arena = get_node(arena_path)
	_actor_root = get_node(actor_root_path)


func state() -> RunState:
	return _state

func player() -> Player:
	return _player

func boss() -> BossActor:
	return _boss

func phase() -> StringName:
	return _phase

## Live wave enemies, excluding the Boss. Read by the debug panel and the
## integration test; the coordinator stays the only thing that mutates the list.
func live_enemies() -> Array[EnemyBase]:
	return _live_enemies.duplicate()

func offered_sacrifice() -> SacrificeDefinition:
	return GameData.definition(M1_SACRIFICE_ID)


## Fresh run. Reusing the scene rather than reloading it keeps the seed under
## our control, which is what makes a reported bug replayable.
func start_run(run_seed: int, restarted: bool = false) -> void:
	get_tree().paused = false
	RNGService.configure(run_seed)
	_run_counter += 1
	EventBus.bind_run(_run_counter)

	_clear_actors()
	_state = RunState.create(GameData.balance, run_seed)
	_state.set_run_status(RunState.STATUS_ACTIVE)
	_spawn_player()
	state_ready.emit(_state)

	var payload := EventBus.context({"seed": run_seed})
	if restarted:
		EventBus.run_restarted.emit(payload)
	else:
		EventBus.run_started.emit(payload)

	_begin_wave()


func restart_run(reuse_seed: bool = true) -> void:
	# randi() here generates a *new seed*, not a gameplay roll — gameplay always
	# draws from a named RNGService stream.
	var next_seed: int = _state.run_seed() if (reuse_seed and _state != null) else randi()
	start_run(next_seed, true)


# --- phases -----------------------------------------------------------------

func _set_phase(next: StringName) -> void:
	_phase = next
	EventBus.set_stage(next)
	phase_changed.emit(next)


func _begin_wave() -> void:
	_set_phase(PHASE_WAVE)
	var points := _arena.enemy_spawn_points()
	if points.is_empty():
		push_error("RunCoordinator: arena has no enemy spawn points")
		_begin_sacrifice()
		return
	for index in range(GameData.balance.wave_enemy_count):
		_spawn_enemy(points[index % points.size()].global_position)


func _begin_sacrifice() -> void:
	_set_phase(PHASE_SACRIFICE)
	var definition := offered_sacrifice()
	if definition == null:
		push_error("RunCoordinator: sacrifice %s missing from library" % M1_SACRIFICE_ID)
		begin_boss()
		return
	get_tree().paused = true
	sacrifice_offered.emit(definition)


## Called by the sacrifice panel once the player confirms. The panel showed a
## preview; this runs the same transaction for real.
func confirm_sacrifice(definition: SacrificeDefinition) -> SacrificeResult:
	var result := GameData.sacrifices.apply(_state, definition)
	if not result.ok:
		push_warning("Sacrifice %s rejected: %s" % [definition.id, result.failure_reason])
	get_tree().paused = false
	begin_boss()
	return result


func begin_boss() -> void:
	if _phase == PHASE_BOSS or _phase == PHASE_RESULT:
		return
	_set_phase(PHASE_BOSS)
	_boss = boss_scene.instantiate()
	_actor_root.add_child(_boss)
	_boss.global_position = _arena.boss_spawn.global_position
	_boss.initialize(boss_config, _player)
	_boss.defeated.connect(_on_boss_defeated)
	_boss.start_encounter()
	boss_spawned.emit(_boss)


func _finish_run(outcome: StringName) -> void:
	if _phase == PHASE_RESULT:
		return
	_set_phase(PHASE_RESULT)
	_state.set_run_status(outcome)
	EventBus.run_completed.emit(EventBus.context({"outcome": outcome}))
	run_finished.emit(outcome)


# --- spawning ---------------------------------------------------------------

func _spawn_player() -> void:
	_player = player_scene.instantiate()
	_actor_root.add_child(_player)
	_player.global_position = _arena.player_spawn.global_position
	_player.setup(_state, GameData.balance)
	_player.died.connect(_on_player_died)
	_arena.apply_camera_bounds(_player.camera)
	_player.camera.make_current()


## Also the debug "spawn reference enemy" command, so the debug path exercises
## the same code the wave does.
func spawn_enemy_at(position: Vector2) -> EnemyBase:
	return _spawn_enemy(position)


func _spawn_enemy(position: Vector2) -> EnemyBase:
	var enemy: EnemyBase = enemy_scene.instantiate()
	_actor_root.add_child(enemy)
	enemy.global_position = position
	enemy.initialize(enemy_config, _player)
	enemy.died.connect(_on_enemy_died)
	_live_enemies.append(enemy)
	return enemy


func _clear_actors() -> void:
	_live_enemies.clear()
	_boss = null
	_player = null
	for child in _actor_root.get_children():
		_actor_root.remove_child(child)
		child.queue_free()


# --- reactions --------------------------------------------------------------

func _on_enemy_died(enemy: EnemyBase) -> void:
	_live_enemies.erase(enemy)
	if _phase == PHASE_WAVE and _live_enemies.is_empty():
		_begin_sacrifice()


func _on_boss_defeated(_boss_actor: BossActor) -> void:
	_finish_run(RunState.STATUS_VICTORY)


func _on_player_died() -> void:
	_finish_run(RunState.STATUS_DEFEAT)


# --- debug commands ---------------------------------------------------------
# Routed through the coordinator so the debug panel never touches RunState.

func debug_heal(amount: float) -> void:
	_state.heal(amount)

## Goes through the normal receive_damage path so a debug kill exercises the
## same death handling as a real killing blow.
func debug_damage(amount: float) -> void:
	if _player == null:
		return
	var context := DamageContext.new()
	context.source_id = &"debug"
	context.target_id = Player.ACTOR_ID
	context.base_damage = amount
	context.crit_allowed = false
	context.target_armour = 0.0
	context.target_current_hp = _state.current_hp()
	_player.receive_damage(context)

func debug_spawn_reference_enemy() -> void:
	if _player == null:
		return
	var offset := 90.0 * (1 if _player.facing() >= 0 else -1)
	spawn_enemy_at(_player.global_position + Vector2(offset, 0.0))

func debug_preview_sacrifice() -> SacrificeResult:
	return GameData.sacrifices.preview(_state, offered_sacrifice())

func debug_apply_sacrifice() -> SacrificeResult:
	return GameData.sacrifices.apply(_state, offered_sacrifice())
