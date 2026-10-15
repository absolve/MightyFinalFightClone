extends Node2D
class_name DamageNumber
## 伤害飘字：在受击位置生成，向上飘出并淡出后自释放。
##
## 由 [method FightObject.takeDamage] 生成。用法：先 add_child 再 [method setup]，
## 飘字动画在 _ready 中启动，数值由 setup 填入。

const RISE_DISTANCE: float = 36.0
const LIFE_TIME: float = 0.7

@onready var label: Label = $label


func _ready() -> void:
	var tween: Tween = create_tween()
	tween.set_parallel()
	tween.tween_property(self, "position:y", position.y - RISE_DISTANCE, LIFE_TIME)
	tween.tween_property(self, "modulate:a", 0.0, LIFE_TIME)
	tween.chain().tween_callback(queue_free)


func setup(amount: int) -> void:
	label.text = str(amount)
