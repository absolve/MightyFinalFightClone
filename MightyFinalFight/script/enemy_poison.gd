extends Enemy
class_name EnemyPoison
## 近战杂兵（贴图 sprite/enemy/Enemies_poison_17x1.png）：对应原作敌人类型 3。
##
## 实测数值见 逆向分析.md §12.13/§12.14，已写进本场景的 Inspector：
## 走速 1.00 px/帧（60 px/s）、攻击 ID 11（10）/ 27（14）/ 43（18）随变体递进、
## 命中状态 `85` 第 8 帧、判定距离 dx 28 / dy 0~2。
## 类型 3-6 的 HP 未实测，先按类型 1/2 的 40 取值，待 ROM 补测后改场景即可。
