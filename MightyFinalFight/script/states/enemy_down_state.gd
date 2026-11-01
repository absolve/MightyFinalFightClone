extends State
class_name EnemyDownState
## 敌人倒下：清空判定、播 down 片段，短暂停留后从场景移除。

const REMOVE_DELAY: float = 0.9

var elapsed: float = 0.0


func enter(_previousStatePath: String, _data: Dictionary = {}) -> void:
	elapsed = 0.0
	obj.vec = Vector2.ZERO
	obj.invincible = true
	obj.setHitBoxEnabled(false)
	obj.playAnim(&"down")


func physics_update(delta: float) -> void:
	elapsed += delta
	# 空中被打死也要落回地面
	obj.applyGravity(delta)
	if elapsed >= REMOVE_DELAY:
		obj.queue_free()
