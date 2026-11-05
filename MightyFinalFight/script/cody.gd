extends "res://script/player.gd"
## Cody：招式动画覆盖表（帧率/循环/命中窗口），由 AnimBuilder 构建片段时使用。
##
## 动画名清单与每段该用哪几帧贴图见 doc/玩家动画配置表.md §3.2。
## hitWindow 为攻击框开启的时间区间（秒），到点由动画方法轨道开关 hitBox；
## 数值须小于片段时长（帧数/帧率）。

const MOVE_OVERRIDES: Dictionary = {
	"default": {"fps": 6.0, "loop": true},
	"walk": {"fps": 10.0, "loop": true},
	"jump": {"loop": true},
	# 翻滚跳（按住方向起跳）与直落（未按方向）是两套贴图
	"jumpRoll": {"fps": 12.0, "loop": true},
	"fall": {"loop": true},
	"squat": {"loop": true},
	"grap": {"loop": true},
	"wake": {"fps": 8.0},
	# down 是一次性倒地片段，播完由倒地状态计时，不能循环
	"down": {"fps": 6.0},
	"hurt": {"fps": 4.0},
	"act1": {"fps": 12.0, "hitWindow": [0.03, 0.13]},
	"act2": {"fps": 12.0, "hitWindow": [0.03, 0.13]},
	"act3": {"fps": 12.0, "hitWindow": [0.03, 0.15]},
	"squatAttack": {"fps": 12.0, "hitWindow": [0.03, 0.07]},
	"jumpAttack": {"fps": 12.0, "hitWindow": [0.02, 0.07]},
	"jumpKick": {"fps": 12.0, "hitWindow": [0.03, 0.07]},
	"act4": {"fps": 14.0, "hitWindow": [0.10, 0.20]},
	"act5": {"fps": 14.0, "hitWindow": [0.20, 0.41]},
	"act7": {"fps": 14.0, "hitWindow": [0.05, 0.13]},
	"throw": {"fps": 12.0, "hitWindow": [0.10, 0.15]},
}

func getMoveOverrides() -> Dictionary:
	return MOVE_OVERRIDES
