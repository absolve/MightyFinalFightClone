extends CanvasLayer
class_name Hud
## 游戏内 HUD：每个参战玩家一组「血条 + 命数 + LEVEL/EXP」，外加一条敌人/Boss 血条。
##
## 槽位数量跟 Game.playerCount 对齐（单人时隐藏 2P 槽）；血条由 [method bindPlayers]
## 绑定各玩家的 hpChanged 信号实时刷新，命数/等级/经验由 [method setSlotStats] 写入。
## 等级与经验的数值规则由后续等级系统提供（原作最高 LV6，见 doc/原作资料.md §3）。

const MAX_SLOTS: int = 2

@export var level: int = 1
@export var exp: int = 0
@export var expToNext: int = 90

var lives: int = 2
var enemyTarget: FightObject
var slotTargets: Array[FightObject] = []

@onready var slotRoots: Array[Node2D] = [$topBar/slotP1, $topBar/slotP2]
@onready var slotBars: Array[SegmentBar] = [$topBar/slotP1/playerBar, $topBar/slotP2/playerBar]
@onready var slotLives: Array[Label] = [$topBar/slotP1/livesLabel, $topBar/slotP2/livesLabel]
@onready var slotLevels: Array[Label] = [$bottomBar/p1LevelLabel, $bottomBar/p2LevelLabel]
@onready var slotExps: Array[Label] = [$bottomBar/p1ExpLabel, $bottomBar/p2ExpLabel]
@onready var enemyBar: SegmentBar = $topBar/enemySlot/enemyBar
@onready var enemyLabel: TextureRect = $topBar/enemySlot/enemyLabel

# 兼容单人写法的别名：槽位 0 就是原来的唯一玩家
@onready var playerBar: SegmentBar = slotBars[0]
@onready var livesLabel: Label = slotLives[0]
@onready var levelLabel: Label = slotLevels[0]
@onready var expLabel: Label = slotExps[0]


func _ready() -> void:
	slotTargets.resize(MAX_SLOTS)
	for slot: int in MAX_SLOTS:
		setSlotStats(slot, lives, level, exp, expToNext)
	applySlotVisibility()
	updateEnemyBarVisible()


func activeSlotCount() -> int:
	return clampi(Game.playerCount, 1, MAX_SLOTS)


func applySlotVisibility() -> void:
	for slot: int in MAX_SLOTS:
		var shown: bool = slot < activeSlotCount()
		slotRoots[slot].visible = shown
		slotLevels[slot].visible = shown
		slotExps[slot].visible = shown


func bindPlayers(players: Array[FightObject]) -> void:
	for slot: int in mini(players.size(), MAX_SLOTS):
		bindPlayer(players[slot], slot)


func bindPlayer(playerObj: FightObject, slot: int = 0) -> void:
	if slot < 0 or slot >= MAX_SLOTS:
		return
	slotTargets[slot] = playerObj
	playerObj.hpChanged.connect(onSlotHpChanged.bind(slot))
	refreshSlotBar(slot)


func showEnemyBar(enemyObj: FightObject) -> void:
	enemyTarget = enemyObj
	enemyObj.hpChanged.connect(onEnemyHpChanged)
	updateEnemyBarVisible()
	onEnemyHpChanged(enemyObj.hp)


func hideEnemyBar() -> void:
	enemyTarget = null
	updateEnemyBarVisible()


# 单人旧接口：都作用在槽位 0
func setLives(value: int) -> void:
	lives = value
	slotLives[0].text = "PL ×%d" % value


func setLevel(value: int) -> void:
	level = value
	slotLevels[0].text = "LEVEL %d" % value


func setExp(current: int, needed: int) -> void:
	exp = current
	expToNext = needed
	slotExps[0].text = "EXP %03d/%03d" % [current, needed]


func setSlotStats(slot: int, newLives: int, newLevel: int, newExp: int, newExpToNext: int) -> void:
	if slot < 0 or slot >= MAX_SLOTS:
		return
	slotLives[slot].text = "PL ×%d" % newLives
	slotLevels[slot].text = "LEVEL %d" % newLevel
	slotExps[slot].text = "EXP %03d/%03d" % [newExp, newExpToNext]


func refreshSlotBar(slot: int) -> void:
	var target: FightObject = slotTargets[slot]
	if target == null:
		return
	slotBars[slot].setRatio(float(target.hp) / float(target.maxHp))


func onSlotHpChanged(currentHp: int, slot: int) -> void:
	var target: FightObject = slotTargets[slot]
	if target == null:
		return
	slotBars[slot].setRatio(float(currentHp) / float(target.maxHp))


func onEnemyHpChanged(currentHp: int) -> void:
	if enemyTarget == null:
		return
	enemyBar.setRatio(float(currentHp) / float(enemyTarget.maxHp))
	if currentHp <= 0:
		hideEnemyBar()


func updateEnemyBarVisible() -> void:
	var showEnemy: bool = enemyTarget != null
	enemyBar.visible = showEnemy
	enemyLabel.visible = showEnemy
