extends Node
## 玩家基本操作无头回归测试。
##
## 运行：
##   godot --headless --path MightyFinalFight res://test/player_ops_test.tscn
##
## 覆盖范围（全部通过 get_tree().physics_frame 逐帧驱动）：
## - 待机 / 走 / 停：状态下标、朝向、贴图翻转
## - 纵深系数：上下移动比左右慢
## - 关卡边界：移动被 playBounds 钳制
## - 跳跃：未按方向 = 上升 jump / 下落 fall；按住方向 = 翻滚跳 jumpRoll（全程）
## - 空中攻击：拳=jumpAttack、下+拳=jumpKick，每次跳跃仅一次
##   （贴图缺失时按状态机兜底退回 jumpAttack）
## - 地面三段连击：命中确认后才递进，第 3 段后不再连
## - 招式片段可重播：同一段打完再打必须从头再播，状态机不能卡在攻击态
## - 蹲击：下+拳（squatAttack 贴图缺失时按状态机兜底走 act1）
## - 走打与搓招的区分：按住方向出拳=普通攻击，原地出拳才查搓招表
## - 攻击框随朝向翻转（AnimatedShape2D 插件写 Area2D 缩放）
## - 受击：击退、转向、无敌、回待机；空中受击落地不悬空
##
## 时序断言一律轮询（waitNode/waitState/waitIdle）：playback.start() 要下一帧
## 才反映到 get_current_node()，按精确帧数对齐会假失败。

const CODY_SCENE: PackedScene = preload("res://scene/player/cody.tscn")
const START_POS: Vector2 = Vector2(320, 380)
## 靶子与玩家的横向距离：落在攻击框（x 16~32）与受击框（±13）的重叠区内
const DUMMY_DX: float = 26.0
const PLAYER_KEYS: Array[String] = [
	"p1_left", "p1_right", "p1_up", "p1_down", "p1_punch", "p1_jump",
]
## 2d_physics/layer_3="enemy"：玩家攻击框只检测该层，靶子的受击框要挂到这一层才吃得到拳
const ENEMY_LAYER: int = 4

var checked: int = 0
var failed: int = 0
# 连段测试用的靶子，随玩家一起创建与销毁
var dummy: Player = null
# 空中攻击片段播放次数（验「每次跳跃只允许一次空中攻击」）
var airAnimCount: int = 0


func onAirAnimFinished(animName: StringName) -> void:
	if animName == &"jumpAttack":
		airAnimCount += 1


func _ready() -> void:
	await frames(2)
	print("================ 玩家基本操作测试 ================")
	await testMoveAndFacing()
	await testDepthSpeed()
	await testBounds()
	await testJump()
	await testRollJump()
	await testAirAttack()
	await testGroundCombo()
	await testComboStopsWithoutHit()
	await testAttackReplay()
	await testMashPunchNoLock()
	await testSquatAttack()
	await testWalkAttack()
	await testSkillStillWorks()
	await testHitBoxFlip()
	await testHurtKnockback()
	await testAirHurtLands()
	print("=================================================")
	if failed == 0:
		print("✅ 全部 %d 项断言通过" % checked)
	else:
		printerr("❌ %d/%d 项断言失败" % [failed, checked])
	get_tree().quit(0 if failed == 0 else 1)


# ---------------------------------------------------------------- 测试用例

func testMoveAndFacing() -> void:
	var p: Player = await spawn()
	check(p.stateMachineNode.currState is IdleState, "初始进入 idleState")
	check(curAnim(p) == &"default", "待机播放 default 片段")

	var x0: float = p.global_position.x
	press("p1_right")
	await frames(12)
	check(p.stateMachineNode.currState is WalkState, "按住右进入 walkState")
	check(p.faceDir == 1 and not p.ani.flip_h, "向右：faceDir=1 且贴图不翻转")
	# 位移按 speed 换算：12 物理帧 = 0.2 秒，留一半余量给起步与边界
	check(p.global_position.x > x0 + p.speed * 0.1, "向右移动位移与 speed 一致")
	check(curAnim(p) == &"walk", "移动播放 walk 片段")

	release("p1_right")
	await frames(3)
	check(p.stateMachineNode.currState is IdleState, "松开方向回到 idleState")

	var x1: float = p.global_position.x
	press("p1_left")
	await frames(12)
	check(p.faceDir == -1 and p.ani.flip_h, "向左：faceDir=-1 且贴图翻转")
	check(p.global_position.x < x1 - p.speed * 0.1, "向左移动位移与 speed 一致")
	release("p1_left")
	await despawn(p)


func testDepthSpeed() -> void:
	var p: Player = await spawn()
	var x0: float = p.global_position.x
	press("p1_right")
	await frames(12)
	var dx: float = absf(p.global_position.x - x0)
	release("p1_right")
	await frames(3)

	var y0: float = p.global_position.y
	press("p1_down")
	await frames(12)
	var dy: float = absf(p.global_position.y - y0)
	release("p1_down")
	await frames(3)
	check(dy > p.speed * p.depthSpeedFactor * 0.1, "向下移动有位移（纵深方向可走）")
	check(dy < dx, "纵深移动比横向慢（depthSpeedFactor 生效）")
	await despawn(p)


func testBounds() -> void:
	var p: Player = await spawn()
	# 可活动范围右边界 400，玩家从 320 出发向右走 100 帧必定顶到边界
	p.playBounds = Rect2(300, 340, 100, 100)
	press("p1_right")
	await frames(100)
	var reached: float = p.global_position.x
	release("p1_right")
	await frames(2)
	check(reached <= 400.5 and reached > 395.0, "移动被 playBounds 钳制在右边界")
	check(p.global_position.y <= 440.5, "纵深位置同样受 playBounds 钳制")
	await despawn(p)


func testJump() -> void:
	var p: Player = await spawn()
	press("p1_jump")
	await frames(2)
	release("p1_jump")
	check(p.stateMachineNode.currState is JumpState, "按跳进入 jumpState")
	check(p.inAir, "起跳后 inAir=true")

	await frames(6)
	check(p.bodyNode.position.y < 0.0, "起跳后 body 抬离地面（伪 Z 轴上升）")
	check(await waitNode(p, &"jump", 6), "上升阶段播放 jump 片段")

	# 等待进入下落阶段（zVec 由负转正）
	var guard: int = 0
	while p.zVec < 0.0 and guard < 120:
		await frames(1)
		guard += 1
	check(p.zVec >= 0.0, "跳跃到达顶点后开始下落")
	check(await waitNode(p, &"fall", 6), "下落阶段切换 fall 片段")

	guard = 0
	while p.inAir and guard < 240:
		await frames(1)
		guard += 1
	check(not p.inAir, "落地后 inAir=false")
	check(is_zero_approx(p.bodyNode.position.y), "落地后 body 竖直偏移归零")
	check(await waitStateType(p, IdleState, 20), "落地回到 idleState")
	await despawn(p)


# 翻滚跳只在起跳时按住方向才出现，下落段也保持翻滚，不会切回直落片段
func testRollJump() -> void:
	var p: Player = await spawn()
	press("p1_right")
	await frames(2)
	press("p1_jump")
	await frames(2)
	release("p1_jump")
	check(await waitNode(p, &"jumpRoll", 6), "按住方向起跳播放翻滚片段")
	var guard: int = 0
	while p.zVec < 0.0 and guard < 120:
		await frames(1)
		guard += 1
	check(p.zVec >= 0.0, "翻滚跳同样会到达顶点")
	check(await nodeHolds(p, &"jumpRoll", 8), "翻滚跳下落段仍用翻滚片段")
	release("p1_right")
	await despawn(p)


func testAirAttack() -> void:
	var p: Player = await spawn()
	press("p1_jump")
	await frames(2)
	release("p1_jump")
	await frames(4)
	press("p1_punch")
	await frames(1)
	release("p1_punch")
	check(await waitNode(p, &"jumpAttack", 8), "空中按拳播放 jumpAttack")

	# 空中第二次按拳不再触发：整段跳跃里 jumpAttack 只应该播完一次
	airAnimCount = 0
	p.tree.animation_finished.connect(onAirAnimFinished)
	press("p1_punch")
	await frames(1)
	release("p1_punch")
	await frames(30)
	check(airAnimCount == 1, "空中第二次按拳不换片段（每跳仅一次）")
	p.tree.animation_finished.disconnect(onAirAnimFinished)
	await despawn(p)

	# 下+拳 = 跳踢
	p = await spawn()
	press("p1_down")
	press("p1_jump")
	await frames(2)
	release("p1_jump")
	await frames(4)
	press("p1_punch")
	await frames(1)
	release("p1_punch")
	# 下+拳 = 跳踢（jumpKick 贴图缺失时按 jump_state 的兜底走 jumpAttack）
	var kickAnim: StringName = &"jumpKick" if p.hasAnim(&"jumpKick") else &"jumpAttack"
	check(await waitNode(p, kickAnim, 8), "空中下+拳播放跳踢片段")
	await despawn(p)


func testGroundCombo() -> void:
	var p: Player = await spawnWithDummy()
	await tap("p1_punch")
	check(p.stateMachineNode.currState is AttackState, "地面出拳进入 attackState")
	check(await waitNode(p, &"act1", 6), "第一段播放 act1")

	await tap("p1_punch")
	check(await waitNode(p, &"act2", 20), "命中后再按拳递进到 act2")

	await tap("p1_punch")
	check(await waitNode(p, &"act3", 20), "继续按拳递进到 act3")

	# 第 4 段不存在：等待本段结束应回到待机，而不是卡在攻击状态
	await tap("p1_punch")
	check(await waitStateType(p, IdleState, 60), "三段打完后回到 idleState（不再连段）")
	await despawn(p)


# 命中确认：全程没打到人时连段不应递进，且一定能打完回到待机
func testComboStopsWithoutHit() -> void:
	var p: Player = await spawn()
	await tap("p1_punch")
	await tap("p1_punch")
	await tap("p1_punch")
	check(await waitNode(p, &"act1", 6), "空挥不按命中递进，始终停在 act1")
	check(await waitStateType(p, IdleState, 60), "空挥连打仍能回到 idleState")
	await despawn(p)


# 卡死回归：同一段招式打完再打必须重新播起来，状态机不能永远停在攻击态
func testAttackReplay() -> void:
	var p: Player = await spawn()
	for i in 4:
		await tap("p1_punch")
		check(p.stateMachineNode.currState is AttackState, "第 %d 次出拳进入 attackState" % (i + 1))
		check(await waitNode(p, &"act1", 6), "第 %d 次出拳播放 act1" % (i + 1))
		check(await waitAniRestarted(p, &"act1", 2),
				"第 %d 次出拳片段从第 0 帧重播（没沿用上一段残留帧）" % (i + 1))
		check(await waitStateType(p, IdleState, 40), "第 %d 次出拳打完后回到 idleState" % (i + 1))
	await despawn(p)


# 高频连打（原作手感）：停手后必须能回待机，不能锁死在攻击/必杀态
func testMashPunchNoLock() -> void:
	var p: Player = await spawnWithDummy()
	for f in 120:
		pushInput("p1_punch", f % 2 == 0)
		await frames(1)
	pushInput("p1_punch", false)
	check(await waitStateType(p, IdleState, 90), "高频连打停手后回到 idleState（无卡死）")
	check(await waitNode(p, &"default", 10), "卡死回归：停手后播放待机片段")
	await despawn(p)


func testSquatAttack() -> void:
	var p: Player = await spawn()
	press("p1_down")
	await frames(2)
	await tap("p1_punch")
	# squatAttack 贴图缺失时按 attack_state 的兜底走 act1
	var squatAnim: StringName = &"squatAttack" if p.hasAnim(&"squatAttack") else &"act1"
	check(await waitNode(p, squatAnim, 6), "下+拳播放蹲击片段")
	release("p1_down")
	check(await waitStateType(p, IdleState, 60), "蹲击结束回到 idleState")
	await despawn(p)


func testWalkAttack() -> void:
	var p: Player = await spawn()
	# 按住方向出拳 = 走打，不应被搓招表截走
	press("p1_left")
	await frames(6)
	await tap("p1_punch")
	check(p.stateMachineNode.currState is AttackState, "按住方向出拳是普通攻击")
	check(await waitNode(p, &"act1", 6), "走打从 act1 起手")
	check(p.faceDir == -1, "走打保留当前朝向（朝左）")
	release("p1_left")
	await despawn(p)


func testSkillStillWorks() -> void:
	var p: Player = await spawn()
	# 点一下左键再松手，然后原地出拳 → 搓出 skill1（映射到 act5）
	await tap("p1_left")
	await frames(1)
	await tap("p1_punch")
	check(p.stateMachineNode.currState is SkillState, "点方向后原地出拳触发必杀状态")
	check(await waitNode(p, &"act5", 6), "skill1 播放 act5 片段")
	check(await waitStateType(p, IdleState, 90), "必杀播完回到 idleState")
	await despawn(p)


# 攻击框翻转改由 AnimatedShape2D 插件负责（写 hitBox 的 Area2D scale.x），
# FightObject 里的手动偏移在 handle_flip_h=true 时不再介入。
# 插件按 AnimatedSprite2D 的当前片段取形状，所以要在真的出拳（act1）期间验翻转。
func testHitBoxFlip() -> void:
	var p: Player = await spawn()
	check(p.hitBoxOffsetNode == null, "插件接管翻转后不再手动改写攻击框偏移")
	p.setFaceDir(1)
	await tap("p1_punch")
	check(await waitNode(p, &"act1", 6), "朝右出拳播放 act1")
	check(await hitBoxFlipped(p, false, 6), "朝右出拳时攻击框 Area2D 不翻转")
	await waitStateType(p, IdleState, 40)

	p.setFaceDir(-1)
	await tap("p1_punch")
	check(await waitNode(p, &"act1", 6), "朝左出拳播放 act1")
	check(await hitBoxFlipped(p, true, 6), "朝左出拳时攻击框镜像到另一侧")
	await despawn(p)


func testHurtKnockback() -> void:
	var p: Player = await spawn()
	var hp0: int = p.hp
	var x0: float = p.global_position.x
	p.takeDamage(10, 1)
	await frames(2)
	check(p.stateMachineNode.currState is HurtState, "受击进入 hurtState")
	check(p.hp == hp0 - 10, "受击扣除血量")
	check(p.invincible, "受击后短暂无敌")
	check(p.faceDir == -1, "受击后转身面向出手者")
	await frames(8)
	check(p.global_position.x > x0, "受击被沿出手方向击退")
	check(await waitStateType(p, IdleState, 60), "受击硬直结束回到 idleState")
	check(not p.invincible, "硬直结束后解除无敌")
	await despawn(p)


func testAirHurtLands() -> void:
	var p: Player = await spawn()
	press("p1_jump")
	await frames(2)
	release("p1_jump")
	await frames(6)
	check(p.bodyNode.position.y < 0.0, "空中受击前处于浮空状态")
	p.takeDamage(10, 1)
	var guard: int = 0
	while p.inAir and guard < 240:
		await frames(1)
		guard += 1
	check(not p.inAir and is_zero_approx(p.bodyNode.position.y),
			"空中受击后仍会落地，不会悬空")
	await despawn(p)


# ---------------------------------------------------------------- 断言与工具

func check(condition: bool, label: String) -> void:
	checked += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		failed += 1
		printerr("  [FAIL] %s" % label)


func curAnim(p: Player) -> StringName:
	if p.playback == null:
		return &""
	return p.playback.get_current_node()


# 轮询等某个片段成为状态机当前节点（start() 要下一帧才反映到 get_current_node()）
func waitNode(p: Player, animName: StringName, maxFrames: int) -> bool:
	for i in maxFrames:
		if curAnim(p) == animName:
			return true
		await frames(1)
	return curAnim(p) == animName


# 轮询验证片段稳定停在同名上（用于「不该切换」的负向断言）
func nodeHolds(p: Player, animName: StringName, maxFrames: int) -> bool:
	for i in maxFrames:
		if curAnim(p) != animName:
			return false
		await frames(1)
	return curAnim(p) == animName


func waitStateType(p: Player, type: Script, maxFrames: int) -> bool:
	for i in maxFrames:
		if isInstance(p.stateMachineNode.currState, type):
			return true
		await frames(1)
	return isInstance(p.stateMachineNode.currState, type)


func isInstance(node: Object, type: Script) -> bool:
	return node != null and node.get_script() == type


# 一次性片段重播的判据：贴图既已切到该片段，又停在第 0 帧
# （旧实现按 get_current_node() 同名跳过 start()，重播会被挡掉并卡死状态机）
func waitAniRestarted(p: Player, animName: StringName, maxFrames: int) -> bool:
	for i in maxFrames:
		if showingFirstFrameOf(p, animName):
			return true
		await frames(1)
	return showingFirstFrameOf(p, animName)


func showingFirstFrameOf(p: Player, animName: StringName) -> bool:
	return p.ani.animation == animName and p.ani.frame == 0


# AnimatedShape2D 在 _physics_process 写 Area2D 缩放，需要轮询而不是当帧读取
func hitBoxFlipped(p: Player, wantFlipped: bool, maxFrames: int) -> bool:
	for i in maxFrames:
		if (p.hitBoxNode.scale.x < 0.0) == wantFlipped:
			return true
		await frames(1)
	return (p.hitBoxNode.scale.x < 0.0) == wantFlipped


func frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func spawn() -> Player:
	releaseAll()
	var p: Player = CODY_SCENE.instantiate()
	p.position = START_POS
	add_child(p)
	# 等 AnimationTree 真正开播（首个 start() 要若干物理帧才反映到当前节点）
	var guard: int = 0
	while guard < 60 and not animPlaying(p):
		await frames(1)
		guard += 1
	InputRecorder.clearBuffer(p.playerId)
	return p


# 连段带命中确认，需要一个够得着的靶子才能验出 act2/act3
func spawnWithDummy() -> Player:
	var p: Player = await spawn()
	dummy = CODY_SCENE.instantiate()
	dummy.position = p.position + Vector2(DUMMY_DX, 0)
	dummy.playerId = Game.PlayId.P2
	add_child(dummy)
	# onready 取到的框节点要等入树后才有效
	dummy.hurtBoxNode.collision_layer = ENEMY_LAYER
	await frames(4)
	p.setFaceDir(1)
	return p


func animPlaying(p: Player) -> bool:
	var node: StringName = p.playback.get_current_node()
	return node != &"" and node != &"Start"


func despawn(p: Player) -> void:
	releaseAll()
	InputRecorder.clearBuffer(p.playerId)
	p.queue_free()
	if dummy != null:
		dummy.queue_free()
		dummy = null
	await frames(2)


func press(action: String) -> void:
	pushInput(action, true)


func release(action: String) -> void:
	pushInput(action, false)


func pushInput(action: String, pressed: bool) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func releaseAll() -> void:
	for key in PLAYER_KEYS:
		release(key)


# 点按：按下 -> 停 1 帧 -> 松开 -> 停 1 帧，保证 just_pressed 被状态机收到一次
func tap(action: String) -> void:
	press(action)
	await frames(1)
	release(action)
	await frames(1)
