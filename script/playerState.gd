extends "res://script/state.gd"

class_name playerState

var player

func _ready():
	print(owner)
	yield(owner,"ready")
	player=owner
	
	
func enter(previous_state_path: String, data := {}) -> void:
	
	pass

func physics_update(_delta: float) -> void:
	var xDir= Input.get_axis("p1_left","p1_right")
	if xDir==0:
		player.vec.x=0
	elif xDir>0:
		player.vec.x=player.speed
	elif xDir<0:
		player.vec.x=-player.speed
	
	var yDir=Input.get_axis("p1_up","p1_down")
	if yDir==0:
		player.vec.y=0
	elif yDir>0:
		player.vec.y=player.speed
	elif yDir<0:
		player.vec.y=-player.speed	
	
		
	player.move_and_slide(player.vec)
	
func animation():
	
	pass

