extends Node
## Autoloaded as `GameData`. Owns the balance configuration, the stateless core
## services built from it, and the sacrifice library loaded from disk.
##
## It deliberately does NOT own the active RunState: that belongs to
## RunCoordinator, which hands it to the systems that need it. Keeping mutable
## run data out of an autoload is what stops "just read it from the global"
## becoming the way every script talks to the run.

const BALANCE_PATH := "res://data/balance_config.tres"
const SACRIFICE_DIR := "res://data/sacrifices"

var balance: BalanceConfig
var combat: CombatResolver
var sacrifices: SacrificeService

var _library: Dictionary = {}

func _ready() -> void:
	var config: BalanceConfig = load(BALANCE_PATH)
	if config == null:
		push_error("GameData: cannot load %s" % BALANCE_PATH)
		config = BalanceConfig.new()
	use_balance(config)
	_load_sacrifice_library()

## Rebuilds the services around a different config. Tests use this to check
## behaviour at other tunings without editing the shipped resource.
func use_balance(config: BalanceConfig) -> void:
	balance = config
	combat = CombatResolver.new(config)
	sacrifices = SacrificeService.new(config)

func definition(id: StringName) -> SacrificeDefinition:
	if not _library.has(id):
		return null
	return _library[id]

func definition_ids() -> Array:
	var ids: Array = _library.keys()
	ids.sort()
	return ids

func all_definitions() -> Array[SacrificeDefinition]:
	var out: Array[SacrificeDefinition] = []
	for id in definition_ids():
		out.append(_library[id])
	return out

func _load_sacrifice_library() -> void:
	_library.clear()
	var dir := DirAccess.open(SACRIFICE_DIR)
	if dir == null:
		push_error("GameData: cannot open %s" % SACRIFICE_DIR)
		return
	for file_name in dir.get_files():
		# Exported builds rename .tres to .tres.remap; load() wants the original.
		var resource_name := file_name.trim_suffix(".remap")
		if not resource_name.ends_with(".tres"):
			continue
		var definition_resource: SacrificeDefinition = load(
			"%s/%s" % [SACRIFICE_DIR, resource_name]
		)
		if definition_resource == null:
			push_error("GameData: %s is not a SacrificeDefinition" % resource_name)
			continue
		if _library.has(definition_resource.id):
			push_error("GameData: duplicate sacrifice id %s" % definition_resource.id)
			continue
		_library[definition_resource.id] = definition_resource
