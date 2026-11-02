extends State
class_name EnemyAttackState
## 敌人出拳：播 act1，攻击框由动画方法轨道按命中窗口开关；
## 收拳后回待机并进入冷却（冷却在 Enemy 本体推进）。
##
## 场景还没挂 SpriteFrames 时没人开框，此时按 fallbackHitWindow 兜底，
## 接上动画后（hasAnim 为真）兜底自动失效，窗口重新由 hitWindow 方法轨道决定。

## 兜底脱困时长：没收到片段结束信号时强制回待机
const STALL_GUARD_TIME: float = 0.2

## 未接动画时的命中窗口（秒）：原作类型 1 在出手后第 3 帧命中
@export var fallbackHitWindow: Vector2 = Vector2(0.05, 0.2)

var enemy: Enemy
var elapsed: float = 0.0


func enter(_previousStatePath: String, _data: Dictionary = {}) -> void:
	enemy = obj as Enemy
	elapsed = 0.0
	obj.vec = Vector2.ZERO
	obj.attack = enemy.punchDamage
	# 出拳瞬间补一次转向，避免追击途中玩家绕到背后
	enemy.faceTarget()
	obj.playAnim(&"act1")


func exit() -> void:
	obj.setHitBoxEnabled(false)
	enemy.startAttackCooldown()


func physics_update(delta: float) -> void:
	elapsed += delta
	if not obj.hasAnim(&"act1"):
		obj.setHitBoxEnabled(elapsed >= fallbackHitWindow.x and elapsed < fallbackHitWindow.y)
	if elapsed >= obj.getAnimLength(&"act1") + STALL_GUARD_TIME:
		stateMachineNode.transition_to("idleState")


func onAnimationFinished(animName: StringName) -> void:
	if stateMachineNode.currState != self:
		return
	if animName == &"act1":
		stateMachineNode.transition_to("idleState")
