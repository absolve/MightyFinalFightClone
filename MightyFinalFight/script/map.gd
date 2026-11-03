extends Node2D
class_name Map
## 关卡基类：背景音乐、下一关、以及本关的可活动范围分发。
##
## playBounds 由 [RoomManager] 按当前房间逐间写入（无房间系统时在 Inspector 里填死）；
## 开场与换房时由本类统一发给场上所有玩家与敌人，移动时被钳在该矩形内。

## 玩家可活动范围；size 为零表示不限制
@export var playBounds: Rect2 = Rect2()

var bgMusic
var nextStage


func _ready() -> void:
	applyPlayBounds()


# 把本关的可活动范围写给场上所有玩家与敌人（分组见 Player.GROUP / Enemy.GROUP）
func applyPlayBounds() -> void:
	if playBounds.size == Vector2.ZERO:
		return
	for groupName: StringName in [Player.GROUP, Enemy.GROUP]:
		for node in get_tree().get_nodes_in_group(groupName):
			var fightObject: FightObject = node as FightObject
			if fightObject != null:
				fightObject.playBounds = playBounds
