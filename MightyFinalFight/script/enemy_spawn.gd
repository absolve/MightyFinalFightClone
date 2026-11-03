extends Resource
class_name EnemySpawn
## 房间里的一个刷怪条目：刷哪个敌人、刷在哪、多少血、什么时候出场、怎么进场。
##
## 坐标来自 ROM 波次表（doc/逆向分析.md §12.17），按
## 「x = nes_x * 3、y = 340 + (nes_y - 112) * 1.8」折算成我们的世界坐标后写死在这里。

## 出场时机
enum Trigger {
	ON_ENTRY, ## 进房即刷（可再叠 delay）
	AT_PLAYER_X, ## 玩家推进到 triggerX 才刷
	WHEN_ALIVE_BELOW, ## 场上存活数低于 aliveThreshold 才补这一批
}

## 进场方式
enum EnterFrom {
	PLACED, ## 原地显形
	SCREEN_LEFT, ## 从屏幕左侧场外走进来
	SCREEN_RIGHT, ## 从屏幕右侧场外走进来
}

@export var enemyScene: PackedScene
@export var worldPosition: Vector2 = Vector2.ZERO
## 覆盖场景默认血量；0 表示沿用场景值。原作同一类型在不同记录里 HP 不同，所以血量挂在条目上
@export var hp: int = 0
@export var trigger: Trigger = Trigger.ON_ENTRY
## AT_PLAYER_X 用的世界 X 阈值
@export var triggerX: float = 0.0
## WHEN_ALIVE_BELOW 用的存活数阈值
@export var aliveThreshold: int = 1
## 触发条件成立后再等的秒数
@export var delay: float = 0.0
@export var enterFrom: EnterFrom = EnterFrom.PLACED
## 出场朝向：0 自动面向玩家，±1 强制朝左/朝右
@export var facing: int = 0
