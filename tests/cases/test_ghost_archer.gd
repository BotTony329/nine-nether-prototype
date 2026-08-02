extends TestCase
## X02: Ghost Archer spacing, shot timing, projectile contract and death safety.

const ARCHER_SCENE := "res://actors/enemies/ghost_archer.tscn"
const ARCHER_CONFIG := "res://data/actors/ghost_archer.tres"
const ARROW_SCENE := "res://actors/enemies/ghost_arrow.tscn"


class MockDamageable:
	extends Node2D
	var hp: float = 100.0
	var defence: float = 0.0
	var hits: int = 0

	func actor_id() -> StringName:
		return &"mock_target"

	func armour() -> float:
		return defence

	func current_hp() -> float:
		return hp

	func receive_damage(context: DamageContext) -> DamageResult:
		var result := GameData.combat.resolve(context)
		hp = maxf(0.0, hp - result.final_damage)
		hits += 1
		return result


var _spawned: Array[Node] = []


func after_each() -> void:
	for node in _spawned:
		if is_instance_valid(node):
			node.queue_free()
	_spawned.clear()


func _track(node: Node) -> Node:
	tree.root.add_child(node)
	_spawned.append(node)
	return node


func _target(position: Vector2, with_hurtbox: bool = false) -> MockDamageable:
	var target := MockDamageable.new()
	_track(target)
	target.global_position = position
	if with_hurtbox:
		var hurtbox := Hurtbox.new()
		hurtbox.collision_layer = 8
		hurtbox.collision_mask = 0
		target.add_child(hurtbox)
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 8.0
		shape.shape = circle
		hurtbox.add_child(shape)
	return target


func _spawn_archer(target: Node2D = null) -> GhostArcher:
	var archer := (load(ARCHER_SCENE) as PackedScene).instantiate() as GhostArcher
	_track(archer)
	var enemy_config := (load(ARCHER_CONFIG) as EnemyConfig).duplicate(true) as EnemyConfig
	# Actor tests have no arena floor; removing gravity isolates horizontal AI.
	enemy_config.gravity = 0.0
	archer.initialize(enemy_config, target)
	return archer


func _spawn_arrow(
	owner_actor: Node,
	direction: Vector2,
	lifetime: float,
	position: Vector2 = Vector2.ZERO
) -> GhostArrow:
	var arrow := (load(ARROW_SCENE) as PackedScene).instantiate() as GhostArrow
	arrow.configure(&"ghost_archer", owner_actor, direction, 12.0, 1.0, 240.0, lifetime)
	_track(arrow)
	arrow.global_position = position
	return arrow


func _blow(target: EnemyBase, amount: float) -> DamageContext:
	var context := DamageContext.new()
	context.source_id = &"test"
	context.target_id = target.actor_id()
	context.base_damage = amount
	context.crit_allowed = false
	context.target_armour = target.armour()
	context.target_current_hp = target.current_hp()
	return context


func test_archer_patrols_then_detects_the_player() -> void:
	var target := _target(Vector2(400.0, 0.0))
	var archer := _spawn_archer(target)
	var start_x := archer.global_position.x
	await step_physics(4)
	assert_equal(archer.state(), EnemyBase.State.IDLE, "outside detection range stays in patrol")
	assert_greater(archer.global_position.x, start_x, "idle patrol moves within its route")

	target.global_position = Vector2(180.0, 0.0)
	await step_physics(2)
	assert_equal(archer.state(), EnemyBase.State.CHASE, "the player is detected")


func test_archer_retreats_when_the_player_is_close() -> void:
	var target := _target(Vector2(40.0, 0.0))
	var archer := _spawn_archer(target)
	await step_physics(3)
	assert_less(archer.velocity.x, 0.0, "an archer left of a close player retreats left")
	assert_equal(archer.state(), EnemyBase.State.CHASE, "retreat is spacing, not a new framework state")


func test_archer_aims_shoots_and_respects_cooldown() -> void:
	var target := _target(Vector2(150.0, 0.0))
	var archer := _spawn_archer(target)
	var shots := [0]
	var release_frames := []
	archer.arrow_fired.connect(func(_arrow: GhostArrow) -> void:
		shots[0] += 1
		release_frames.append(archer.sprite.frame)
	)

	var saw_aim := false
	for _i in range(20):
		await step_physics(1)
		saw_aim = saw_aim or archer.state() == EnemyBase.State.WINDUP
	assert_true(saw_aim, "preferred range begins the readable aim")
	await step_physics(45)
	assert_equal(shots[0], 1, "one arrow is released after the wind-up")
	if not release_frames.is_empty():
		assert_equal(release_frames[0], 1, "the arrow releases on authored shoot frame 1")

	await step_physics(55)
	assert_equal(shots[0], 1, "recovery and cooldown prevent an immediate second shot")
	await step_physics(60)
	assert_greater(shots[0], 1, "the archer may shoot again after cooldown")


func test_arrow_hits_once_through_combat_resolver_and_is_destroyed() -> void:
	var target := _target(Vector2(32.0, 0.0), true)
	target.defence = 20.0
	var arrow := _spawn_arrow(null, Vector2.RIGHT, 1.0)
	await step_physics(16)

	assert_equal(target.hits, 1, "overlap resolves exactly one hit")
	assert_almost(target.hp, 90.0, "12 damage is mitigated by armour through CombatResolver")
	assert_false(is_instance_valid(arrow), "the projectile is destroyed after impact")


func test_arrow_cannot_hit_its_owner() -> void:
	var owner_actor := _target(Vector2.ZERO, true)
	var arrow := _spawn_arrow(owner_actor, Vector2.RIGHT, 1.0, Vector2.ZERO)
	await step_physics(3)
	assert_equal(owner_actor.hits, 0, "owner overlap is ignored")
	assert_false(arrow.has_impacted(), "owner contact does not consume the projectile")


func test_arrow_expires_without_hitting_anything() -> void:
	var arrow := _spawn_arrow(null, Vector2.RIGHT, 0.03)
	await step_physics(5)
	assert_false(is_instance_valid(arrow), "timeout destroys a missed arrow")


func test_archer_takes_damage_dies_and_never_shoots_after_death() -> void:
	var target := _target(Vector2(150.0, 0.0))
	var archer := _spawn_archer(target)
	var shots := [0]
	archer.arrow_fired.connect(func(_arrow: GhostArrow) -> void: shots[0] += 1)
	var result := archer.receive_damage(_blow(archer, 999.0))
	assert_true(result.is_lethal, "lethality is reported by CombatResolver")
	assert_true(archer.is_dead(), "the inherited idempotent death path runs")

	await step_physics(20)
	assert_equal(archer.state(), EnemyBase.State.DEAD, "behaviour remains parked in DEAD")
	assert_equal(shots[0], 0, "a dead archer cannot release a projectile")
