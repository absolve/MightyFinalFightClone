extends Node
class_name State
## 状态基类：玩家与敌人状态的父类，由 [StateMachine] 驱动分发。
##
## 子类覆盖 [method enter] / [method exit] / [method physics_update] /
## [method handle_input] / [method onAnimationFinished] 实现具体行为；
## 玩家状态建议继承 PlayerState 以获得搓招等玩家专属逻辑。

var obj: FightObject
var stateMachineNode: StateMachine

func _ready() -> void:
	set_process(false)
	set_physics_process(false)
	await owner.ready
	obj = owner as FightObject
	stateMachineNode = get_parent() as StateMachine
	obj.tree.animation_finished.connect(onAnimationFinished)


func enter(previousStatePath: String, data: Dictionary = {}) -> void:
	pass


func exit() -> void:
	pass


func update(delta: float) -> void:
	pass


func physics_update(delta: float) -> void:
	pass


func handle_input(event: InputEvent) -> void:
	pass


# AnimationTree（AnimationMixer）的 animation_finished 带片段名参数
func onAnimationFinished(animName: StringName) -> void:
	pass
