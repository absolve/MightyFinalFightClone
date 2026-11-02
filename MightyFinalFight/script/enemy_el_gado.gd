extends Enemy
class_name EnemyElGado
## 掷刀远程兵（贴图 sprite/enemy/Enemies_el_gado_21x1.png）：对应原作敌人类型 5。
##
## 实测数值见 逆向分析.md §12.14，已写进本场景的 Inspector：
## 走速 1.00 px/帧（60 px/s）、攻击 ID 5（12）/ 21（16）在同一次出手里命中两段
## （12~56 帧 与 ≈96~100 帧，跨度就是飞刀飞行造成的延迟）、判定距离 dx 29~31 / dy 0~1。
## 另有状态 `8E`（ID 51/52，dx 15~17）的近身二段，暂未拆出。
##
## 与近战杂兵的差别在场景里配置：idleState 与 chaseState 的 attackStatePath
## 指向 throwState，由 [EnemyThrowState] 掷出敌人侧飞刀弹体。
