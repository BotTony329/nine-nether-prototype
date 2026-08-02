class_name SacrificeResult
extends RefCounted
## Outcome of a sacrifice transaction. The same object is produced by `preview`
## and by `apply`, which is how the UI can promise that what it showed is what
## happened.

var ok: bool = false
var definition_id: StringName = &""
var failure_reason: String = ""
## Full RunState snapshots either side of the transaction.
var before: Dictionary = {}
var after: Dictionary = {}
## Signed changes for the values the card is required to display.
var deltas: Dictionary = {}
## G from the saturating reward curve.
var gain: float = 0.0
## Cost score C from the resource components.
var cost_score: float = 0.0
var imbalance_delta: float = 0.0
var warnings: Array[String] = []

static func failed(definition_id: StringName, reason: String) -> SacrificeResult:
	var result := SacrificeResult.new()
	result.ok = false
	result.definition_id = definition_id
	result.failure_reason = reason
	return result

## True when two results describe the same transaction. The preview/apply
## equality test uses this.
func matches(other: SacrificeResult, tolerance: float = 0.0001) -> bool:
	if ok != other.ok or definition_id != other.definition_id:
		return false
	if deltas.keys().size() != other.deltas.keys().size():
		return false
	for key in deltas:
		if not other.deltas.has(key):
			return false
		if absf(float(deltas[key]) - float(other.deltas[key])) > tolerance:
			return false
	return absf(gain - other.gain) <= tolerance \
		and absf(imbalance_delta - other.imbalance_delta) <= tolerance

func to_dictionary() -> Dictionary:
	return {
		"ok": ok,
		"definition_id": definition_id,
		"failure_reason": failure_reason,
		"deltas": deltas.duplicate(),
		"gain": gain,
		"cost_score": cost_score,
		"imbalance_delta": imbalance_delta,
		"warnings": warnings.duplicate(),
	}
