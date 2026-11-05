extends "res://script/player.gd"
## Haggar：招式动画覆盖表（帧率/循环/命中窗口）。
##
## 贴图来自 sprite/player/Haggar_*.png 的 48x48 帧条（行号 2/42/98/145/190/237/277/312），
## 切分表见 data/sprites/haggar_frames.tres。
## 数值取自逆向文档 12.11：走速 1.14 px/帧（最慢）、连段 6/4/10、跳攻 10、L0 最大 HP 80。
## hitWindow 必须小于片段时长（帧数/帧率），超出时 AnimBuilder 会收窄并告警。

const MOVE_OVERRIDES: Dictionary = {
	"default": {"fps": 6.0, "loop": true},
	"walk": {"fps": 8.0, "loop": true},
	"jump": {"loop": true},
	"jumpRoll": {"fps": 10.0, "loop": true},
	"fall": {"loop": true},
	"squat": {"loop": true},
	"grap": {"loop": true},
	"wake": {"fps": 8.0},
	"down": {"fps": 6.0},
	"hurt": {"fps": 4.0},
	"act1": {"fps": 10.0, "hitWindow": [0.05, 0.16]},
	"act2": {"fps": 10.0, "hitWindow": [0.05, 0.16]},
	"act3": {"fps": 10.0, "hitWindow": [0.05, 0.17]},
	"squatAttack": {"fps": 10.0, "hitWindow": [0.03, 0.08]},
	"jumpAttack": {"fps": 10.0, "hitWindow": [0.03, 0.09]},
	"jumpKick": {"fps": 10.0, "hitWindow": [0.03, 0.09]},
	"act4": {"fps": 10.0, "hitWindow": [0.05, 0.16]},
	"act5": {"fps": 10.0, "hitWindow": [0.05, 0.16]},
	"act7": {"fps": 10.0, "hitWindow": [0.05, 0.16]},
	"throw": {"fps": 10.0, "hitWindow": [0.08, 0.17]},
}

func getMoveOverrides() -> Dictionary:
	return MOVE_OVERRIDES
