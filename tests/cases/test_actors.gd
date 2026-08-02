extends TestCase
## EnemyBase and BossActor: damage intake, idempotent death, and the shared
## Damageable shape.

const ENEMY_SCENE := "res://actors/enemies/ghost_melee.tscn"
const BOSS_SCENE := "res://actors/boss/boss.tscn"
const ENEMY_CONFIG := "res://data/actors/ghost_melee.tres"
const BOSS_CONFIG := "res://data/actors/boss_gate_guardian.tres"

var _spawned: Array[Node] = []

func after_each() -> void:
	for node in _spawned:
		if is_instance_valid(node):
			node.queue_free()
	_spawned.clear()

func _spawn(scene_path: String, config_path: String) -> EnemyBase:
	var enemy: EnemyBase = (load(scene_path) as PackedScene).instantiate()
	tree.root.add_child(enemy)
	_spawned.append(enemy)
	enemy.initialize(load(config_path) as EnemyConfig, null)
	return enemy

func _blow(target: EnemyBase, amount: float) -> DamageContext:
	var context := DamageContext.new()
	context.source_id = &"test"
	context.target_id = target.actor_id()
	context.base_damage = amount
	context.crit_allowed = false
	context.target_armour = target.armour()
	context.target_current_hp = target.current_hp()
	return context


func test_enemy_exposes_the_damageable_shape() -> void:
	var enemy := _spawn(ENEMY_SCENE, ENEMY_CONFIG)
	assert_equal(enemy.actor_id(), &"ghost_melee", "actor_id comes from the config")
	assert_almost(enemy.max_hp(), 34.0, "max HP comes from the config")
	assert_almost(enemy.current_hp(), 34.0, "spawns at full HP")
	assert_almost(enemy.armour(), 4.0, "armour comes from the config")


func test_enemy_takes_damage_through_the_resolver() -> void:
	var enemy := _spawn(ENEMY_SCENE, ENEMY_CONFIG)
	var result := enemy.receive_damage(_blow(enemy, 10.0))
	# Armour 4 mitigates: 10 * 100 / 104
	assert_almost(result.final_damage, 1000.0 / 104.0, "armour applied by CombatResolver", 1e-4)
	assert_almost(enemy.current_hp(), 34.0 - 1000.0 / 104.0, "HP dropped by exactly that", 1e-4)
	assert_false(enemy.is_dead(), "still alive")


func test_death_fires_exactly_once_however_many_lethal_hits_land() -> void:
	var enemy := _spawn(ENEMY_SCENE, ENEMY_CONFIG)
	var signal_count := [0]
	var bus_count := [0]
	enemy.died.connect(func(_e: EnemyBase) -> void: signal_count[0] += 1)
	var bus_handler := func(_payload: Dictionary) -> void: bus_count[0] += 1
	EventBus.enemy_died.connect(bus_handler)

	enemy.receive_damage(_blow(enemy, 1000.0))
	enemy.receive_damage(_blow(enemy, 1000.0))
	enemy.die(&"test")
	enemy.die(&"test")

	EventBus.enemy_died.disconnect(bus_handler)
	assert_equal(signal_count[0], 1, "the died signal fired once")
	assert_equal(bus_count[0], 1, "the enemy_died event fired once")


func test_damage_after_death_is_ignored() -> void:
	var enemy := _spawn(ENEMY_SCENE, ENEMY_CONFIG)
	enemy.die(&"test")
	var result := enemy.receive_damage(_blow(enemy, 50.0))
	assert_almost(result.final_damage, 0.0, "a corpse takes no damage")
	assert_almost(enemy.current_hp(), 0.0, "HP stays at zero")


func test_death_disables_behaviour() -> void:
	var enemy := _spawn(ENEMY_SCENE, ENEMY_CONFIG)
	enemy.die(&"test")
	await step_physics(2)
	assert_equal(enemy.state(), EnemyBase.State.DEAD, "state machine parked in DEAD")
	assert_false(enemy.attack_hitbox.is_active(), "attack box is closed")
	assert_false(enemy.hurtbox.monitorable, "hurtbox no longer registers hits")
	assert_true(enemy.body_shape.disabled, "body collision is off")
	assert_almost(enemy.velocity.x, 0.0, "no residual movement", 1.0)


func test_boss_reuses_the_enemy_foundation() -> void:
	var boss := _spawn(BOSS_SCENE, BOSS_CONFIG) as BossActor
	assert_true(boss is EnemyBase, "BossActor extends EnemyBase — one combat system")
	assert_almost(boss.max_hp(), 260.0, "boss vitals come from its own config")
	boss.receive_damage(_blow(boss, 100.0))
	assert_less(boss.current_hp(), 260.0, "boss takes damage through the same resolver")


func test_boss_death_publishes_its_own_events_once() -> void:
	var boss := _spawn(BOSS_SCENE, BOSS_CONFIG) as BossActor
	var defeated := [0]
	var bus := [0]
	boss.defeated.connect(func(_b: BossActor) -> void: defeated[0] += 1)
	var handler := func(_payload: Dictionary) -> void: bus[0] += 1
	EventBus.boss_died.connect(handler)

	boss.receive_damage(_blow(boss, 9999.0))
	boss.die(&"test")
	assert_equal(defeated[0], 0, "victory waits while the collapse animation plays")
	await step_physics(125)

	EventBus.boss_died.disconnect(handler)
	assert_equal(defeated[0], 1, "defeated fired once")
	assert_equal(bus[0], 1, "boss_died fired once")


func test_enemy_chases_a_target_in_range() -> void:
	var enemy := _spawn(ENEMY_SCENE, ENEMY_CONFIG)
	var target := Node2D.new()
	tree.root.add_child(target)
	_spawned.append(target)
	enemy.global_position = Vector2.ZERO
	target.global_position = Vector2(140.0, 0.0)
	enemy.acquire_target(target)
	await step_physics(4)
	assert_true(
		enemy.state() == EnemyBase.State.CHASE,
		"a target inside the 180px detection range is chased"
	)
