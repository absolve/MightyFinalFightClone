extends CanvasLayer
class_name Hud
## 游戏内 HUD：玩家/敌人分段血条、命数、等级与经验。
##
## 玩家血条通过 [method bindPlayer] 绑定 [FightObject] 的 hpChanged 信号实时刷新；
## 敌人血条（Boss 战）平时隐藏，[method showEnemyBar] 显示并跟随目标血量，
## 目标血量归零时自动隐藏。等级/经验仅负责显示，数值规则由后续等级系统提供
## （原作最高 LV6、特殊攻击 LV4 解锁，见 doc/原作资料.md §3）。

@export var level: int = 1
@export var exp: int = 0
@export var expToNext: int = 90

var lives: int = 2
var playerTarget: FightObject
var enemyTarget: FightObject

@onready var playerBar: SegmentBar = $topBar/playerBar
@onready var enemyBar: SegmentBar = $topBar/enemyBar
@onready var enemyLabel: TextureRect = $topBar/enemyLabel
@onready var livesLabel: Label = $topBar/livesLabel
@onready var levelLabel: Label = $bottomBar/levelLabel
@onready var expLabel: Label = $bottomBar/expLabel


func _ready() -> void:
	setLives(lives)
	setLevel(level)
	setExp(exp, expToNext)
	updateEnemyBarVisible()


func bindPlayer(playerObj: FightObject) -> void:
	playerTarget = playerObj
	playerObj.hpChanged.connect(onPlayerHpChanged)
	onPlayerHpChanged(playerObj.hp)


func showEnemyBar(enemyObj: FightObject) -> void:
	enemyTarget = enemyObj
	enemyObj.hpChanged.connect(onEnemyHpChanged)
	updateEnemyBarVisible()
	onEnemyHpChanged(enemyObj.hp)


func hideEnemyBar() -> void:
	enemyTarget = null
	updateEnemyBarVisible()


func setLives(value: int) -> void:
	lives = value
	livesLabel.text = "PL ×%d" % lives


func setLevel(value: int) -> void:
	level = value
	levelLabel.text = "LEVEL %d" % level


func setExp(current: int, needed: int) -> void:
	exp = current
	expToNext = needed
	expLabel.text = "EXP %03d/%03d" % [exp, expToNext]


func onPlayerHpChanged(currentHp: int) -> void:
	if playerTarget == null:
		return
	playerBar.setRatio(float(currentHp) / float(playerTarget.maxHp))


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
