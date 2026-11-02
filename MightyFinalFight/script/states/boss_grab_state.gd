extends State
class_name BossGrabState
## Boss 抓取压制（状态字节 82 抓取/压制，原地）：实测 48~63 帧，
## 命中窗口取实测的 5~53 帧（0.08s~0.88s），伤害为攻击 ID 31。
##
## 原作抓取会把玩家举起再摔下，需要投技与玩家受控状态配合；
## 本作先做原地判定，玩家脱离抓取距离就提前结束。

const HIT_FROM: float = 0.08
const HIT_TO: float = 0.88
const GRAB_TIME: float = 1.0
## 抓取距离的该倍数视为玩家已脱身
const ESCAPE_FACTOR: float = 1.5

var boss: Boss
var elapsed: float = 0.0


func enter(_previousStatePath: String, _data: Dictionary = {}) -> void:
	boss = obj as Boss
	elapsed = 0.0
	obj.vec = Vector2.ZERO
	obj.attack = boss.grabDamage
	boss.faceTarget()
	obj.playAnim(&"grap")


func exit() -> void:
	obj.setHitBoxEnabled(false)


func physics_update(delta: float) -> void:
	elapsed += delta
	obj.setHitBoxEnabled(elapsed >= HIT_FROM and elapsed < HIT_TO)
	var escaped: bool = boss.target != null \
			and boss.lateralDistance(boss.target) > boss.grabDistance * ESCAPE_FACTOR
	if elapsed >= GRAB_TIME or escaped:
		stateMachineNode.transition_to("walkState")
