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
## - 跳跃：起跳、上升 jump / 下落 fall 片段、落地回待机
## - 空中攻击：拳=jumpAttack、下+拳=jumpKick，每次跳跃仅一次
## - 地面三段连击：可取消窗口递进，第 4 拳不再连
## - 蹲击：下+拳
## - 走打与搓招的区分：按住方向出拳=普通攻击，原地出拳才查搓招表
## - 攻击框随朝向翻转
## - 受击：击退、转向、无敌、回待机；空中受击落地不悬空

const CODY_SCENE: PackedScene = preload("res://scene/cody.tscn")
const START_POS: Vector2 = Vector2(320, 380)
const PLAYER_KEYS: Array[String] = [
	"p1_left", "p1_right", "p1_up", "p1_down", "p1_punch", "p1_jump",
]

var checked: int = 0
var failed: int = 0


func _ready() -> void:
	await frames(2)
	print("================ 玩家基本操作测试 ================")
	await testMoveAndFacing()
	await testDepthSpeed()
	await testBounds()
	await testJump()
	await testAirAttack()
	await testGroundCombo()
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
	check(p.global_position.x > x0 + 30.0, "向右移动位移正确（>30px）")
	check(curAnim(p) == &"walk", "移动播放 walk 片段")

	release("p1_right")
	await frames(3)
	check(p.stateMachineNode.currState is IdleState, "松开方向回到 idleState")

	var x1: float = p.global_position.x
	press("p1_left")
	await frames(12)
	check(p.faceDir == -1 and p.ani.flip_h, "向左：faceDir=-1 且贴图翻转")
	check(p.global_position.x < x1 - 30.0, "向左移动位移正确（>30px）")
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
	check(dy > 15.0, "向下移动有位移（纵深方向可走）")
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
	check(curAnim(p) == &"jump", "上升阶段播放 jump 片段")

	# 等待进入下落阶段（zVec 由负转正）
	var guard: int = 0
	while p.zVec < 0.0 and guard < 120:
		await frames(1)
		guard += 1
	check(p.zVec >= 0.0, "跳跃到达顶点后开始下落")
	await frames(1)
	check(curAnim(p) == &"fall", "下落阶段切换 fall 片段")

	guard = 0
	while p.inAir and guard < 240:
		await frames(1)
		guard += 1
	check(not p.inAir, "落地后 inAir=false")
	check(is_zero_approx(p.bodyNode.position.y), "落地后 body 竖直偏移归零")
	await frames(2)
	check(p.stateMachineNode.currState is IdleState, "落地回到 idleState")
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
	check(curAnim(p) == &"jumpAttack", "空中按拳播放 jumpAttack")
	check("jumpAttack" in [curAnim(p)], "空中攻击片段已切换")

	# 空中第二次按拳不再触发（每次跳跃仅一次）
	press("p1_punch")
	await frames(1)
	release("p1_punch")
	await frames(1)
	check(curAnim(p) != &"jumpKick", "空中攻击每跳仅一次，不会改成跳踢")
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
	check(curAnim(p) == &"jumpKick", "空中下+拳播放 jumpKick")
	await despawn(p)


func testGroundCombo() -> void:
	var p: Player = await spawn()
	await tap("p1_punch")
	check(p.stateMachineNode.currState is AttackState, "地面出拳进入 attackState")
	check(curAnim(p) == &"act1", "第一段播放 act1")

	await frames(2)
	await tap("p1_punch")
	await frames(8)
	check(curAnim(p) == &"act2", "可取消窗口内再按拳递进到 act2")

	await tap("p1_punch")
	await frames(8)
	check(curAnim(p) == &"act3", "继续按拳递进到 act3")

	# 第 4 段不存在：等待本段结束应回到待机，而不是卡在攻击状态
	await tap("p1_punch")
	await frames(20)
	check(p.stateMachineNode.currState is IdleState, "三段打完后回到 idleState（不再连段）")
	await despawn(p)


func testSquatAttack() -> void:
	var p: Player = await spawn()
	press("p1_down")
	await frames(2)
	await tap("p1_punch")
	check(curAnim(p) == &"squatAttack", "下+拳播放 squatAttack 蹲击")
	release("p1_down")
	await frames(20)
	check(p.stateMachineNode.currState is IdleState, "蹲击结束回到 idleState")
	await despawn(p)


func testWalkAttack() -> void:
	var p: Player = await spawn()
	# 按住方向出拳 = 走打，不应被搓招表截走
	press("p1_left")
	await frames(6)
	await tap("p1_punch")
	check(p.stateMachineNode.currState is AttackState, "按住方向出拳是普通攻击")
	check(curAnim(p) == &"act1", "走打从 act1 起手")
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
	check(curAnim(p) == &"act5", "skill1 播放 act5 片段")
	await frames(60)
	await despawn(p)


func testHitBoxFlip() -> void:
	var p: Player = await spawn()
	check(p.hitBoxBaseX > 0.0, "识别到攻击框横向偏移量")
	var base: float = p.hitBoxBaseX
	p.setFaceDir(1)
	var rightX: float = p.hitBoxOffsetNode.position.x
	p.setFaceDir(-1)
	var leftX: float = p.hitBoxOffsetNode.position.x
	check(is_equal_approx(rightX, base) and is_equal_approx(leftX, -base),
			"攻击框随朝向翻转到另一侧")
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
	await frames(30)
	check(p.stateMachineNode.currState is IdleState, "受击硬直结束回到 idleState")
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


func frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func spawn() -> Player:
	releaseAll()
	var p: Player = CODY_SCENE.instantiate()
	p.position = START_POS
	add_child(p)
	# 等 AnimationTree 真正开播（首个 start() 有若干帧延迟，见 FightObject.ensureFirstAnimStarted）
	var guard: int = 0
	while guard < 60 and not animPlaying(p):
		await frames(1)
		guard += 1
	InputRecorder.clearBuffer(p.playerId)
	return p


func animPlaying(p: Player) -> bool:
	var node: StringName = p.playback.get_current_node()
	return node != &"" and node != &"Start"


func despawn(p: Player) -> void:
	releaseAll()
	InputRecorder.clearBuffer(p.playerId)
	p.queue_free()
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
