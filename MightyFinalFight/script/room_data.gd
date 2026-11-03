extends Resource
class_name RoomData
## 一个房间的数据：可活动范围、背景、刷怪清单与出口位置。
##
## 房间沿关卡 x 首尾相接，[RoomManager] 一次只实例化一间，
## 下一间靠 [StageData] 里的路径线程预载，所以这里只描述本房的内容。

@export var title: String = ""
## 玩家与敌人在本房的可活动范围（世界坐标）
@export var bounds: Rect2 = Rect2(0, 340, 640, 110)
@export var bgTexture: Texture2D
## 背景左上角的世界坐标（贴图按 bgScale 放大后铺在本房起点）
@export var bgPosition: Vector2 = Vector2.ZERO
@export var bgScale: float = 3.0
@export var spawns: Array[EnemySpawn] = []
## 清场后玩家走到该世界 X 即切换到下一间
@export var exitX: float = 0.0
## Boss 房：清场即过关，不再往前切
@export var isBossRoom: bool = false
