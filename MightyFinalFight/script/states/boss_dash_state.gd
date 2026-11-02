extends State
class_name BossDashState
## Boss 突进（状态字节 83 起手/突进）：实测 74~79 帧 / 2.2 px/帧，
## 命中窗口取类型 9 的 8~43 帧（0.13s~0.72s），伤害为攻击 ID 7。

const HIT_FROM: float = 0.13
const HIT_TO: float = 0.72
## 突进时长：实测 76 帧
const DASH_TIME: float = 1.27

var boss: Boss
var elapsed: float = 0.0
var dashDir: int = 1


func enter(_previousStatePath: String, _data: Dictionary = {}) -> void:
	boss = obj as Boss
	elapsed = 0.0
	dashDir = boss.faceDir
	if boss.target != null:
		dashDir = int(signf(boss.target.global_position.x - obj.global_position.x))
	obj.setFaceDir(dashDir)
	obj.attack = boss.strikeDamage
	obj.playAnim(&"act1")


func exit() -> void:
	obj.setHitBoxEnabled(false)
	obj.vec = Vector2.ZERO


func physics_update(delta: float) -> void:
	elapsed += delta
	obj.setHitBoxEnabled(elapsed >= HIT_FROM and elapsed < HIT_TO)
	obj.vec = Vector2(boss.dashSpeed * dashDir, 0.0)
	obj.moveSelf()
	obj.clampToBounds()
	if elapsed >= DASH_TIME:
		stateMachineNode.transition_to("walkState")
