extends State
class_name EnemyIdleState
## 敌人待机：原地守卫动画，按横向/纵深距离决定追击还是直接出拳。

var enemy: Enemy


func enter(_previousStatePath: String, _data: Dictionary = {}) -> void:
	enemy = obj as Enemy
	obj.vec = Vector2.ZERO
	obj.playAnim(&"default")


func physics_update(_delta: float) -> void:
	if enemy.target == null:
		enemy.findTarget()
	if enemy.canAttack():
		stateMachineNode.transition_to("attackState")
	elif enemy.target != null:
		stateMachineNode.transition_to("chaseState")
