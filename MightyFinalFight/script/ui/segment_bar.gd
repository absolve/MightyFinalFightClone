extends Node2D
class_name SegmentBar
## NES 风格分段血条：固定数量的红白分段，按剩余血量比例点亮。
##
## 分段贴图取自 HUD 素材图集（亮段=剩余血量，暗段=已损失血量），
## 玩家血条与敌人（Boss）血条复用本控件，通过 [method setRatio] 更新。

@export var segmentCount: int = 16
@export var segmentScale: float = 2.0
@export var onTexture: AtlasTexture
@export var offTexture: AtlasTexture

var segmentNodes: Array[Sprite2D] = []


func _ready() -> void:
	for i in segmentCount:
		var segment: Sprite2D = Sprite2D.new()
		segment.texture = onTexture
		segment.centered = false
		segment.position = Vector2(i * 8.0 * segmentScale, 0.0)
		segment.scale = Vector2(segmentScale, segmentScale)
		add_child(segment)
		segmentNodes.append(segment)
	setRatio(1.0)


func setRatio(ratio: float) -> void:
	var litCount: int = roundi(clampf(ratio, 0.0, 1.0) * segmentCount)
	for i in segmentCount:
		segmentNodes[i].texture = onTexture if i < litCount else offTexture
