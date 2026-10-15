extends CanvasLayer
class_name Hud
## 游戏内 HUD：玩家/敌人分段血条、命数、分数与倒计时。
##
## 玩家血条通过 [method bindPlayer] 绑定 [FightObject] 的 hpChanged 信号实时刷新；
## 敌人血条（Boss 战）平时隐藏，[method showEnemyBar] 显示并跟随目标血量，
## 目标血量归零时自动隐藏。倒计时归零发出 [signal timeOver]。

signal timeOver

const TIME_LIMIT: int = 99

@export var timeLimit: int = TIME_LIMIT

var score: int = 0
var lives: int = 2
var timeLeft: int = TIME_LIMIT
var timeAcc: float = 0.0
var playerTarget: FightObject
var enemyTarget: FightObject

@onready var playerBar: SegmentBar = $topBar/playerBar
@onready var enemyBar: SegmentBar = $topBar/enemyBar
@onready var enemyLabel: TextureRect = $topBar/enemyLabel
@onready var livesLabel: Label = $topBar/livesLabel
@onready var scoreLabel: Label = $bottomBar/scoreLabel
@onready var timeLabel: Label = $bottomBar/timeLabel


func _ready() -> void:
	setScore(0)
	setLives(lives)
	timeLeft = timeLimit
	timeAcc = 0.0
	updateTimeLabel()
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


func addScore(points: int) -> void:
	setScore(score + points)


func setScore(value: int) -> void:
	score = value
	scoreLabel.text = "SCORE %07d" % score


func setLives(value: int) -> void:
	lives = value
	livesLabel.text = "PL ×%d" % lives


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


func updateTimeLabel() -> void:
	timeLabel.text = "TIME %02d" % timeLeft


func _process(delta: float) -> void:
	if timeLeft <= 0:
		return
	timeAcc += delta
	if timeAcc >= 1.0:
		timeAcc -= 1.0
		timeLeft -= 1
		updateTimeLabel()
		if timeLeft <= 0:
			timeOver.emit()
