extends State
class_name PlayerState
## 玩家状态基类：玩家状态共享逻辑的存放处（敌人状态直接继承 [State]）。

# 出拳输入统一入口：优先搓招命中进必杀，其次下+拳进蹲击，否则第一段攻击
func tryPunchCombo() -> bool:
	if not Input.is_action_just_pressed("%s_punch" % obj.keyMapPrefix):
		return false
	var matched: ComboDef = ComboMatcher.match(
		obj.combos,
		InputRecorder.getBuffer(obj.playerId))
	if matched != null:
		InputRecorder.clearBuffer(obj.playerId)
		stateMachineNode.transition_to("skillState", { skill = matched.skillName })
	elif Input.is_action_pressed("%s_down" % obj.keyMapPrefix):
		stateMachineNode.transition_to("attackState", { hit = 1, squat = true })
	else:
		stateMachineNode.transition_to("attackState", { hit = 1 })
	return true
