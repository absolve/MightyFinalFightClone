extends State
class_name BossChargeState
## Boss 冲撞（状态字节 86）：朝锁定方向横穿屏幕，实测 117 帧 / 1.85 px/帧，
## 命中窗口取实测的 31~110 帧（0.52s~1.83s），伤害为攻击 ID 22。

const HIT_FROM: float = 0.52
const HIT_TO: float = 1.83
## 冲撞时长：实测 117 帧
const CHARGE_TIME: float = 1.95

var boss: Boss
var elapsed: float = 0.0
var chargeDir: int = 1


func enter(_previousStatePath: String, _data: Dictionary = {}) -> void:
	boss = obj as Boss
	elapsed = 0.0
	chargeDir = boss.faceDir
	if boss.target != null:
		chargeDir = int(signf(boss.target.global_position.x - obj.global_position.x))
	obj.setFaceDir(chargeDir)
	obj.attack = boss.heavyDamage
	obj.playAnim(&"act1")


func exit() -> void:
	obj.setHitBoxEnabled(false)
	obj.vec = Vector2.ZERO


func physics_update(delta: float) -> void:
	elapsed += delta
	obj.setHitBoxEnabled(elapsed >= HIT_FROM and elapsed < HIT_TO)
	obj.vec = Vector2(boss.chargeSpeed * chargeDir, 0.0)
	obj.moveSelf()
	obj.clampToBounds()
	if elapsed >= CHARGE_TIME:
		stateMachineNode.transition_to("walkState")
