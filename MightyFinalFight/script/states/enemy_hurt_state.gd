extends State
class_name EnemyHurtState
## 敌人受击：短硬直 + 水平击退，结束回待机。玩家版 HurtState 继承 PlayerState，
## 敌人不套用玩家专属层，所以这里单独一份。

const HURT_TIME: float = 0.35
const KNOCKBACK_SPEED: float = 180.0
const KNOCKBACK_DECAY: float = 1200.0

## 硬直结束后回到的状态节点名：杂兵回待机，Boss 场景改回接近
@export var returnStatePath: NodePath = NodePath("idleState")

var elapsed: float = 0.0
var pushDir: int = 0
var pushSpeed: float = 0.0


func enter(_previousStatePath: String, data: Dictionary = {}) -> void:
	elapsed = 0.0
	pushDir = data.get("pushDir", 0)
	pushSpeed = KNOCKBACK_SPEED if pushDir != 0 else 0.0
	obj.setFaceDir(-pushDir)
	obj.vec = Vector2.ZERO
	obj.invincible = true
	obj.playAnim(&"hurt")


func physics_update(delta: float) -> void:
	elapsed += delta
	if pushSpeed > 0.0:
		pushSpeed = maxf(pushSpeed - KNOCKBACK_DECAY * delta, 0.0)
		obj.vec = Vector2(pushDir * pushSpeed, 0.0)
		obj.moveSelf()
		obj.clampToBounds()
	if elapsed >= HURT_TIME:
		stateMachineNode.transition_to(String(returnStatePath))


func exit() -> void:
	obj.vec = Vector2.ZERO
	obj.invincible = false
