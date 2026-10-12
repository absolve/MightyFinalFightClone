extends Node
class_name StateMachine
## 状态机驱动器：每帧分发到当前状态并支持状态切换。
##
## 玩家与敌人共用的基础框架，不含任何角色专属逻辑；
## 具体行为由子树上的状态节点（[State] 子类）实现。

@export var initialState: NodePath
@export var enableProcess: bool = false
@export var enablePhysicsProcess: bool = true

var currState: State

func _ready() -> void:
	set_process(enableProcess)
	set_physics_process(enablePhysicsProcess)
	await owner.ready
	currState = get_node(initialState) as State
	currState.enter("", {})


func transition_to(statePath: String, data: Dictionary = {}) -> void:
	if not has_node(statePath):
		push_error("状态节点不存在: %s" % statePath)
		return
	var nextState: State = get_node(statePath) as State
	if nextState == null:
		return
	# 允许自转移（如攻击连段递进），退出后重新进入
	var previousPath: String = currState.name
	currState.exit()
	currState = nextState
	currState.enter(previousPath, data)


func _process(delta: float) -> void:
	currState.update(delta)


func _physics_process(delta: float) -> void:
	currState.physics_update(delta)


func _unhandled_input(event: InputEvent) -> void:
	currState.handle_input(event)
