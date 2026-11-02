extends State
class_name BossIntroState
## Boss 登场（状态字节 88 登场/挑衅）：原地站桩后转入接近。
##
## 原作进入 Boss 区还有一段演出与对话（模式 $20 -> $0A，按 A 推进），
## 本作先只做停留时长控制，对话演出留待过场系统接入。

## 登场停留时长（秒）
@export var introTime: float = 1.2

var elapsed: float = 0.0


func enter(_previousStatePath: String, _data: Dictionary = {}) -> void:
	elapsed = 0.0
	obj.vec = Vector2.ZERO
	obj.playAnim(&"default")


func physics_update(delta: float) -> void:
	elapsed += delta
	if elapsed >= introTime:
		stateMachineNode.transition_to("walkState")
