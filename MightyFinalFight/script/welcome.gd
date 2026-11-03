extends Node2D

const CHARACTER_SELECT_SCENE: String = "res://scene/ui/character_select.tscn"


func _ready() -> void:
	RenderingServer.set_default_clear_color("#000")


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("start"):
		get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE)
