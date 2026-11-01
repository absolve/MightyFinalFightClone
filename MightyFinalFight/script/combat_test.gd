extends Node2D
class_name CombatTest
## 对战测试沙盒：自由切换可选角色、刷不同敌人，并实时显示双方状态与动画。
##
## 热键（不与 p1/p2 按键冲突）：
## - 1 / 2 / 3 = 给 P1 换角色，4 / 5 / 6 = 给 P2 换角色（按 roster 顺序）
## - E = 刷一个敌人（连按会轮换 enemyScenes 里的不同敌人）
## - C = 清空敌人，R = 重置（角色回原点满血 + 清空敌人）
## - H = 显示/隐藏状态面板
##
## 角色与敌人都从 Inspector 的数组里取：新增角色/敌人只要把场景拖进数组，
## 本场景与状态面板都会自动带上，不需要改代码。

@export var playerScenes: Array[PackedScene] = []
@export var enemyScenes: Array[PackedScene] = []
## 可活动范围（世界坐标），与关卡里 Map.playBounds 保持一致便于对照
@export var playBounds: Rect2 = Rect2(20, 340, 600, 110)
@export var p1Spawn: Vector2 = Vector2(180, 380)
@export var p2Spawn: Vector2 = Vector2(140, 420)
## 敌人相对 P1 的出生偏移，纵深再随机 ±24
@export var enemySpawnOffset: Vector2 = Vector2(240, 0)

@onready var playerHolder: Node2D = $playerHolder
@onready var enemyHolder: Node2D = $enemyHolder
@onready var hud: Hud = $hud
@onready var debugLabel: Label = $debugLayer/debugLabel

# playerId -> 当前角色场景下标；-1 表示该槽位没有角色
var slots: Array[int] = [-1, -1]
var players: Array[Player] = [null, null]
var enemyTurn: int = 0
var debugVisible: bool = true
var refreshTick: float = 0.0


func _ready() -> void:
	selectPlayer(0, 0)


# ---------------------------------------------------------------- 角色

func selectPlayer(slot: int, charIndex: int) -> void:
	if slot < 0 or slot >= slots.size() or charIndex < 0 or charIndex >= playerScenes.size():
		return
	slots[slot] = charIndex
	freeNode(players[slot])
	var player: Player = playerScenes[charIndex].instantiate() as Player
	if player == null:
		push_error("roster 里第 %d 个场景不是 Player（缺玩家状态机？）" % charIndex)
		return
	player.playerId = slot
	player.position = p1Spawn if slot == 0 else p2Spawn
	player.playBounds = playBounds
	playerHolder.add_child(player)
	players[slot] = player
	if slot == 0:
		hud.bindPlayer(player)


func currentLabel(slot: int) -> String:
	if slots[slot] < 0:
		return "空"
	return playerScenes[slots[slot]].resource_path.get_file().get_basename()


# ---------------------------------------------------------------- 敌人

func spawnEnemy() -> void:
	if enemyScenes.is_empty():
		return
	var scene: PackedScene = enemyScenes[enemyTurn % enemyScenes.size()]
	enemyTurn += 1
	var enemy: FightObject = scene.instantiate() as FightObject
	if enemy == null:
		push_error("roster 里第 %d 个场景不是 FightObject" % enemyTurn)
		return
	enemy.position = p1Spawn + enemySpawnOffset \
			+ Vector2(randf_range(-16.0, 48.0), randf_range(-24.0, 24.0))
	enemy.playBounds = playBounds
	enemyHolder.add_child(enemy)


func clearEnemies() -> void:
	for child in enemyHolder.get_children():
		freeNode(child)


func resetAll() -> void:
	clearEnemies()
	for slot in slots.size():
		if slots[slot] >= 0:
			selectPlayer(slot, slots[slot])


# ---------------------------------------------------------------- 面板

func _process(delta: float) -> void:
	if not debugVisible:
		return
	# 逐帧拼字符串没必要，10 帧刷新一次足够看清状态流转
	refreshTick += delta
	if refreshTick < 0.16:
		return
	refreshTick = 0.0
	debugLabel.text = buildDebugText()


func buildDebugText() -> String:
	var lines: Array[String] = ["1/2/3=P1 4/5/6=P2 E=刷敌人 C=清空 R=重置 H=面板"]
	for slot in players.size():
		lines.append("P%d [%s] %s" % [slot + 1, currentLabel(slot), describe(players[slot])])
	lines.append("敌人 %d 个：" % enemyHolder.get_child_count())
	for child in enemyHolder.get_children():
		lines.append("  " + describe(child as FightObject))
	return "\n".join(lines)


func describe(obj: FightObject) -> String:
	if obj == null or not is_instance_valid(obj):
		return "-"
	var anim: String = String(obj.playback.get_current_node()) if obj.playback != null else "-"
	return "state=%-12s anim=%-11s hp=%3d/%3d x=%4.0f y=%3.0f dir=%+d" % [
			stateName(obj), anim, obj.hp, obj.maxHp,
			obj.global_position.x, obj.global_position.y, obj.faceDir]


func stateName(obj: FightObject) -> String:
	var state: State = obj.stateMachineNode.currState
	return "未接线" if state == null else String(state.name)


# ---------------------------------------------------------------- 输入与工具

func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_1:
			selectPlayer(0, 0)
		KEY_2:
			selectPlayer(0, 1)
		KEY_3:
			selectPlayer(0, 2)
		KEY_4:
			selectPlayer(1, 0)
		KEY_5:
			selectPlayer(1, 1)
		KEY_6:
			selectPlayer(1, 2)
		KEY_E:
			spawnEnemy()
		KEY_C:
			clearEnemies()
		KEY_R:
			resetAll()
		KEY_H:
			debugVisible = not debugVisible
			debugLabel.visible = debugVisible
		_:
			return
	get_viewport().set_input_as_handled()


func freeNode(node: Node) -> void:
	if not is_instance_valid(node):
		return
	node.get_parent().remove_child(node)
	node.free()
