extends "res://script/map.gd"
## 第一关：按选人结果生成 1-2 名玩家，再交给 HUD 与房间调度。
##
## 玩家不在场景里写死，因为出场角色由选人画面决定；
## 出生点按槽位错开，避免两人重叠卡住彼此的身体碰撞。

# 出生点必须落在 room1 的 bounds（x 900~3000）内，否则第一次移动就被钳回来
const SPAWN_POINTS: Array[Vector2] = [Vector2(930, 400), Vector2(986, 400)]

@onready var hud: Hud = $hud

var players: Array[FightObject] = []


func _ready() -> void:
	super._ready()
	spawnPlayers()
	hud.bindPlayers(players)
	# RoomManager 是子节点，它的 _ready 早于本函数，玩家当时还不存在，补发一次范围
	applyPlayBounds()


func spawnPlayers() -> void:
	for slot: int in hud.activeSlotCount():
		var player: Player = (load(Game.selectedScenePath(slot)) as PackedScene).instantiate() as Player
		# playerId 必须在 add_child 前设好：FightObject._ready 里就按它派生 keyMapPrefix
		player.playerId = Game.PlayId.P1 if slot == 0 else Game.PlayId.P2
		player.position = SPAWN_POINTS[slot]
		add_child(player)
		players.append(player)
