extends Node2D
## 关卡基类：背景音乐、下一关、以及本关的可活动范围分发。
##
## playBounds 在 Inspector 里按关卡背景的地面区域填写（世界坐标）；
## 开场由本类统一写给场上所有玩家，玩家移动时被钳制在该矩形内。

## 玩家可活动范围；size 为零表示不限制
@export var playBounds: Rect2 = Rect2()

var bgMusic
var nextStage


func _ready() -> void:
	applyPlayBounds()


# 把本关的可活动范围写给场上所有玩家（分组见 Player.GROUP）
func applyPlayBounds() -> void:
	if playBounds.size == Vector2.ZERO:
		return
	for node in get_tree().get_nodes_in_group(Player.GROUP):
		var fightObject: FightObject = node as FightObject
		if fightObject != null:
			fightObject.playBounds = playBounds
