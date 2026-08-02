class_name MetaConfig
extends Resource
## Tunables for the meta layer only. Kept apart from BalanceConfig on purpose:
## in-run balance is owned by the combat design and must not be disturbed by
## somebody tuning the shop.
##
## Shipped instance: res://data/meta_config.tres.

@export_group("Soul Ash reward")
## Paid for finishing a run at all, so a bad run still moves the meta forward.
@export var soul_ash_base: int = 5
@export var soul_ash_per_kill: int = 2
@export var soul_ash_victory_bonus: int = 25

@export_group("Tempered Blade")
@export var tempered_blade_cost: int = 40
## Flat starting attack added to every future run once bought.
@export var tempered_blade_attack_bonus: float = 2.0


## Prices a finished run. Pure: same result in, same number out — which is why
## the reward rule can be tested without a save file or a scene.
func soul_ash_for(result: RunResult) -> int:
	var earned := soul_ash_base + soul_ash_per_kill * maxi(0, result.kills)
	if result.is_victory():
		earned += soul_ash_victory_bonus
	return maxi(0, earned)
