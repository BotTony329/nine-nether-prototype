class_name MetaSave
extends RefCounted
## Reads and writes the meta profile as JSON.
##
## The path is injected so tests write to a scratch file instead of the player's
## real save. That is the whole reason this is an object rather than a set of
## statics: the filesystem is exactly the dependency you want to be able to
## point somewhere else.
##
## Failure policy: a missing, unreadable or malformed save yields a fresh
## profile. Losing progress is bad; refusing to launch is worse.

const DEFAULT_PATH := "user://meta_save.json"
## Bump when the stored shape changes in a way `MetaState.from_dictionary`
## cannot absorb, and add the migration there.
const VERSION := 1

var _path: String

func _init(path: String = DEFAULT_PATH) -> void:
	_path = path

func path() -> String:
	return _path

func exists() -> bool:
	return FileAccess.file_exists(_path)


func load_state() -> MetaState:
	if not FileAccess.file_exists(_path):
		return MetaState.new()
	var file := FileAccess.open(_path, FileAccess.READ)
	if file == null:
		push_warning("MetaSave: cannot read %s (%d) — starting fresh" % [_path, FileAccess.get_open_error()])
		return MetaState.new()
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("MetaSave: %s is not valid JSON — starting fresh" % _path)
		return MetaState.new()
	var payload: Dictionary = parsed
	var stored_version := int(payload.get("version", 0))
	if stored_version > VERSION:
		push_warning(
			"MetaSave: %s was written by version %d, this build reads %d — starting fresh"
			% [_path, stored_version, VERSION]
		)
		return MetaState.new()
	return MetaState.from_dictionary(payload.get("meta", {}))


func save_state(meta: MetaState) -> bool:
	var file := FileAccess.open(_path, FileAccess.WRITE)
	if file == null:
		push_error("MetaSave: cannot write %s (%d)" % [_path, FileAccess.get_open_error()])
		return false
	file.store_string(JSON.stringify({
		"version": VERSION,
		"meta": meta.to_dictionary(),
	}, "\t"))
	file.close()
	return true


## Deletes the file and returns a fresh profile. The caller decides what to do
## with it — this does not reach into anyone's state.
func reset() -> MetaState:
	if FileAccess.file_exists(_path):
		var error := DirAccess.remove_absolute(ProjectSettings.globalize_path(_path))
		if error != OK:
			push_warning("MetaSave: could not delete %s (%d)" % [_path, error])
	return MetaState.new()
