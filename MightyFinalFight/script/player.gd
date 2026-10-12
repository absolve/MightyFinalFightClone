extends "res://script/object.gd"
class_name Player
## 玩家基类：在战斗对象基础上接入输入，把本玩家的方向/攻击输入写入 InputRecorder。
##
## Cody/Guy/Haggar 继承本类；敌人直接继承 object.gd，不录入输入。

# 录入搓招缓冲的动作名（不含玩家前缀）
const RECORD_ACTIONS: Array[StringName] = [&"up", &"down", &"left", &"right", &"punch", &"jump"]

func recordInput(event: InputEvent) -> void:
	for actionName in RECORD_ACTIONS:
		if event.is_action_pressed("%s_%s" % [keyMapPrefix, actionName]):
			InputRecorder.record(playerId, actionName)


# 用 _input 而非 _unhandled_input：_input 整树先于 _unhandled_input 一个阶段，
# 保证录入一定发生在状态机派发 handle_input 之前，与节点在树中的位置无关
func _input(event: InputEvent) -> void:
	recordInput(event)
