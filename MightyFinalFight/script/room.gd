extends Node2D
class_name Room
## 房间运行时：按 [EnemySpawn] 的触发条件把敌人刷出来，
## 全部刷完且全部倒下后发 [signal cleared]，何时切下一间由 [RoomManager] 决定。
##
## 房间本身不是场景，由 [RoomManager] 用 [RoomData] 在运行期搭出来：
## 一间房 = 一段背景 + 一份刷怪清单 + 一块可活动范围。

signal cleared

## 场外进场时相对世界坐标的横向偏移（世界像素，比半屏略多，保证是从屏幕外走进来）
const OFFSCREEN_OFFSET: float = 380.0

var data: RoomData
var elapsed: float = 0.0
var pending: Array[EnemySpawn] = []
var armedAt: Dictionary = {}
var alive: Array[Enemy] = []
var clearedEmitted: bool = false


func setup(roomData: RoomData) -> void:
	data = roomData
	pending = roomData.spawns.duplicate()
	placeBackground()


func _physics_process(delta: float) -> void:
	elapsed += delta
	trySpawnPending()
	pruneAlive()
	if clearedEmitted or not pending.is_empty() or not alive.is_empty():
		return
	clearedEmitted = true
	cleared.emit()


func isCleared() -> bool:
	return clearedEmitted


# 触发与出口判定用的参考玩家：存活玩家里推进最前（x 最大）的那个，
# 双人时保证落在后面的人不会把波次卡住
func findPlayer() -> FightObject:
	var lead: FightObject = null
	for candidate: FightObject in Player.alivePlayers(get_tree()):
		if lead == null or candidate.global_position.x > lead.global_position.x:
			lead = candidate
	return lead


func placeBackground() -> void:
	if data.bgTexture == null:
		return
	var bg: Sprite2D = Sprite2D.new()
	bg.texture = data.bgTexture
	bg.centered = false
	bg.position = data.bgPosition
	bg.scale = Vector2(data.bgScale, data.bgScale)
	add_child(bg)


# 触发条件一旦不成立就重新计时，delay 始终相对「条件刚成立」的那一刻
func trySpawnPending() -> void:
	var player: FightObject = findPlayer()
	var remaining: Array[EnemySpawn] = []
	for spawn: EnemySpawn in pending:
		if not isTriggerReady(spawn, player):
			armedAt.erase(spawn)
			remaining.append(spawn)
			continue
		if not armedAt.has(spawn):
			armedAt[spawn] = elapsed
		if elapsed - float(armedAt[spawn]) < spawn.delay:
			remaining.append(spawn)
			continue
		spawnEnemy(spawn, player)
	pending = remaining


func isTriggerReady(spawn: EnemySpawn, player: FightObject) -> bool:
	match spawn.trigger:
		EnemySpawn.Trigger.ON_ENTRY:
			return true
		EnemySpawn.Trigger.AT_PLAYER_X:
			return player != null and player.global_position.x >= spawn.triggerX
		EnemySpawn.Trigger.WHEN_ALIVE_BELOW:
			return alive.size() < spawn.aliveThreshold
	return false


func spawnPosition(spawn: EnemySpawn) -> Vector2:
	var spawnPos: Vector2 = spawn.worldPosition
	match spawn.enterFrom:
		EnemySpawn.EnterFrom.SCREEN_LEFT:
			spawnPos.x -= OFFSCREEN_OFFSET
		EnemySpawn.EnterFrom.SCREEN_RIGHT:
			spawnPos.x += OFFSCREEN_OFFSET
	return spawnPos


func spawnEnemy(spawn: EnemySpawn, player: FightObject) -> void:
	if spawn.enemyScene == null:
		push_error("刷怪条目缺少 enemyScene：%s" % spawn.resource_path)
		return
	var enemy: Enemy = spawn.enemyScene.instantiate() as Enemy
	add_child(enemy)
	enemy.global_position = spawnPosition(spawn)
	enemy.playBounds = data.bounds
	if spawn.hp > 0:
		enemy.hp = spawn.hp
		enemy.maxHp = spawn.hp
	if spawn.facing != 0:
		enemy.setFaceDir(float(spawn.facing))
	elif player != null:
		enemy.setFaceDir(signf(player.global_position.x - enemy.global_position.x))
	alive.append(enemy)


# 倒下（hp<=0）就算清完，不等倒地动画播完，避免清场判定被 0.9s 的移除延迟拖住
func pruneAlive() -> void:
	var kept: Array[Enemy] = []
	for enemy: Enemy in alive:
		if is_instance_valid(enemy) and enemy.hp > 0:
			kept.append(enemy)
	alive = kept
