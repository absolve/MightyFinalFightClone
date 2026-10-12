extends PlayerState
class_name JumpState
## 跳跃状态：起跳给予 zVec 初速度，空中施加重力，允许四向移动；
## 空中按一次拳使出跳攻击，落地回待机。

var airAttacked: bool = false

func enter(previousStatePath: String, data: Dictionary = {}) -> void:
	obj.inAir = true
	obj.zVec = -obj.jumpSpeed
	airAttacked = false
	obj.playAnim("jump")


func physics_update(delta: float) -> void:
	var inputVec: Vector2 = Input.get_vector(
			"%s_left" % obj.keyMapPrefix,
			"%s_right" % obj.keyMapPrefix,
			"%s_up" % obj.keyMapPrefix,
			"%s_down" % obj.keyMapPrefix)
	obj.setFaceDir(inputVec.x)
	obj.vec = inputVec * obj.speed
	obj.moveSelf()
	obj.zVec += obj.gravity * delta
	obj.bodyNode.position.y += obj.zVec * delta
	if obj.bodyNode.position.y >= 0.0:
		obj.bodyNode.position.y = 0.0
		obj.inAir = false
		obj.zVec = 0.0
		stateMachineNode.transition_to("idleState")


func exit() -> void:
	obj.vec = Vector2.ZERO
	obj.setHitBoxEnabled(false)


func handle_input(event: InputEvent) -> void:
	if airAttacked or not Input.is_action_just_pressed("%s_punch" % obj.keyMapPrefix):
		return
	airAttacked = true
	obj.playAnim("jumpAttack")


func onAnimationFinished(animName: StringName) -> void:
	if stateMachineNode.currState != self:
		return
	if animName == "jumpAttack":
		obj.playAnim("jump")
