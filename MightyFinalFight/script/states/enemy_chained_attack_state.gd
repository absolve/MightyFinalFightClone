extends EnemyAttackState
class_name EnemyChainedAttackState
## 多段攻击：原作类型 2 与类型 5 在同一次出手里命中两段
## （实测命中时刻 8~55 帧 与 ≈102 帧，见 逆向分析.md §12.12/§12.14）。
##
## 一段 act1 播完就重播，累计到 hitCount 段才回待机；命中窗口仍由动画方法轨道给出。
## 尚未接动画时沿用父类的兜底时长，会退化成单段攻击。

## 一次出手里的命中段数
@export var hitCount: int = 2

var roundsLeft: int = 0


func enter(previousStatePath: String, data: Dictionary = {}) -> void:
	super(previousStatePath, data)
	roundsLeft = hitCount


func onAnimationFinished(animName: StringName) -> void:
	if stateMachineNode.currState != self or animName != &"act1":
		return
	roundsLeft -= 1
	if roundsLeft > 0:
		obj.playAnim(&"act1")
		return
	stateMachineNode.transition_to("idleState")
