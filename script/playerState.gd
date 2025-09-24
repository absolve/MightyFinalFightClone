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
	var xDir= Input.get_axis("%s_left"%player.keyMapPrefix,"%s_right"%player.keyMapPrefix)
	if xDir>0:
		player.vec.x=player.speed
	elif xDir<0:
		player.vec.x=-player.speed
	else:
		player.vec.x=0
	
	var yDir=Input.get_axis("%s_up"%player.keyMapPrefix,"%s_down"%player.keyMapPrefix)
	if yDir>0:
		player.vec.y=player.speed
	elif yDir<0:
		player.vec.y=-player.speed	
	else:
		player.vec.y=0
	
	if Input.is_action_pressed("%s_jump"%player.keyMapPrefix):
		if !player.inAir:
			player.inAir=true
			player.zVec=-500
		
	if player.inAir:
		player.zVec+=player.gravity*_delta
		print(player.zVec)
		player.bodyNode.position.y+=player.zVec*_delta
#		print(player.bodyNode.position.y)
		if player.bodyNode.position.y>=0:
			player.inAir=false
			player.bodyNode.position.y=0
		
	player.move_and_slide(player.vec)
	
func animation():
	
	pass

