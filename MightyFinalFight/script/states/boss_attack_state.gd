extends State
class_name BossAttackState
## Boss 移动攻击（状态字节 84 攻击/冲刺）：类型 8 实测 43~73 帧 / 1.0~2.2 px/帧，
## 命中窗口取实测的 33~100 帧，伤害为攻击 ID 23。

const HIT_FROM: float = 0.55
const HIT_TO: float = 1.22
## 移动攻击时长：实测 73 帧
const ATTACK_TIME: float = 1.22

var boss: Boss
var elapsed: float = 0.0


func enter(_previousStatePath: String, _data: Dictionary = {}) -> void:
	boss = obj as Boss
	elapsed = 0.0
	obj.attack = boss.strikeDamage
	obj.playAnim(&"act1")
	if boss.target != null:
		obj.setFaceDir(boss.directionTo(boss.target).x)


func exit() -> void:
	obj.setHitBoxEnabled(false)
	obj.vec = Vector2.ZERO


func physics_update(delta: float) -> void:
	elapsed += delta
	obj.setHitBoxEnabled(elapsed >= HIT_FROM and elapsed < HIT_TO)
	if boss.target != null:
		var dir: Vector2 = boss.directionTo(boss.target)
		obj.vec = Vector2(boss.dashSpeed * dir.x, boss.speed * dir.y * obj.depthSpeedFactor)
		obj.moveSelf()
		obj.clampToBounds()
	if elapsed >= ATTACK_TIME:
		stateMachineNode.transition_to("walkState")
