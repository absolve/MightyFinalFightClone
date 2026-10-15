extends Node2D

const STAGE1_SCENE: String = "res://scene/stage1.tscn"


func _ready() -> void:
	RenderingServer.set_default_clear_color("#000")


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("start"):
		get_tree().change_scene_to_file(STAGE1_SCENE)
