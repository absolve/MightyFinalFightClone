extends PlayerState
class_name HurtState
## 受击状态：播放 hurt 动画，短暂无敌与硬直，结束后回到待机。

const HURT_TIME: float = 0.4

var hurtTimer: float = 0.0

func enter(previousStatePath: String, data: Dictionary = {}) -> void:
	hurtTimer = 0.0
	obj.vec = Vector2.ZERO
	obj.invincible = true
	obj.playAnim("hurt")


func physics_update(delta: float) -> void:
	hurtTimer += delta
	if hurtTimer >= HURT_TIME:
		stateMachineNode.transition_to("idleState")


func exit() -> void:
	obj.invincible = false
