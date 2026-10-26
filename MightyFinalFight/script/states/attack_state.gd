extends PlayerState
class_name AttackState
## 攻击状态：act1→act2→act3 三段连击；下+拳为蹲击（squatAttack，不连段）。
##
## 攻击框由动画方法轨道按命中窗口开关，见 AnimBuilder；
## 连段不再要求「等当前段播完」：出招期间按下拳会先入缓冲，
## 动画进度超过 CANCEL_RATIO（可取消窗口）后立刻接下一段，手感更接近原作。
## 若该段本来就很短，动画播完时也会补一次连段判定。

const MAX_COMBO: int = 3
## 可取消窗口：动画进度超过该比例即可接下一段
const CANCEL_RATIO: float = 0.55
## 取不到片段长度时的兜底可取消时刻（秒）
const MIN_CANCEL_TIME: float = 0.08

var hitCount: int = 1
var isSquat: bool = false
var currentAnim: StringName = &""
var buffered: bool = false
var elapsed: float = 0.0
var cancelTime: float = MIN_CANCEL_TIME

func enter(_previousStatePath: String, data: Dictionary = {}) -> void:
	hitCount = data.get("hit", 1)
	isSquat = data.get("squat", false)
	buffered = false
	elapsed = 0.0
	obj.vec = Vector2.ZERO
	obj.faceInput()
	# 蹲击片段缺失时退回普通第一段，保证出拳一定有动画与判定
	if isSquat:
		currentAnim = &"squatAttack" if obj.hasAnim(&"squatAttack") else &"act1"
	else:
		currentAnim = "act%d" % hitCount
	# 清掉发起攻击的那次出拳，连段只认攻击期间新按的拳
	InputRecorder.clearBuffer(obj.playerId)
	obj.playAnim(currentAnim)
	cancelTime = maxf(obj.getAnimLength(currentAnim) * CANCEL_RATIO, MIN_CANCEL_TIME)


func exit() -> void:
	obj.setHitBoxEnabled(false)


# 蹲击为单段，第 3 段后不再连段
func canChain() -> bool:
	return not isSquat and hitCount < MAX_COMBO


func physics_update(delta: float) -> void:
	elapsed += delta
	if buffered and elapsed >= cancelTime:
		chain()


func handle_input(event: InputEvent) -> void:
	if not canChain():
		return
	if Input.is_action_just_pressed("%s_punch" % obj.keyMapPrefix):
		buffered = true


func chain() -> void:
	stateMachineNode.transition_to("attackState", { hit = hitCount + 1 })


func onAnimationFinished(animName: StringName) -> void:
	if stateMachineNode.currState != self:
		return
	if animName != currentAnim:
		return
	if buffered and canChain():
		chain()
		return
	stateMachineNode.transition_to("idleState")
