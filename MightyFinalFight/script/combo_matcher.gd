class_name ComboMatcher
extends RefCounted
## 搓招匹配器：在输入缓冲末尾做严格后缀逐项比较。
##
## 相比旧版字符串子串 find_last，后缀严格匹配保证时序相邻、无歧义；
## 多个命中时长序列优先（避免 →拳 抢掉 →←拳），同长度取 priority 高者。

static func match(combos: Array, buffer: Array[String]) -> ComboDef:
	var best: ComboDef = null
	for comboDef in combos:
		var seq: Array = comboDef.inputs
		if seq.is_empty() or seq.size() > buffer.size():
			continue
		var start: int = buffer.size() - seq.size()
		var matched: bool = true
		for i in seq.size():
			if buffer[start + i] != seq[i]:
				matched = false
				break
		if matched and isBetter(comboDef, best):
			best = comboDef
	return best


static func isBetter(candidate: ComboDef, current: ComboDef) -> bool:
	if current == null:
		return true
	if candidate.inputs.size() > current.inputs.size():
		return true
	return candidate.inputs.size() == current.inputs.size() and candidate.priority > current.priority
