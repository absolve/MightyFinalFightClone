extends PlayerState
class_name SkillState
## 必杀状态：播放搓招命中的必杀动画（攻击框由方法轨道开关），结束后回到待机。

## 兜底脱困时长：没收到片段结束信号时强制回待机
const STALL_GUARD_TIME: float = 0.2

var skillName: StringName = &""
var currentAnim: StringName = &""
var elapsed: float = 0.0

func enter(previousStatePath: String, data: Dictionary = {}) -> void:
	skillName = data.get("skill", &"skill1")
	# 伤害来自 ComboDef（每段命中都按该值结算）
	obj.attack = int(data.get("damage", obj.attack))
	obj.vec = Vector2.ZERO
	elapsed = 0.0
	# 必杀映射到的片段缺失时退回默认必杀片段，避免空播放
	var anim: StringName = obj.skillAnims.get(skillName, &"act4")
	currentAnim = anim if obj.hasAnim(anim) else &"act4"
	obj.playAnim(currentAnim)


func physics_update(delta: float) -> void:
	elapsed += delta
	# 与 AttackState 同样的兜底：收不到 animation_finished 也要能回到待机
	if elapsed >= obj.getAnimLength(currentAnim) + STALL_GUARD_TIME:
		stateMachineNode.transition_to("idleState")


func exit() -> void:
	obj.setHitBoxEnabled(false)


func onAnimationFinished(animName: StringName) -> void:
	if stateMachineNode.currState != self:
		return
	if animName == currentAnim:
		stateMachineNode.transition_to("idleState")
