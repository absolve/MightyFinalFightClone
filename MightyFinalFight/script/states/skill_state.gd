extends PlayerState
class_name SkillState
## 必杀状态：播放搓招命中的必杀动画（攻击框由方法轨道开关），结束后回到待机。

var skillName: StringName = &""
var currentAnim: StringName = &""

func enter(previousStatePath: String, data: Dictionary = {}) -> void:
	skillName = data.get("skill", &"skill1")
	obj.vec = Vector2.ZERO
	# 必杀映射到的片段缺失时退回默认必杀片段，避免空播放
	var anim: StringName = obj.skillAnims.get(skillName, &"act4")
	currentAnim = anim if obj.hasAnim(anim) else &"act4"
	obj.playAnim(currentAnim)


func exit() -> void:
	obj.setHitBoxEnabled(false)


func onAnimationFinished(animName: StringName) -> void:
	if stateMachineNode.currState != self:
		return
	if animName == currentAnim:
		stateMachineNode.transition_to("idleState")
