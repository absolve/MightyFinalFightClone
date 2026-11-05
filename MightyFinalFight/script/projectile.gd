extends Area2D
class_name Projectile
## 飞行物基类：投掷/发射的弹体（Cody 气功波与小刀、Guy 飞镖，以及敌人飞刀）。
##
## 用法与 [DamageNumber] 一致：实例化子场景 -> add_child -> 设 global_position ->
## [method setup]。命中 [FightObject] 的 hurtBox 结算伤害；飞出 [member flyBounds]
## 横向范围、或超出 lifeTime 自行释放。
## 弹道参数、贴图与碰撞层都在子场景 Inspector 里配置：
## 玩家侧弹体 collision_layer 取 playerHitBox、collision_mask 取 enemy；敌人侧反之。

## 命中伤害：原作玩家投掷武器命中为 8，敌人飞刀按类型 4~8
@export var damage: int = 8
## 横向速度（世界像素/秒）：原作手里剑最快、小刀居中、气功波最慢
@export var speed: float = 240.0
## 纵向初速（世界像素/秒），抛物线弹用；0 表示水平直线
@export var launchVerticalSpeed: float = 0.0
## 每秒叠加的纵向速度（抛物线下坠），0 表示不坠
## 命名避开 Area2D 内置的 gravity（那是 2D 重力场属性）
@export var fallGravity: float = 0.0
## 最长存活时间（秒），没撞上目标也没飞出 flyBounds 时的兜底消失
@export var lifeTime: float = 2.0
## 命中后是否继续飞行（贯穿多个目标）
@export var pierce: bool = false
## 横向飞行范围，飞出即消失；size.x 为 0 表示不判定，只靠 lifeTime 兜底。
## 只判横向：地面带只有 110 px 高，抛物线弹会升到带上沿，按纵向判会当场删掉。
## 留空时由 [method setup] 取投掷者的 playBounds（= 当前房间 bounds）
@export var flyBounds: Rect2 = Rect2()

@onready var ani: AnimatedSprite2D = $Ani

var direction: int = 1
var thrower: FightObject
var elapsed: float = 0.0
var verticalSpeed: float = 0.0
var finished: bool = false


func _ready() -> void:
	area_entered.connect(onAreaEntered)


func setup(dir: int, amount: int, source: FightObject = null) -> void:
	direction = -1 if dir < 0 else 1
	damage = amount
	thrower = source
	verticalSpeed = launchVerticalSpeed
	# 未单独配置范围时跟着投掷者的可活动范围走：房间制关卡里那就是本房 bounds
	if flyBounds.size.x == 0.0 and source != null:
		flyBounds = source.playBounds
	if ani != null and ani.sprite_frames != null and ani.sprite_frames.has_animation(&"default"):
		ani.play(&"default")


func despawn() -> void:
	if finished:
		return
	finished = true
	queue_free()


func onAreaEntered(area: Area2D) -> void:
	var target: FightObject = area.owner as FightObject
	if target == null or target == thrower:
		return
	target.takeDamage(damage, direction)
	if not pierce:
		despawn()


func isOutOfBounds() -> bool:
	if flyBounds.size.x <= 0.0:
		return false
	return global_position.x < flyBounds.position.x or global_position.x > flyBounds.end.x


func _physics_process(delta: float) -> void:
	elapsed += delta
	verticalSpeed += fallGravity * delta
	global_position += Vector2(speed * direction, verticalSpeed) * delta
	if ani != null and ani.sprite_frames != null:
		ani.flip_h = direction < 0
	if elapsed >= lifeTime or isOutOfBounds():
		despawn()
