extends Enemy
class_name Boss
## Boss 基类：状态集合直接照搬逆向实测的敌方状态字节（doc/逆向分析.md §12.4/§12.5/§12.7）。
##
## 81 接近、82 抓取压制、83 突进、84 移动攻击、85 跳跃攻击、86 冲撞、87 受击、88 登场，
## 每个状态对应 stateMachine 下的一个同名节点；本作先不接动画，
## 时长、速度、伤害与命中窗口全部取实测值，由计时器驱动。
## 具体 Boss（如 Thrasher）用子场景的 Inspector 覆盖数值差异。

## 横向距离超过它优先冲撞：实测 |dx| > 60
@export var chargeDistance: float = 60.0
## 横向距离小于它改用抓取：实测 |dx| <= 40
@export var grabDistance: float = 40.0
## 冲撞与跳击伤害：攻击 ID 22 -> 18
@export var heavyDamage: int = 18
## 移动攻击伤害：类型 8 的攻击 ID 23 -> 18
@export var strikeDamage: int = 18
## 抓取压制伤害：攻击 ID 31 -> 5
@export var grabDamage: int = 5
## 冲撞速度：实测 1.85 px/帧
@export var chargeSpeed: float = 111.0
## 突进速度：实测 2.2 px/帧
@export var dashSpeed: float = 132.0
## 跳击滞空时长上限：实测 97 帧
@export var jumpAttackTime: float = 1.6
## 两次招式之间的间隔
@export var actionInterval: float = 1.2

var actionCooldownLeft: float = 0.0


# 按实测决策距离挑下一个招式状态；冷却没到返回空名，交给接近状态继续走位
func chooseAction() -> StringName:
	if target == null or actionCooldownLeft > 0.0:
		return &""
	var dx: float = lateralDistance(target)
	var next: StringName
	if dx > chargeDistance:
		next = &"chargeState"
	elif dx > grabDistance:
		var options: Array[StringName] = [&"dashState", &"jumpAttackState", &"attackState"]
		next = options[randi() % options.size()]
	else:
		next = &"grabState"
	actionCooldownLeft = actionInterval
	return next


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	actionCooldownLeft = maxf(actionCooldownLeft - delta, 0.0)
