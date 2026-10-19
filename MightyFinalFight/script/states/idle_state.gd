extends PlayerState
class_name IdleState
## 待机状态：无移动输入，播放 default 动画；监听移动/跳跃/出拳输入。
## 若因空中受击硬直结束等原因仍处于浮空，本状态负责把角色落回地面再恢复操作。

func enter(previousStatePath: String, data: Dictionary = {}) -> void:
	obj.vec = Vector2.ZERO
	obj.playAnim(fallAnim() if obj.inAir else &"default")


func fallAnim() -> StringName:
	return &"fall" if obj.hasAnim(&"fall") else &"jump"


func physics_update(delta: float) -> void:
	# 浮空时只受重力，落回地面后才允许移动
	if obj.inAir:
		obj.playAnim(fallAnim())
		obj.applyGravity(delta)
		return
	var inputDir: Vector2 = obj.getMoveInput()
	if inputDir != Vector2.ZERO:
		obj.setFaceDir(inputDir.x)
		stateMachineNode.transition_to("walkState")


func handle_input(event: InputEvent) -> void:
	if obj.inAir:
		return
	if tryJump():
		return
	tryPunchCombo()
