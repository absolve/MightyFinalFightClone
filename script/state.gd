extends Node

class_name state


func _ready():
	set_physics_process(false)
	set_process(false)

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass
	
func enter(previous_state_path: String, data := {}) -> void:
	pass	
	
func exit() -> void:
	pass

func handle_input(_event: InputEvent) -> void:
	pass
