extends "res://script/player.gd"
## Cody：招式动画覆盖表（帧率/循环/命中窗口），由 AnimBuilder 构建片段时使用。
##
## hitWindow 为攻击框开启的时间区间（秒），到点由动画方法轨道开关 hitBox；
## 数值须小于片段时长（帧数/帧率）。

const MOVE_OVERRIDES: Dictionary = {
	"default": {"fps": 6.0, "loop": true},
	"walk": {"fps": 10.0, "loop": true},
	"jump": {"loop": true},
	"squat": {"loop": true},
	"grap": {"loop": true},
	"fall": {"loop": true},
	"down": {"loop": true},
	"hurt": {"fps": 4.0},
	"act1": {"fps": 12.0, "hitWindow": [0.05, 0.15]},
	"act2": {"fps": 12.0, "hitWindow": [0.05, 0.15]},
	"act3": {"fps": 12.0, "hitWindow": [0.10, 0.23]},
	"squatAttack": {"fps": 12.0, "hitWindow": [0.10, 0.23]},
	"jumpAttack": {"fps": 12.0, "hitWindow": [0.03, 0.15]},
	"jumpKick": {"fps": 12.0, "hitWindow": [0.03, 0.15]},
	"act4": {"fps": 14.0, "hitWindow": [0.10, 0.26]},
	"act5": {"fps": 14.0, "hitWindow": [0.20, 0.41]},
	"act7": {"fps": 14.0, "hitWindow": [0.12, 0.26]},
	"act8": {"fps": 14.0, "hitWindow": [0.15, 0.26]},
	"act9": {"fps": 16.0, "hitWindow": [0.12, 0.35]},
	"act10": {"fps": 14.0, "hitWindow": [0.08, 0.20]},
	"act11": {"fps": 14.0, "hitWindow": [0.15, 0.41]},
	"act12": {"fps": 14.0, "hitWindow": [0.05, 0.13]},
	"throw": {"fps": 12.0, "hitWindow": [0.10, 0.15]},
}

func getMoveOverrides() -> Dictionary:
	return MOVE_OVERRIDES
