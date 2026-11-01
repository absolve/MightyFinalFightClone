extends "res://script/enemy.gd"
class_name EnemyPuncher
## 出拳杂兵：贴图来自 sprite/enemy/Sprite-0010_01_14x1.png（14 格单帧，32×32）。
##
## 片段用格（0 基）：default 0-1、walk 2-5、act1 5-6-7（6 是伸拳那格）、
## hurt 8 与 12、down 9-10；11 与 13 暂留作起身/守卫备用。
## 数值取自逆向文档 12.12：类型 1 杂兵 HP 40、走速 1.39 px/帧、拳伤 4、
## 命中发生在攻击状态开始后约 3 帧、判定距离 dx 21~22。

const MOVE_OVERRIDES: Dictionary = {
	"default": {"fps": 6.0, "loop": true},
	"walk": {"fps": 8.0, "loop": true},
	# 伸拳格在 12fps 下是第 0.083~0.167 秒，命中窗口按原作压在它前后
	"act1": {"fps": 12.0, "hitWindow": [0.05, 0.16]},
	"hurt": {"fps": 6.0},
	"down": {"fps": 6.0},
}

func getMoveOverrides() -> Dictionary:
	return MOVE_OVERRIDES
