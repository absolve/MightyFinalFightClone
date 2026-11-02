extends Enemy
class_name EnemyAxl
## 踢击杂兵（贴图 sprite/enemy/Enemies_axl_13x1.png）：对应原作敌人类型 4。
##
## 实测数值见 逆向分析.md §12.13/§12.14，已写进本场景的 Inspector：
## 走速 1.27 px/帧（76 px/s）、攻击 ID 4（10）、命中状态 `85` 第 12 帧、
## 判定距离 dx 12~28 / dy 1。
## 类型 4 另有上段/下段两套：状态 `8B`（ID 48/50，dx 28~31 平打）与
## 状态 `89`（ID 57/59，dy 18~31 打空中）。对空那套需要第二个判定框，
## [FightObject] 目前只有一个 hitBox，留待判定框扩展后再补，这里先只做平打。
