extends PlayerState
class_name AttackState
## 攻击状态：act1→act2→act3 三段连击；下+拳为蹲击（squatAttack，不连段）。
##
## 攻击框由动画方法轨道按命中窗口开关，见 AnimBuilder；
## 动画播放期间再次按拳则递进到下一段（最多 [constant MAX_COMBO] 段）。

const MAX_COMBO: int = 3

var hitCount: int = 1
var isSquat: bool = false
var currentAnim: StringName = &""

func enter(_previousStatePath: String, data: Dictionary = {}) -> void:
	hitCount = data.get("hit", 1)
	isSquat = data.get("squat", false)
	obj.vec = Vector2.ZERO
	currentAnim = "squatAttack" if isSquat else "act%d" % hitCount
	# 清掉发起攻击的那次出拳，连段只认攻击期间新按的拳
	InputRecorder.clearBuffer(obj.playerId)
	obj.playAnim(currentAnim)


func exit() -> void:
	obj.setHitBoxEnabled(false)


func onAnimationFinished(animName: StringName) -> void:
	if stateMachineNode.currState != self:
		return
	if animName != currentAnim:
		return
	if not isSquat:
		# 连段：出招期间再次按拳则递进到下一段
		var buffer: Array[String] = InputRecorder.getBuffer(obj.playerId)
		if buffer.size() > 0 and buffer.back() == "punch" and hitCount < MAX_COMBO:
			InputRecorder.clearBuffer(obj.playerId)
			stateMachineNode.transition_to("attackState", { hit = hitCount + 1 })
			return
	stateMachineNode.transition_to("idleState")
