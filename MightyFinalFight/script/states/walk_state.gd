extends PlayerState
class_name WalkState
## 行走状态：四向移动（上下方向按纵深系数减速），受关卡可活动范围限制；
## 可接跳跃与出拳。

func physics_update(_delta: float) -> void:
	var inputDir: Vector2 = obj.getMoveInput()
	if inputDir == Vector2.ZERO:
		stateMachineNode.transition_to("idleState")
		return
	obj.setFaceDir(inputDir.x)
	obj.playAnim("walk")
	obj.moveByInput()


func exit() -> void:
	obj.vec = Vector2.ZERO


func handle_input(_event: InputEvent) -> void:
	if tryJump():
		return
	tryPunchCombo()
