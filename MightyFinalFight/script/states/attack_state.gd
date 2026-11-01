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
## 兜底脱困时长：片段播完却没收到结束信号（贴图缺失/被打断）时，超过它强制回待机
const STALL_GUARD_TIME: float = 0.2

var hitCount: int = 1
var isSquat: bool = false
var currentAnim: StringName = &""
var buffered: bool = false
var hitConfirmed: bool = false
var elapsed: float = 0.0
var cancelTime: float = MIN_CANCEL_TIME

func enter(_previousStatePath: String, data: Dictionary = {}) -> void:
	hitCount = data.get("hit", 1)
	isSquat = data.get("squat", false)
	buffered = false
	hitConfirmed = false
	elapsed = 0.0
	if not obj.hitLanded.is_connected(_onHitLanded):
		obj.hitLanded.connect(_onHitLanded)
	obj.vec = Vector2.ZERO
	obj.faceInput()
	var fighter: Player = obj as Player
	# 蹲击片段缺失时退回普通第一段，保证出拳一定有动画与判定
	if isSquat:
		currentAnim = &"squatAttack" if obj.hasAnim(&"squatAttack") else &"act1"
		obj.attack = fighter.squatDamage
	else:
		currentAnim = "act%d" % hitCount
		obj.attack = fighter.comboDamage[clampi(hitCount - 1, 0, fighter.comboDamage.size() - 1)]
	# 清掉发起攻击的那次出拳，连段只认攻击期间新按的拳
	InputRecorder.clearBuffer(obj.playerId)
	obj.playAnim(currentAnim)
	cancelTime = maxf(obj.getAnimLength(currentAnim) * CANCEL_RATIO, MIN_CANCEL_TIME)


func exit() -> void:
	obj.setHitBoxEnabled(false)
	if obj.hitLanded.is_connected(_onHitLanded):
		obj.hitLanded.disconnect(_onHitLanded)


# 蹲击为单段，第 3 段后不再连段；且必须本段命中过才能接下一段（原作 hit-confirm）
func canChain() -> bool:
	return hitConfirmed and not isSquat and hitCount < MAX_COMBO


func _onHitLanded(_target: FightObject) -> void:
	hitConfirmed = true


func physics_update(delta: float) -> void:
	elapsed += delta
	if buffered and hitConfirmed and elapsed >= cancelTime:
		chain()
		return
	# 兜底：正常播放一定会收到 animation_finished，超过片段长度仍未收到时强制回待机，
	# 避免动画被打断/片段缺失导致永远卡在攻击态、不再响应任何输入
	if elapsed >= cancelTime + STALL_GUARD_TIME:
		stateMachineNode.transition_to("idleState")


func handle_input(event: InputEvent) -> void:
	# 先入缓冲即可：命中确认在接段时再判断，与原作「打到人才能接后续」一致
	if isSquat or hitCount >= MAX_COMBO:
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
