extends State
class_name PlayerState
## 玩家状态基类：玩家状态共享逻辑的存放处（敌人状态直接继承 [State]）。


# 出拳输入统一入口：优先搓招命中进必杀，其次下+拳进蹲击，否则第一段攻击。
# 按住方向键出拳视为「走打」，一律走普通攻击这条分支——否则边走路边出拳会被
# skill1（方向+拳）截走，普通拳就再也打不出来了；搓招要求先松开方向、原地出拳。
func tryPunchCombo() -> bool:
	if not Input.is_action_just_pressed("%s_punch" % obj.keyMapPrefix):
		return false
	# 起手先转向：按住方向出拳时朝向该方向
	obj.faceInput()
	var matched: ComboDef = null
	if obj.getMoveInput() == Vector2.ZERO:
		matched = ComboMatcher.match(obj.combos, InputRecorder.getBuffer(obj.playerId))
	if matched != null:
		InputRecorder.clearBuffer(obj.playerId)
		stateMachineNode.transition_to("skillState", { skill = matched.skillName })
	elif Input.is_action_pressed("%s_down" % obj.keyMapPrefix):
		stateMachineNode.transition_to("attackState", { hit = 1, squat = true })
	else:
		stateMachineNode.transition_to("attackState", { hit = 1 })
	return true


# 跳跃输入统一入口
func tryJump() -> bool:
	if not Input.is_action_just_pressed("%s_jump" % obj.keyMapPrefix):
		return false
	stateMachineNode.transition_to("jumpState")
	return true
