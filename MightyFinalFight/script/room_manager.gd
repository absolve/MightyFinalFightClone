extends Node
class_name RoomManager
## 房间调度：一次只实例化当前房间，下一间用 ResourceLoader 线程预载；
## 当前房间清空后解锁前进，玩家走到 exitX 就换成预载好的下一间。
##
## 锁房只需要改一块矩形：本房 bounds 写给关卡（playBounds）与相机 limit，
## 角色与敌人各自被钳在范围内，不需要每个对象自己判断「能不能过去」。

signal roomChanged(roomIndex: int)
signal stageFinished

@export var stageData: StageData
## 相机固定的纵向位置：地面带在 340~450，取视口半高即可
@export var cameraY: float = 240.0
## 取景高度，用于把相机上下 limit 钉死（清版动作游戏不做纵向滚动）
@export var viewHeight: float = 480.0

@onready var camera: Camera2D = get_node_or_null("camera") as Camera2D
@onready var mapNode: Map = get_parent() as Map

var roomIndex: int = -1
var currentRoom: Room
var currentData: RoomData
var requested: Dictionary = {}


func _ready() -> void:
	if stageData == null or stageData.roomPaths.is_empty():
		push_error("RoomManager 未配置 stageData / roomPaths")
		return
	requestRoom(1)
	activateRoom(0)


func _physics_process(_delta: float) -> void:
	if currentRoom == null:
		return
	followCamera()
	advanceIfExitReached()


# 线程预载：房间 .tres 连同它引用的敌人场景一起进缓存，切间时不再卡帧
func requestRoom(index: int) -> void:
	if index < 0 or index >= stageData.roomPaths.size() or requested.has(index):
		return
	requested[index] = ResourceLoader.load_threaded_request(stageData.roomPaths[index])


# 预载已完成或仍在进行中都走 threaded_get（进行中会等到完成），失败才退回主线程 load
func takeRoom(index: int) -> RoomData:
	var path: String = stageData.roomPaths[index]
	if int(requested.get(index, ERR_UNAVAILABLE)) == OK:
		var status: int = ResourceLoader.load_threaded_get_status(path)
		if status != ResourceLoader.THREAD_LOAD_FAILED:
			return ResourceLoader.load_threaded_get(path) as RoomData
	return load(path) as RoomData


func activateRoom(index: int) -> void:
	if index < 0 or index >= stageData.roomPaths.size():
		return
	var data: RoomData = takeRoom(index)
	if data == null:
		push_error("房间加载失败：%s" % stageData.roomPaths[index])
		return
	roomIndex = index
	currentData = data
	if currentRoom != null:
		currentRoom.queue_free()
	currentRoom = Room.new()
	currentRoom.name = "room%d" % index
	add_child(currentRoom)
	currentRoom.setup(data)
	currentRoom.cleared.connect(onRoomCleared)
	applyBounds(data.bounds)
	applyCameraLimits(data.bounds)
	requestRoom(index + 1)
	roomChanged.emit(index)


func applyBounds(bounds: Rect2) -> void:
	if mapNode == null:
		return
	mapNode.playBounds = bounds
	mapNode.applyPlayBounds()


func applyCameraLimits(bounds: Rect2) -> void:
	if camera == null:
		return
	camera.limit_left = int(bounds.position.x)
	camera.limit_right = int(bounds.end.x)
	camera.limit_top = int(cameraY - viewHeight * 0.5)
	camera.limit_bottom = int(cameraY + viewHeight * 0.5)


# 相机横向跟玩家，但被夹在本房范围内：房间比一屏窄时居中，不来回抖
func followCamera() -> void:
	if camera == null or currentData == null:
		return
	var halfWidth: float = get_viewport().get_visible_rect().size.x * 0.5
	var minX: float = currentData.bounds.position.x + halfWidth
	var maxX: float = currentData.bounds.end.x - halfWidth
	var targetX: float = framingCenter()
	if maxX < minX:
		targetX = currentData.bounds.get_center().x
	else:
		targetX = clampf(targetX, minX, maxX)
	camera.global_position = Vector2(targetX, cameraY)


# 单人跟本人，双人取两人中点，保证两边都在镜头里
func framingCenter() -> float:
	var players: Array[FightObject] = Player.alivePlayers(get_tree())
	if players.is_empty():
		return camera.global_position.x
	var nearestX: float = players[0].global_position.x
	var furthestX: float = nearestX
	for player: FightObject in players:
		nearestX = minf(nearestX, player.global_position.x)
		furthestX = maxf(furthestX, player.global_position.x)
	return (nearestX + furthestX) * 0.5


func onRoomCleared() -> void:
	if currentData != null and currentData.isBossRoom:
		stageFinished.emit()


# 清场后玩家继续往右走到 exitX 才真正切间，切间过程不打断操作
func advanceIfExitReached() -> void:
	if currentRoom == null or not currentRoom.isCleared():
		return
	if currentData.isBossRoom or currentData.exitX <= 0.0:
		return
	var player: FightObject = currentRoom.findPlayer()
	if player != null and player.global_position.x >= currentData.exitX:
		activateRoom(roomIndex + 1)
