class_name BossActor
extends EnemyBase
## Prototype Boss — 镇关鬼将, the Gate Guardian Ghost General.
##
## Deliberately thin: it is an EnemyBase with boss-scale numbers, its own
## lifecycle events and a health bar. There is no second combat system, no
## second state machine and no phase controller in M1.
##
## Why only one attack: `assets/boss/` ships exactly one attack sheet
## (boss_attack.png, 5 frames). The Prototype Development Pack asks for three
## moves and two phases, and the M1 brief gates the second move on the art
## supporting it. It does not, so the charge and the ground slam are left to
## Codex X04 rather than faked by replaying the run cycle. See
## docs/AI_HANDOFF.md, "Asset integration gaps".
##
## Extension point for X04: add moves as EnemyConfig-driven AttackDefinitions
## selected by an AttackScheduler here. Do not modify EnemyBase or
## CombatResolver to do it.

signal defeated(boss: BossActor)

func start_encounter() -> void:
	EventBus.boss_started.emit(
		EventBus.context({"actor_id": actor_id(), "max_hp": max_hp()})
	)

func _publish_death(source_id: StringName) -> void:
	EventBus.boss_died.emit(
		EventBus.context({"actor_id": actor_id(), "source_id": source_id})
	)
	defeated.emit(self)
