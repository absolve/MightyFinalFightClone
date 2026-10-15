extends "res://script/map.gd"


@onready var codyP1: Player = $codyP1
@onready var hud: Hud = $hud


func _ready() -> void:
	hud.bindPlayer(codyP1)
