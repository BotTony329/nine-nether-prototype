class_name BalanceConfig
extends Resource
## Every tunable number in the prototype. Scripts read from here; they must not
## hardcode balance values.
##
## Baselines come from the research report "残躯换锋 · 2D 动作肉鸽核心机制深度研究报告"
## (Appendix A parameter table, sections 5.1–5.7) via the Prototype Development
## Pack. The shipped instance is res://data/balance_config.tres.

@export_group("Player baseline")
## Section 5.1. `hp_0`, `st_0`, `arm_0`, `sr_0` in the integrity formula.
@export var base_max_hp: float = 100.0
@export var base_max_stamina: float = 100.0
@export var base_armour: float = 10.0
@export var base_stamina_recovery: float = 12.0
@export var base_attack: float = 10.0
@export var base_crit_rate: float = 0.05
@export var base_crit_damage: float = 1.5
@export var base_attack_speed: float = 1.0

@export_group("Structural floors")
## Section 5.7. Sacrifices may not push a structural stat below these.
@export var min_max_hp: float = 10.0
@export var min_max_stamina: float = 15.0
@export var min_armour: float = 0.0

@export_group("Soft and hard caps")
## Section 5.7. Crit rate is a hard cap; the rest compress past the knee.
@export var crit_rate_hard_cap: float = 0.80
@export var crit_damage_soft_cap: float = 4.5
@export var crit_damage_soft_slope: float = 0.35
@export var attack_speed_soft_cap: float = 2.4
@export var attack_speed_soft_slope: float = 0.35
@export var more_product_soft_cap: float = 12.0
@export var more_product_soft_slope: float = 0.30

@export_group("Integrity weights")
## Section 5.4: I = clamp(0.34h + 0.24s + 0.16a + 0.14r + 0.12f, 0, 1)
@export var integrity_weight_hp: float = 0.34
@export var integrity_weight_stamina: float = 0.24
@export var integrity_weight_armour: float = 0.16
@export var integrity_weight_recovery: float = 0.14
@export var integrity_weight_freedom: float = 0.12
@export var integrity_major_lock_penalty: float = 0.12
@export var integrity_action_tax_penalty: float = 0.06

@export_group("Sacrifice reward curve")
## Section 5.5: D = (1 - I)^exponent, G = g_S * (base + slope * D) * Q
@export var deficiency_exponent: float = 1.35
@export var reward_base: float = 0.55
@export var reward_slope: float = 1.45
## g_S indexed by strength 1..5; index 0 is unused padding.
@export var strength_gain: PackedFloat32Array = PackedFloat32Array(
	[0.0, 0.12, 0.20, 0.32, 0.48, 0.70]
)
@export var synergy_bonus: float = 0.12
@export var dilution_penalty: float = 0.08
@export var synergy_quality_min: float = 0.85
@export var synergy_quality_max: float = 1.45

@export_group("Sacrifice cost and imbalance")
## Section 5.6: C_res = 100*dh + 80*ds + 60*da + 50*dr; dB = C * (0.75 + 0.05*S)
@export var cost_weight_hp: float = 100.0
@export var cost_weight_stamina: float = 80.0
@export var cost_weight_armour: float = 60.0
@export var cost_weight_recovery: float = 50.0
@export var imbalance_base_factor: float = 0.75
@export var imbalance_strength_factor: float = 0.05
@export var imbalance_max: float = 200.0
## Section 9.3 caps: at most 2 major locks and 3 action taxes in one run.
@export var max_major_locks: int = 2
@export var max_action_taxes: int = 3

@export_group("Health thresholds")
## Section 6.4. `wounded` and `guttering candle` are momentary, not structural.
@export var wounded_threshold: float = 0.30
@export var guttering_threshold: float = 0.15
@export var guttering_more_multiplier: float = 1.20

@export_group("Player movement")
@export var player_move_speed: float = 110.0
@export var player_air_control: float = 0.65
@export var player_jump_velocity: float = -230.0
@export var player_gravity: float = 780.0
@export var player_max_fall_speed: float = 420.0
@export var player_hurt_duration: float = 0.25
@export var player_hurt_knockback: float = 90.0
@export var player_invulnerable_after_hit: float = 0.45

@export_group("Player light attack")
## Light attack costs no stamina (section 6.1) so the player is never fully
## locked out of acting.
@export var light_attack_windup: float = 0.10
@export var light_attack_active: float = 0.12
@export var light_attack_recovery: float = 0.20
@export var light_attack_skill_multiplier: float = 1.0
@export var light_attack_stamina_cost: float = 0.0

@export_group("Stamina")
@export var stamina_recovery_delay: float = 0.10
@export var stamina_exhausted_lock: float = 1.10

@export_group("Run flow")
@export var wave_enemy_count: int = 3
@export var enemy_spawn_interval: float = 0.6

@export_group("Camera")
@export var camera_smoothing_speed: float = 6.0
@export var camera_look_ahead: float = 24.0
