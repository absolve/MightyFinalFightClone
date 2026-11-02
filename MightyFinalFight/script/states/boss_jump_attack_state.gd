extends State
class_name BossJumpAttackState
## Boss 跳跃攻击（状态字节 85 跳跃攻击）：实测滞空约 97 帧、跳高 57 px，
## 命中窗口取实测的 15~56 帧（0.25s~0.93s），伤害为攻击 ID 22。
##
## 跳高由场景里的 jumpSpeed 决定：按 gravity=980 换算 57px 需要 jumpSpeed 约 334。

const HIT_FROM: float = 0.25
const HIT_TO: float = 0.93

var boss: Boss
var elapsed: float = 0.0


func enter(_previousStatePath: String, _data: Dictionary = {}) -> void:
	boss = obj as Boss
	elapsed = 0.0
	obj.attack = boss.heavyDamage
	obj.vec = Vector2.ZERO
	obj.startJump()
	obj.playAnim(&"jump")


func exit() -> void:
	obj.setHitBoxEnabled(false)


func physics_update(delta: float) -> void:
	elapsed += delta
	obj.setHitBoxEnabled(elapsed >= HIT_FROM and elapsed < HIT_TO)
	if obj.applyGravity(delta) or elapsed >= boss.jumpAttackTime:
		stateMachineNode.transition_to("walkState")
