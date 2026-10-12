extends EditorScript
## 动画生成工具：打开角色场景（如 cody.tscn），在脚本编辑器点「运行」，
## 按角色脚本的 getMoveOverrides() 重新生成动画库与状态机，
## 存为 res://data/anims/<角色>_library.tres / _state_machine.tres，
## 并挂接到场景的 player/tree 节点上。场景会被标记为未保存，确认后 Ctrl+S。
## 注意：重新生成会覆盖同名 .tres，对片段的手动微调应在保存的场景节点副本上做，
## 或直接把数值改进覆盖表后重跑本工具。

func _run() -> void:
	var target: FightObject = get_scene() as FightObject
	if target == null:
		push_error("当前打开的场景根节点不是 FightObject（请先打开角色场景）")
		return
	var result: Dictionary = AnimBuilder.saveToFiles(target)
	if result.is_empty():
		push_error("该角色未配置 sprite_frames，无法生成动画")
		return
	target.player.set("libraries", {&"": result.library})
	target.tree.anim_player = NodePath("../player")
	target.tree.tree_root = result.stateMachine
	target.tree.active = true
	get_editor_interface().mark_scene_as_unsaved()
	print("已生成 %s / %s 并挂接到 player/tree 节点，保存场景后生效"
			% [result.libraryPath, result.stateMachinePath])
