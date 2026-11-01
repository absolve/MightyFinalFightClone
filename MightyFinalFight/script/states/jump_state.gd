extends PlayerState
class_name JumpState
## 跳跃状态：起跳给予 zVec 初速度，空中受重力并可按 airControlFactor 修正方向；
## 起跳时按住方向 = 翻滚跳（jumpRoll 全程），未按方向 = 普通跳（上升 jump、下落 fall）；
## 空中可出一次攻击（拳=jumpAttack，下+拳=jumpKick），
## 攻击动画结束回到对应空中片段，落地回待机。

const ASCEND_ANIM: StringName = &"jump"
const DESCEND_ANIM: StringName = &"fall"
## 按住方向起跳才是翻滚跳（原作如此），未按方向是直上直下的普通跳
const ROLL_ANIM: StringName = &"jumpRoll"
const AIR_ATTACK_ANIM: StringName = &"jumpAttack"
const AIR_KICK_ANIM: StringName = &"jumpKick"

# 每次跳跃只允许一次空中攻击
var airAttacked: bool = false
var airAttackPlaying: bool = false
var descending: bool = false
var rolling: bool = false
var airAttackAnim: StringName = &""

func enter(previousStatePath: String, data: Dictionary = {}) -> void:
	obj.startJump()
	airAttacked = false
	airAttackPlaying = false
	descending = false
	rolling = obj.getMoveInput() != Vector2.ZERO
	airAttackAnim = &""
	# 保留起跳瞬间的方向速度，跑动起跳不会立刻刹停
	obj.vec = obj.velocityFromInput(obj.getMoveInput())
	obj.playAnim(airAnim())


# 空中常态片段：翻滚跳全程用翻滚；普通跳上升 jump、下落 fall。素材缺失时退回 jump
func airAnim() -> StringName:
	if rolling and obj.hasAnim(ROLL_ANIM):
		return ROLL_ANIM
	return flyAnim()


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
			obj.playAnim(airAnim())
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
	obj.attack = (obj as Player).airAttackDamage
	obj.faceInput()
	# 空中按 下+拳 为跳踢，否则为跳拳；素材缺失时退回跳拳
	var wantKick: bool = Input.is_action_pressed("%s_down" % obj.keyMapPrefix)
	airAttackAnim = AIR_KICK_ANIM if wantKick and obj.hasAnim(AIR_KICK_ANIM) \
			else AIR_ATTACK_ANIM
	obj.playAnim(airAttackAnim)


func onAnimationFinished(animName: StringName) -> void:
	if stateMachineNode.currState != self:
		return
	# 空中攻击放完，回到当前空中片段继续飞行动画
	if animName == airAttackAnim:
		airAttackPlaying = false
		obj.playAnim(airAnim())
