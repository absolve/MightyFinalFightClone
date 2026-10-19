extends PlayerState
class_name HurtState
## 受击状态：播放 hurt 动画，被击退一小段距离，短暂无敌与硬直，结束后回到待机。
## 空中受击时同样受重力约束，落地不会悬空。

const HURT_TIME: float = 0.4
## 击退初速度与衰减，仅作用于水平方向
const KNOCKBACK_SPEED: float = 220.0
const KNOCKBACK_DECAY: float = 1400.0

var hurtTimer: float = 0.0
var pushDir: int = 0
var pushSpeed: float = 0.0

func enter(previousStatePath: String, data: Dictionary = {}) -> void:
	hurtTimer = 0.0
	pushDir = data.get("pushDir", 0)
	pushSpeed = KNOCKBACK_SPEED if pushDir != 0 else 0.0
	# 转身面向出手者
	obj.setFaceDir(-pushDir)
	obj.vec = Vector2.ZERO
	obj.invincible = true
	obj.playAnim("hurt")


func physics_update(delta: float) -> void:
	hurtTimer += delta
	if pushSpeed > 0.0:
		pushSpeed = maxf(pushSpeed - KNOCKBACK_DECAY * delta, 0.0)
		obj.vec = Vector2(pushDir * pushSpeed, 0.0)
		obj.moveSelf()
		obj.clampToBounds()
	obj.applyGravity(delta)
	if hurtTimer >= HURT_TIME:
		stateMachineNode.transition_to("idleState")


func exit() -> void:
	obj.vec = Vector2.ZERO
	obj.invincible = false
