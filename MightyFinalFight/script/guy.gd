extends "res://script/player.gd"
## Guy：招式动画覆盖表（帧率/循环/命中窗口）。
##
## 贴图来自 sprite/player/Guy_01_13x2.png（站姿/走/跳/翻滚/倒地）与
## Guy_107_13x3.png（攻击/抓取/必杀），切分表见 data/sprites/guy_frames.tres。
## 数值取自逆向文档 12.11：走速 1.46 px/帧、连段 1/5/3、跳攻 5、L0 最大 HP 48。
## hitWindow 必须小于片段时长（帧数/帧率），超出时 AnimBuilder 会收窄并告警。

const MOVE_OVERRIDES: Dictionary = {
	"default": {"fps": 6.0, "loop": true},
	"walk": {"fps": 10.0, "loop": true},
	"jump": {"loop": true},
	"jumpRoll": {"fps": 12.0, "loop": true},
	"fall": {"loop": true},
	"squat": {"loop": true},
	"grap": {"loop": true},
	"wake": {"fps": 8.0, "loop": true},
	"down": {"fps": 6.0, "loop": true},
	"hurt": {"fps": 4.0},
	"act1": {"fps": 12.0, "hitWindow": [0.03, 0.13]},
	"act2": {"fps": 12.0, "hitWindow": [0.03, 0.13]},
	"act3": {"fps": 12.0, "hitWindow": [0.03, 0.15]},
	"squatAttack": {"fps": 12.0, "hitWindow": [0.03, 0.15]},
	"jumpAttack": {"fps": 12.0, "hitWindow": [0.02, 0.07]},
	"jumpKick": {"fps": 12.0, "hitWindow": [0.03, 0.11]},
	"act4": {"fps": 12.0, "hitWindow": [0.08, 0.20]},
	"act5": {"fps": 12.0, "hitWindow": [0.08, 0.20]},
	"act7": {"fps": 12.0, "hitWindow": [0.06, 0.18]},
	"throw": {"fps": 12.0, "hitWindow": [0.08, 0.15]},
}

func getMoveOverrides() -> Dictionary:
	return MOVE_OVERRIDES
