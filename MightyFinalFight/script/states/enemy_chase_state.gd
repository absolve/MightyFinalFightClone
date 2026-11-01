extends State
class_name EnemyChaseState
## 敌人追击：朝玩家的横向与纵深位置靠拢（纵深按 depthSpeedFactor 减速），
## 进入出拳判定距离就交给 attackState；目标丢失则回待机。

var enemy: Enemy


func enter(_previousStatePath: String, _data: Dictionary = {}) -> void:
	enemy = obj as Enemy
	obj.playAnim(&"walk")


func physics_update(_delta: float) -> void:
	if enemy.target == null:
		stateMachineNode.transition_to("idleState")
		return
	if enemy.inAttackPose():
		# 已在出拳位置但冷却没好：站住守卫，别顶着玩家身体原地蹭步
		obj.vec = Vector2.ZERO
		obj.playAnim(&"default")
		if enemy.canAttack():
			stateMachineNode.transition_to("attackState")
		return
	var dir: Vector2 = enemy.directionTo(enemy.target)
	obj.setFaceDir(dir.x)
	obj.vec = obj.velocityFromInput(dir)
	obj.moveSelf()
	obj.clampToBounds()
	if enemy.canAttack():
		stateMachineNode.transition_to("attackState")
	elif enemy.lateralDistance(enemy.target) > enemy.aggroRange:
		stateMachineNode.transition_to("idleState")
