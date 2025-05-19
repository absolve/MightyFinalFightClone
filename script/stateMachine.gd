extends Node

class_name stateMachine

export(NodePath) var initialState
export var enableProcess=false
export var enablePhysicsProcess=true

onready var currState:state = get_node(initialState)

func _ready():
	set_process(enableProcess)
	set_physics_process(enablePhysicsProcess)
	print(owner)

func _process(delta):
	currState.update(delta)


func _physics_process(delta):
	currState.physics_update(delta)
	
func _unhandled_input(event):
	currState.handle_input(event)
	
