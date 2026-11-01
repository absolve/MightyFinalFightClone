extends FightObject
class_name Enemy
## 敌人基类：锁定最近玩家、按横向/纵深距离给出拳判据，并处理死亡。
##
## 与 [Player] 一样继承 [FightObject]，行为由 stateMachine 子树上的状态节点驱动；
## 敌人状态直接继承 [State]，不掺玩家专属逻辑。
## 具体招式数值与动画参数在子类脚本与场景 Inspector 里配置。

## 关卡用来统一写入可活动范围的节点分组
const GROUP: StringName = &"enemies"

## 横向出拳判定距离（世界像素）：原作类型 1 杂兵命中距离 dx 21~22
@export var attackRange: float = 22.0
## 纵深允许误差：原作命中要求 dy 0~1，即基本站在同一条地面线上
@export var depthTolerance: float = 12.0
## 超过该横向距离不再锁定玩家，避免半张地图的敌人一起跟着跑
@export var aggroRange: float = 260.0
## 两次出拳之间的间隔
@export var attackCooldown: float = 0.8
## 本敌人拳伤：原作类型 1 杂兵攻击 ID 1 → 伤害 4
@export var punchDamage: int = 4

var target: FightObject
var attackCooldownLeft: float = 0.0


func _ready() -> void:
	super._ready()
	add_to_group(GROUP)


# 冷却与目标维护放在本体，状态节点只关心「现在做什么」
func _physics_process(delta: float) -> void:
	attackCooldownLeft = maxf(attackCooldownLeft - delta, 0.0)
	if not isInstanceAlive(target):
		target = null
		findTarget()


func findTarget() -> FightObject:
	var nearest: FightObject = null
	var bestDist: float = aggroRange
	for node in get_tree().get_nodes_in_group(Player.GROUP):
		var candidate: FightObject = node as FightObject
		if not isInstanceAlive(candidate):
			continue
		var dist: float = lateralDistance(candidate)
		if dist <= bestDist:
			bestDist = dist
			nearest = candidate
	target = nearest
	return nearest


static func isInstanceAlive(candidate: FightObject) -> bool:
	return candidate != null and is_instance_valid(candidate) and candidate.hp > 0


func lateralDistance(other: FightObject) -> float:
	return absf(other.global_position.x - global_position.x)


func depthDistance(other: FightObject) -> float:
	return absf(other.global_position.y - global_position.y)


# 指向目标的横向/纵深方向（-1/0/1），追击时按系数换算成速度
func directionTo(other: FightObject) -> Vector2:
	return Vector2(signf(other.global_position.x - global_position.x),
			signf(other.global_position.y - global_position.y))


func faceTarget() -> void:
	if target != null:
		setFaceDir(signf(target.global_position.x - global_position.x))


# 够得着、站得齐、冷却好了才出拳
func canAttack() -> bool:
	return attackCooldownLeft <= 0.0 and inAttackPose()


# 已在出拳位置上（不看冷却）：追击状态据此停止贴脸挤压，改播守卫动画
func inAttackPose() -> bool:
	return target != null and lateralDistance(target) <= attackRange \
			and depthDistance(target) <= depthTolerance


func startAttackCooldown() -> void:
	attackCooldownLeft = attackCooldown


# 敌人被打死：交给 downState 播倒下并移除，之后靠 invincible 挡住重复伤害
func takeDamage(amount: int, fromDir: int = 0) -> void:
	super(amount, fromDir)
	if hp <= 0:
		stateMachineNode.transition_to("downState")
