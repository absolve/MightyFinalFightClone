extends EnemyAttackState
class_name EnemyThrowState
## 远程投掷：原作类型 5（El Gado）在同一次出手里掷出飞刀，
## 实测命中时刻 12~56 帧的跨度就是弹体飞行造成的延迟（见 逆向分析.md §12.14）。
##
## 伤害沿用本体的 punchDamage（在 enter 里写进 obj.attack），
## 弹体场景在 Inspector 里挂：敌人侧弹体 collision_layer 取 enemyHitBox、mask 取 player。

## 出手点相对本体的偏移（世界像素，横向会按朝向翻转）
@export var throwOffset: Vector2 = Vector2(14, -6)
@export var projectileScene: PackedScene

var thrown: bool = false


func enter(previousStatePath: String, data: Dictionary = {}) -> void:
	super(previousStatePath, data)
	thrown = false
	# 伤害由弹体结算，本体近战框保持关闭（父类的兜底窗口在这里不适用）
	fallbackHitWindow = Vector2.ZERO


func spawnProjectile() -> void:
	if projectileScene == null or obj.get_parent() == null:
		return
	var projectile: Projectile = projectileScene.instantiate()
	obj.get_parent().add_child(projectile)
	projectile.global_position = obj.global_position \
			+ Vector2(throwOffset.x * obj.faceDir, throwOffset.y)
	projectile.setup(obj.faceDir, obj.attack, obj as FightObject)


func physics_update(delta: float) -> void:
	super(delta)
	if thrown:
		return
	thrown = true
	spawnProjectile()
