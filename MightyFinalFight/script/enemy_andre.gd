extends Enemy
class_name EnemyAndre
## 贴身大块头（贴图 sprite/enemy/Enemies_andre_12x1.png）：对应原作敌人类型 6。
##
## 实测数值见 逆向分析.md §12.13/§12.14，已写进本场景的 Inspector：
## 走速 1.00 px/帧（60 px/s）、攻击 ID 6（10）、命中状态 `80` 第 3~17 帧、
## 判定距离 dx 1~3 / dy 1~7 —— 要求几乎贴到身上才出手，所以 attackRange 压到 6。
## 原作这类体型还有把玩家举起再摔的投技，需要玩家受控状态配合，暂未实现。
