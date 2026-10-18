extends PlayerState
class_name JumpState
## 跳跃状态：起跳给予 zVec 初速度，空中受重力并可按 airControlFactor 修正方向；
## 上升播放 jump、下落播放 fall；空中可出一次攻击（拳=jumpAttack，下+拳=jumpKick），
## 攻击动画结束回到对应飞行动画，落地回待机。

const ASCEND_ANIM: StringName = &"jump"
const DESCEND_ANIM: StringName = &"fall"
const AIR_ATTACK_ANIM: StringName = &"jumpAttack"
const AIR_KICK_ANIM: StringName = &"jumpKick"

# 每次跳跃只允许一次空中攻击
var airAttacked: bool = false
var airAttackPlaying: bool = false
var descending: bool = false
var airAttackAnim: StringName = &""

func enter(previousStatePath: String, data: Dictionary = {}) -> void:
	obj.startJump()
	airAttacked = false
	airAttackPlaying = false
	descending = false
	airAttackAnim = &""
	# 保留起跳瞬间的方向速度，跑动起跳不会立刻刹停
	obj.vec = obj.velocityFromInput(obj.getMoveInput())
	obj.playAnim(flyAnim())


# 上升/下落分别用不同片段，素材缺失时统一退回 jump
func flyAnim() -> StringName:
	var anim: StringName = DESCEND_ANIM if descending else ASCEND_ANIM
	return anim if obj.hasAnim(anim) else ASCEND_ANIM


func physics_update(delta: float) -> void:
	var inputDir: Vector2 = obj.getMoveInput()
	# 空中攻击过程中锁朝向，避免攻击判定框中途翻面
	if not airAttackPlaying:
		obj.setFaceDir(inputDir.x)
	obj.vec = obj.velocityFromInput(inputDir, obj.airControlFactor)
	obj.moveSelf()
	obj.clampToBounds()
	if not descending and obj.zVec >= 0.0:
		descending = true
		if not airAttackPlaying:
			obj.playAnim(flyAnim())
	if obj.applyGravity(delta):
		obj.vec = Vector2.ZERO
		stateMachineNode.transition_to("idleState")


func exit() -> void:
	obj.vec = Vector2.ZERO
	obj.setHitBoxEnabled(false)


func handle_input(event: InputEvent) -> void:
	if airAttacked or not Input.is_action_just_pressed("%s_punch" % obj.keyMapPrefix):
		return
	airAttacked = true
	airAttackPlaying = true
	obj.faceInput()
	# 空中按 下+拳 为跳踢，否则为跳拳；素材缺失时退回跳拳
	var wantKick: bool = Input.is_action_pressed("%s_down" % obj.keyMapPrefix)
	airAttackAnim = AIR_KICK_ANIM if wantKick and obj.hasAnim(AIR_KICK_ANIM) \
			else AIR_ATTACK_ANIM
	obj.playAnim(airAttackAnim)


func onAnimationFinished(animName: StringName) -> void:
	if stateMachineNode.currState != self:
		return
	# 空中攻击放完，回到当前飞行片段继续下落
	if animName == airAttackAnim:
		airAttackPlaying = false
		obj.playAnim(flyAnim())
