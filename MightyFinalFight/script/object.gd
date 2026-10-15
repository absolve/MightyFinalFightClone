extends CharacterBody2D
class_name FightObject
## 战斗对象基类：血量、移动、伪 Z 轴跳跃、朝向与命中盒。
##
## 玩家（继承 [Player]）与敌人、Boss 均继承本类；
## 具体行为由 stateMachine 子树上的状态节点驱动。

signal hpChanged(currentHp: int)

const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://scene/damage_number.tscn")

@export var hp: int = 100
@export var maxHp: int = 100
@export var attack: int = 10
@export var speed: float = 300.0
@export var jumpSpeed: float = 500.0
@export var gravity: float = 980.0
@export var playerId: Game.PlayId = Game.PlayId.P1
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
var hitBoxBaseX: float = 0.0

func _ready() -> void:
	keyMapPrefix = "p%d" % (int(playerId) + 1)
	hitBoxBaseX = absf(hitBoxNode.position.x)
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


func playAnim(animName: StringName) -> void:
	if playback.get_current_node() != animName:
		playback.start(animName)


func setFaceDir(dirX: float) -> void:
	if dirX == 0.0:
		return
	faceDir = 1 if dirX > 0.0 else -1
	ani.flip_h = faceDir < 0
	hitBoxNode.position.x = hitBoxBaseX * faceDir


func moveSelf() -> void:
	velocity = vec
	move_and_slide()


func setHitBoxEnabled(enabled: bool) -> void:
	hitBoxNode.monitoring = enabled


func takeDamage(amount: int) -> void:
	if invincible:
		return
	hp = max(hp - amount, 0)
	hpChanged.emit(hp)
	spawnDamageNumber(amount)
	if hp <= 0:
		return
	stateMachineNode.transition_to("hurtState")


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
	target.takeDamage(attack)
