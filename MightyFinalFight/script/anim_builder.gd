class_name AnimBuilder
## 动画构建器：把角色 SpriteFrames 里的逐帧动画批量转成 AnimationPlayer 片段，
## 并生成 AnimationNodeStateMachine（每动画一状态，代码 start() 切换，无需连线），
## 玩家与敌人共用。
##
## 两条使用路径：
## 1. 编辑器工具（script/editor/anim_build_tool.gd）：生成结果存成
##    res://data/anims/<角色>_library.tres / <角色>_state_machine.tres，
##    挂回场景的 player/tree 节点属性，可在编辑器里直接打开时间轴/状态机面板验证、微调；
## 2. 运行时兜底：场景未配置动画时由 FightObject.buildAnimations 直接构建到节点上。
##
## 每个片段包含：
## - 离散值轨道 body/ani:animation / body/ani:frame（驱动 AnimatedSprite2D 换帧）
## - 可选方法轨道：命中窗口 hitWindow 到点时调用 FightObject.setHitBoxEnabled
##   开关攻击框，为受伤框/攻击框精确判定服务
## 帧率、循环与命中窗口由角色脚本 getMoveOverrides() 按动画名提供。

const DEFAULT_FPS: float = 12.0
const ANIM_SAVE_DIR: String = "res://data/anims/"


# 运行时兜底：直接构建到节点上（不入盘），场景已配置时不会走到这里
static func build(target: FightObject) -> void:
	var spriteFrames: SpriteFrames = target.ani.sprite_frames
	# 场景未配置贴图动画（如尚未接线的角色）时跳过构建
	if spriteFrames == null:
		return
	assignToNodes(target, makeLibrary(spriteFrames, target.getMoveOverrides()),
			makeStateMachine(spriteFrames))


# 生成动画库与状态机并落盘，返回 { library, stateMachine, libraryPath, stateMachinePath }；
# 未配置 sprite_frames 时返回空字典
static func saveToFiles(target: FightObject) -> Dictionary:
	var spriteFrames: SpriteFrames = target.ani.sprite_frames
	if spriteFrames == null:
		return {}
	var library: AnimationLibrary = makeLibrary(spriteFrames, target.getMoveOverrides())
	var machine: AnimationNodeStateMachine = makeStateMachine(spriteFrames)
	var key: String = characterKey(target)
	var libPath: String = "%s%s_library.tres" % [ANIM_SAVE_DIR, key]
	var smPath: String = "%s%s_state_machine.tres" % [ANIM_SAVE_DIR, key]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ANIM_SAVE_DIR))
	ResourceSaver.save(library, libPath)
	ResourceSaver.save(machine, smPath)
	return { library = library, stateMachine = machine,
		libraryPath = libPath, stateMachinePath = smPath }


static func makeLibrary(spriteFrames: SpriteFrames, overrides: Dictionary) -> AnimationLibrary:
	var library: AnimationLibrary = AnimationLibrary.new()
	for animName in spriteFrames.get_animation_names():
		var frameCount: int = spriteFrames.get_frame_count(animName)
		if frameCount == 0:
			continue
		var setting: Dictionary = overrides.get(animName, {})
		library.add_animation(animName, makeClip(animName, frameCount, setting))
	return library


static func makeStateMachine(spriteFrames: SpriteFrames) -> AnimationNodeStateMachine:
	var machine: AnimationNodeStateMachine = AnimationNodeStateMachine.new()
	var index: int = 0
	for animName in spriteFrames.get_animation_names():
		if spriteFrames.get_frame_count(animName) == 0:
			continue
		var stateNode: AnimationNodeAnimation = AnimationNodeAnimation.new()
		stateNode.animation = animName
		# 摆个网格布局，编辑器里打开状态机面板不重叠
		machine.add_node(animName, stateNode,
				Vector2((index % 6) * 200.0, (index / 6) * 100.0))
		index += 1
	return machine


static func assignToNodes(target: FightObject, library: AnimationLibrary,
		machine: AnimationNodeStateMachine) -> void:
	if target.player.has_animation_library(&""):
		target.player.remove_animation_library(&"")
	target.player.add_animation_library(&"", library)
	target.tree.anim_player = NodePath("../player")
	target.tree.tree_root = machine
	target.tree.active = true
	target.playback = target.tree.get("parameters/playback") as AnimationNodeStateMachinePlayback


# 落盘文件名取自角色脚本名（cody.gd → cody），取不到时用节点名
static func characterKey(target: FightObject) -> String:
	var script: Script = target.get_script()
	if script != null and script.resource_path != "":
		return script.resource_path.get_file().get_basename().to_lower()
	return target.name.to_lower()


static func makeClip(animName: StringName, frameCount: int, setting: Dictionary) -> Animation:
	var fps: float = setting.get("fps", DEFAULT_FPS)
	var clip: Animation = Animation.new()
	clip.resource_name = animName
	clip.length = frameCount / fps
	if setting.get("loop", false):
		clip.loop_mode = Animation.LOOP_LINEAR
	var nameTrack: int = clip.add_track(Animation.TYPE_VALUE)
	clip.track_set_path(nameTrack, NodePath("body/ani:animation"))
	clip.value_track_set_update_mode(nameTrack, Animation.UPDATE_DISCRETE)
	clip.track_insert_key(nameTrack, 0.0, animName)
	var frameTrack: int = clip.add_track(Animation.TYPE_VALUE)
	clip.track_set_path(frameTrack, NodePath("body/ani:frame"))
	clip.value_track_set_update_mode(frameTrack, Animation.UPDATE_DISCRETE)
	for i in frameCount:
		clip.track_insert_key(frameTrack, i / fps, i)
	if setting.has("hitWindow"):
		var window: Array = setting["hitWindow"]
		var methodTrack: int = clip.add_track(Animation.TYPE_METHOD)
		clip.track_set_path(methodTrack, NodePath("."))
		clip.track_insert_key(methodTrack, window[0],
				{"method": &"setHitBoxEnabled", "args": [true]})
		clip.track_insert_key(methodTrack, window[1],
				{"method": &"setHitBoxEnabled", "args": [false]})
	return clip
