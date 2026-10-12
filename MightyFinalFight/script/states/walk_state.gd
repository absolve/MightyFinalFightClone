extends PlayerState
class_name WalkState
## 行走状态：四向移动，播放 walk 动画；可接跳跃与出拳。

func physics_update(delta: float) -> void:
	var inputVec: Vector2 = Input.get_vector(
			"%s_left" % obj.keyMapPrefix,
			"%s_right" % obj.keyMapPrefix,
			"%s_up" % obj.keyMapPrefix,
			"%s_down" % obj.keyMapPrefix)
	if inputVec == Vector2.ZERO:
		stateMachineNode.transition_to("idleState")
		return
	obj.setFaceDir(inputVec.x)
	obj.vec = inputVec * obj.speed
	obj.playAnim("walk")
	obj.moveSelf()


func exit() -> void:
	obj.vec = Vector2.ZERO


func handle_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("%s_jump" % obj.keyMapPrefix):
		stateMachineNode.transition_to("jumpState")
		return
	tryPunchCombo()
