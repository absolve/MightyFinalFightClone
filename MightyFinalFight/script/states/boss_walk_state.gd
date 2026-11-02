extends State
class_name BossWalkState
## Boss 接近（状态字节 81 行走/接近）：朝玩家的横向与纵深位置靠拢，
## 进入决策距离就交给 [method Boss.chooseAction] 选出的招式状态。

var boss: Boss


func enter(_previousStatePath: String, _data: Dictionary = {}) -> void:
	boss = obj as Boss
	obj.playAnim(&"walk")


func physics_update(_delta: float) -> void:
	if boss.target == null:
		boss.findTarget()
		return
	var action: StringName = boss.chooseAction()
	if action != &"":
		stateMachineNode.transition_to(String(action))
		return
	var dir: Vector2 = boss.directionTo(boss.target)
	obj.setFaceDir(dir.x)
	obj.vec = boss.velocityFromInput(dir)
	obj.moveSelf()
	obj.clampToBounds()
