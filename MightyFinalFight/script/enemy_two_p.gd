extends Enemy
class_name EnemyTwoP
## 二段拳杂兵（贴图 sprite/enemy/Enemies_two_p_12x1.png）：对应原作敌人类型 2。
##
## 实测数值见 逆向分析.md §12.12，已写进本场景的 Inspector：
## HP 40、走速 1.00 px/帧（60 px/s）、攻击 ID 2 与 10 各 8 伤、
## 同一次出手命中两段（8~55 帧 与 ≈102 帧）、判定距离 dx 9~25 / dy 0~4。
## 两段命中由 attackState 上的 [EnemyChainedAttackState] 承担，动画接上后自动生效。
