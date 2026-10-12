extends PlayerState
class_name IdleState
## 待机状态：无移动输入，播放 default 动画；监听移动/跳跃/出拳输入。

func enter(previousStatePath: String, data: Dictionary = {}) -> void:
	obj.vec = Vector2.ZERO
	obj.playAnim("default")


func physics_update(delta: float) -> void:
	var inputVec: Vector2 = Input.get_vector(
			"%s_left" % obj.keyMapPrefix,
			"%s_right" % obj.keyMapPrefix,
			"%s_up" % obj.keyMapPrefix,
			"%s_down" % obj.keyMapPrefix)
	if inputVec != Vector2.ZERO:
		obj.setFaceDir(inputVec.x)
		stateMachineNode.transition_to("walkState")


func handle_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("%s_jump" % obj.keyMapPrefix):
		stateMachineNode.transition_to("jumpState")
		return
	tryPunchCombo()
