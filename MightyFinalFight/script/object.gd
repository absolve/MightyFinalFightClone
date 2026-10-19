extends CharacterBody2D
class_name FightObject
## 战斗对象基类：血量、移动、伪 Z 轴跳跃、朝向与命中盒。
##
## 玩家（继承 [Player]）与敌人、Boss 均继承本类；
## 具体行为由 stateMachine 子树上的状态节点驱动。
##
## 本类同时提供「基本操作」所需的通用能力：
## 四向输入读取（[method getMoveInput]）、按纵深系数换算速度（[method velocityFromInput]）、
## 转向（[method faceInput]）、移动 + 边界钳制（[method moveByInput]）、
## 伪 Z 轴重力（[method startJump] / [method applyGravity]）。

signal hpChanged(currentHp: int)

const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://scene/damage_number.tscn")

@export var hp: int = 100
@export var maxHp: int = 100
@export var attack: int = 10
@export var speed: float = 300.0
## 上下方向（伪 3D 纵深）相对左右的速度系数，清版动作游戏的经典手感
@export var depthSpeedFactor: float = 0.6
## 空中移动的控制系数，越小越「笨重」
@export var airControlFactor: float = 0.7
@export var jumpSpeed: float = 500.0
@export var gravity: float = 980.0
@export var playerId: Game.PlayId = Game.PlayId.P1
## 可活动范围（世界坐标，size 为零表示不限制）；由关卡 Map 开场统一写入
@export var playBounds: Rect2 = Rect2()
# 该角色的搓招表，在角色场景的 Inspector 里挂 data/combos/ 下的 .tres
@export var combos: Array[ComboDef] = []
# 必杀名 -> 动画名映射，如 { "skill1": "act4" }
@export var skillAnims: Dictionary = {}

# 朝向：1 朝右，-1 朝左；控制贴图翻转与 hitBox 偏移
var faceDir: int = 1
var vec: Vector2 = Vector2.ZERO
var inAir: bool = false
var zVec: float = 0.0
var invincible: bool = false
var keyMapPrefix: String = "p1"

@onready var bodyNode: Node2D = $body
@onready var ani: AnimatedSprite2D = $body/ani
@onready var hitBoxNode: Area2D = $body/hitBox
@onready var hurtBoxNode: Area2D = $body/hurtBox
@onready var stateMachineNode: StateMachine = $stateMachine
@onready var player: AnimationPlayer = $player
@onready var tree: AnimationTree = $tree

# AnimationTree 状态机播放控制器，buildAnimations 之后可用
var playback: AnimationNodeStateMachinePlayback
# 承载攻击框横向偏移的节点与偏移量：偏移可能写在 Area2D 自身，也可能写在其碰撞形状子节点上
var hitBoxOffsetNode: Node2D
var hitBoxBaseX: float = 0.0

func _ready() -> void:
	keyMapPrefix = "p%d" % (int(playerId) + 1)
	setupHitBoxOffset()
	# hurtBox 只被检测，不主动扫描别人
	hurtBoxNode.monitoring = false
	hitBoxNode.area_entered.connect(onHitBoxAreaEntered)
	setHitBoxEnabled(false)
	buildAnimations()

# 子类返回动画覆盖表（fps/loop/hitWindow），见 AnimBuilder
func getMoveOverrides() -> Dictionary:
	return {}


func buildAnimations() -> void:
	# 场景已配置状态机（编辑器工具生成并挂接的 .tres）则直接取用；
	# 未配置的角色（敌人初建、尚未接线）由 AnimBuilder 运行时兜底构建
	var configured: bool = tree.tree_root != null \
			and not tree.tree_root.get_node_list().is_empty()
	if configured:
		tree.active = true
		playback = tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
	else:
		AnimBuilder.build(self)


# ---------------------------------------------------------------- 动画

func hasAnim(animName: StringName) -> bool:
	return player != null and player.has_animation(animName)


func getAnimLength(animName: StringName) -> float:
	if not hasAnim(animName):
		return 0.0
	return player.get_animation(animName).length


func playAnim(animName: StringName) -> void:
	if playback == null or not hasAnim(animName):
		return
	if playback.get_current_node() != animName:
		playback.start(animName)


# ---------------------------------------------------------------- 朝向

# 攻击框的横向偏移可能写在 Area2D 自身或其碰撞形状子节点上，二者取其一作为翻转基准
func setupHitBoxOffset() -> void:
	hitBoxOffsetNode = hitBoxNode
	hitBoxBaseX = absf(hitBoxNode.position.x)
	if is_zero_approx(hitBoxBaseX) and hitBoxNode.get_child_count() > 0:
		var shape: Node2D = hitBoxNode.get_child(0) as Node2D
		if shape != null and not is_zero_approx(shape.position.x):
			hitBoxOffsetNode = shape
			hitBoxBaseX = absf(shape.position.x)


func setFaceDir(dirX: float) -> void:
	if dirX == 0.0:
		return
	faceDir = 1 if dirX > 0.0 else -1
	ani.flip_h = faceDir < 0
	if hitBoxOffsetNode != null:
		hitBoxOffsetNode.position.x = hitBoxBaseX * faceDir


# 按当前方向输入转向（无横向输入时保持原朝向）
func faceInput() -> void:
	var inputDir: Vector2 = getMoveInput()
	if not is_zero_approx(inputDir.x):
		setFaceDir(inputDir.x)


# ---------------------------------------------------------------- 移动

# 四向输入原始轴值：左(-1)/右(1)、上(-1)/下(1)，未归一化，斜向为 (1,1)
func getMoveInput() -> Vector2:
	return Vector2(
			Input.get_axis("%s_left" % keyMapPrefix, "%s_right" % keyMapPrefix),
			Input.get_axis("%s_up" % keyMapPrefix, "%s_down" % keyMapPrefix))


# 把方向输入换算成速度：上下方向乘纵深系数，斜向因此稍快于直线
func velocityFromInput(inputDir: Vector2, control: float = 1.0) -> Vector2:
	return Vector2(inputDir.x * speed, inputDir.y * speed * depthSpeedFactor) * control


# 读输入 -> 设速度 -> 移动 -> 钳进可活动范围，返回本次输入方向
func moveByInput(control: float = 1.0) -> Vector2:
	var inputDir: Vector2 = getMoveInput()
	vec = velocityFromInput(inputDir, control)
	moveSelf()
	clampToBounds()
	return inputDir


func moveSelf() -> void:
	velocity = vec
	move_and_slide()


func clampToBounds() -> void:
	if playBounds.size == Vector2.ZERO:
		return
	global_position.x = clampf(global_position.x, playBounds.position.x, playBounds.end.x)
	global_position.y = clampf(global_position.y, playBounds.position.y, playBounds.end.y)


# ---------------------------------------------------------------- 伪 Z 轴（跳跃）

func startJump() -> void:
	inAir = true
	zVec = -jumpSpeed


# 施加重力并推进 body 的竖直偏移，落地时归零并返回 true
func applyGravity(delta: float) -> bool:
	zVec += gravity * delta
	bodyNode.position.y += zVec * delta
	if bodyNode.position.y >= 0.0:
		bodyNode.position.y = 0.0
		zVec = 0.0
		inAir = false
		return true
	return false


# ---------------------------------------------------------------- 命中

func setHitBoxEnabled(enabled: bool) -> void:
	hitBoxNode.monitoring = enabled


func takeDamage(amount: int, fromDir: int = 0) -> void:
	if invincible:
		return
	hp = max(hp - amount, 0)
	hpChanged.emit(hp)
	spawnDamageNumber(amount)
	if hp <= 0:
		return
	# fromDir 为出手者朝向：受击者被推向该方向，并转而面向出手者
	stateMachineNode.transition_to("hurtState", { pushDir = fromDir })


func spawnDamageNumber(amount: int) -> void:
	if get_parent() == null:
		return
	var damageNumber: DamageNumber = DAMAGE_NUMBER_SCENE.instantiate()
	get_parent().add_child(damageNumber)
	damageNumber.global_position = global_position + Vector2(randf_range(-8.0, 8.0), -30.0)
	damageNumber.setup(amount)


func onHitBoxAreaEntered(area: Area2D) -> void:
	var target: FightObject = area.owner as FightObject
	if target == null or target == self:
		return
	target.takeDamage(attack, faceDir)
