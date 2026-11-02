extends Node
## 出拳杂兵无头回归测试。
##
## 运行：
##   godot --headless --path MightyFinalFight --fixed-fps 60 res://test/enemy_puncher_test.tscn
##
## 覆盖：待机守卫 -> 追击 -> 进入判定距离出拳 -> 玩家掉血 -> 收拳回待机并进冷却；
## 玩家反击命中敌人（受击硬直、扣血）、敌人被打死倒下并被移除。
## 时序断言一律轮询，理由见 player_ops_test.gd 顶部说明。

const CODY_SCENE: PackedScene = preload("res://scene/player/cody.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scene/enemy/enemy_puncher.tscn")
const SPAWN_POS: Vector2 = Vector2(240, 380)
## 首次生成的横向距离：超出 aggroRange(260)，用来先验「无人可打就守卫」
const ENEMY_START_DX: float = 320.0
## 把敌人挪到多近才开始追击
const ENGAGE_DX: float = 90.0

var checked: int = 0
var failed: int = 0
var cody: Player
var enemy: Enemy


func _ready() -> void:
	await frames(2)
	print("================ 出拳杂兵测试 ================")
	await testChaseThenPunch()
	await testPlayerPunchHurt()
	await testEnemyDeath()
	print("=============================================")
	if failed == 0:
		print("✅ 全部 %d 项断言通过" % checked)
	else:
		printerr("❌ %d/%d 项断言失败" % [failed, checked])
	get_tree().quit(0 if failed == 0 else 1)


# ---------------------------------------------------------------- 用例

func testChaseThenPunch() -> void:
	await spawnPair()
	check(enemy.stateMachineNode.currState is EnemyIdleState, "玩家不在 aggroRange：敌人停在 idleState")
	check(curAnim(enemy) == &"default", "守卫时播放 default 片段")
	await frames(10)
	check(distance() > ENEMY_START_DX - 10.0, "锁定不到玩家时不会自己乱走")

	# 挪进 aggroRange 才开始追击
	enemy.global_position = cody.global_position + Vector2(ENGAGE_DX, 0)
	check(await waitState(enemy, EnemyChaseState, 30), "玩家进入 aggroRange -> 追击")
	var dist0: float = distance()
	await frames(20)
	check(distance() < dist0 - 10.0, "追击确实拉近横向距离")
	check(curAnim(enemy) == &"walk", "追击播放 walk 片段")

	check(await waitState(enemy, EnemyAttackState, 180), "进入判定距离后出拳")
	check(curAnim(enemy) == &"act1", "出拳播放 act1 片段")
	var hp0: int = cody.hp
	check(await waitHpDrop(cody, hp0, 90), "命中窗口内玩家掉血")
	check(cody.hp == hp0 - enemy.punchDamage, "玩家扣血量等于 punchDamage")
	check(cody.stateMachineNode.currState is HurtState, "玩家被打后进 hurtState")

	await frames(30)
	check(await waitState(enemy, EnemyIdleState, 60), "收拳后回到 idleState")
	var hp1: int = cody.hp
	await frames(20)
	check(cody.hp == hp1, "冷却期内不会立刻再出一拳")
	await despawnPair()


func testPlayerPunchHurt() -> void:
	await spawnPair()
	# 直接把敌人放到够得着的距离，避免等它走完地图
	enemy.global_position = cody.global_position + Vector2(20, 0)
	# 压住敌人的冷却，否则它会先出一拳把玩家打进硬直、打断玩家攻击框
	enemy.startAttackCooldown()
	cody.setFaceDir(1)
	await frames(2)
	var hp0: int = enemy.hp
	await tap("p1_punch")
	check(await waitNode(cody, &"act1", 6), "玩家出拳播放 act1")
	check(await waitHpDrop(enemy, hp0, 30), "玩家攻击框能命中敌人受击框（层设置正确）")
	check(enemy.hp == hp0 - 2, "敌人扣血 2（轻拳伤害）")
	check(enemy.stateMachineNode.currState is EnemyHurtState, "敌人进 EnemyHurtState")
	check(enemy.faceDir == -1, "敌人受击后转身面向出手者")
	await frames(30)
	check(await waitState(enemy, EnemyIdleState, 60), "敌人硬直结束回到 idleState")
	await despawnPair()


func testEnemyDeath() -> void:
	await spawnPair()
	var hp0: int = enemy.hp
	enemy.takeDamage(hp0, 1)
	check(enemy.hp == 0, "致命伤害把敌人血量清零")
	check(enemy.stateMachineNode.currState is EnemyDownState, "清零后进入 EnemyDownState")
	check(not enemy.hitBoxNode.monitoring, "倒下时关闭攻击框")
	check(await waitNode(enemy, &"down", 6), "倒下播放 down 片段")
	check(await waitFreed(enemy, 120), "倒下动画结束后敌人被移除")
	await despawnPair()


# ---------------------------------------------------------------- 工具

func spawnPair() -> void:
	releaseAll()
	cody = CODY_SCENE.instantiate()
	cody.position = SPAWN_POS
	add_child(cody)
	enemy = ENEMY_SCENE.instantiate()
	enemy.position = SPAWN_POS + Vector2(ENEMY_START_DX, 0)
	add_child(enemy)
	var guard: int = 0
	while guard < 90 and (not animStarted(cody) or not animStarted(enemy)):
		await frames(1)
		guard += 1
	InputRecorder.clearBuffer(cody.playerId)


func despawnPair() -> void:
	releaseAll()
	if is_instance_valid(enemy):
		enemy.queue_free()
	if is_instance_valid(cody):
		cody.queue_free()
	await frames(3)


func animStarted(obj: FightObject) -> bool:
	var node: StringName = obj.playback.get_current_node()
	return node != &"" and node != &"Start"


func curAnim(obj: FightObject) -> StringName:
	return obj.playback.get_current_node() if obj.playback != null else &""


func distance() -> float:
	return absf(enemy.global_position.x - cody.global_position.x)


func waitState(obj: FightObject, type: Script, maxFrames: int) -> bool:
	for i in maxFrames:
		if isSameScript(obj.stateMachineNode.currState, type):
			return true
		await frames(1)
	return isSameScript(obj.stateMachineNode.currState, type)


func isSameScript(node: Object, type: Script) -> bool:
	return node != null and node.get_script() == type


func waitNode(obj: FightObject, animName: StringName, maxFrames: int) -> bool:
	for i in maxFrames:
		if curAnim(obj) == animName:
			return true
		await frames(1)
	return curAnim(obj) == animName


func waitHpDrop(obj: FightObject, hpFrom: int, maxFrames: int) -> bool:
	for i in maxFrames:
		if obj.hp < hpFrom:
			return true
		await frames(1)
	return obj.hp < hpFrom


func waitFreed(obj: Object, maxFrames: int) -> bool:
	for i in maxFrames:
		if not is_instance_valid(obj):
			return true
		await frames(1)
	return not is_instance_valid(obj)


func check(condition: bool, label: String) -> void:
	checked += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		failed += 1
		printerr("  [FAIL] %s" % label)


func frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func tap(action: String) -> void:
	pushInput(action, true)
	await frames(1)
	pushInput(action, false)
	await frames(1)


func pushInput(action: String, pressed: bool) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func releaseAll() -> void:
	for key in ["p1_left", "p1_right", "p1_up", "p1_down", "p1_punch", "p1_jump"]:
		pushInput(key, false)
