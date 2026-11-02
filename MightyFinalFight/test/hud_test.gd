extends Node2D
## 临时无头验证：HUD 绑定刷新、伤害飘字生成/上飘/自毁、敌人血条显隐、计时/分数/命数。
## 通过命令行运行：godot --headless res://test/hud_test.tscn，全部 PASS 后自动退出。

const HUD_SCENE: PackedScene = preload("res://scene/ui/hud.tscn")
const CODY_SCENE: PackedScene = preload("res://scene/player/cody.tscn")

var passed: int = 0
var failed: int = 0


func check(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		print("PASS: " + msg)
	else:
		failed += 1
		printerr("FAIL: " + msg)


func litCount(bar: SegmentBar) -> int:
	var count: int = 0
	for segment in bar.segmentNodes:
		if segment.texture == bar.onTexture:
			count += 1
	return count


func findDamageNumber() -> DamageNumber:
	for child in get_children():
		if child is DamageNumber:
			return child
	return null


func _ready() -> void:
	await runTests()
	onTestsFinished()


func onTestsFinished() -> void:
	print("RESULT: %d passed, %d failed" % [passed, failed])
	get_tree().quit(0 if failed == 0 else 1)


func runTests() -> void:
	var hud: Hud = HUD_SCENE.instantiate()
	add_child(hud)
	var codyP1: Player = CODY_SCENE.instantiate()
	codyP1.position = Vector2(240, 240)
	add_child(codyP1)
	var codyP2: Player = CODY_SCENE.instantiate()
	codyP2.playerId = Game.PlayId.P2
	codyP2.position = Vector2(400, 240)
	add_child(codyP2)
	await get_tree().process_frame

	check(hud.playerBar.segmentNodes.size() == 16, "playerBar builds 16 segments")
	check(litCount(hud.playerBar) == 16, "playerBar full at spawn")

	hud.bindPlayer(codyP1)
	await get_tree().process_frame
	check(litCount(hud.playerBar) == 16, "bindPlayer keeps bar full at max hp")

	codyP1.takeDamage(10)
	await get_tree().process_frame
	check(codyP1.hp == codyP1.maxHp - 10, "takeDamage reduces hp by 10")
	check(litCount(hud.playerBar) == 14, "playerBar lights 14 segments after 10 damage")
	var damageNumber: DamageNumber = findDamageNumber()
	check(damageNumber != null, "damage number spawned on hit")
	if damageNumber != null:
		check(damageNumber.label.text == "10", "damage number shows 10")
		var spawnY: float = damageNumber.global_position.y
		await get_tree().create_timer(0.3).timeout
		check(damageNumber.global_position.y < spawnY, "damage number floats upward")
		await get_tree().create_timer(0.9).timeout
		await get_tree().process_frame
		check(not is_instance_valid(damageNumber), "damage number frees itself after anim")

	check(not hud.enemyBar.visible, "enemyBar hidden before boss bound")
	hud.showEnemyBar(codyP2)
	await get_tree().process_frame
	check(hud.enemyBar.visible and hud.enemyLabel.visible, "enemyBar shown after showEnemyBar")
	check(litCount(hud.enemyBar) == 16, "enemyBar full at max hp")

	codyP2.takeDamage(50)
	await get_tree().process_frame
	check(codyP2.hp == codyP2.maxHp - 50, "bound target hp reduced by 50")
	check(litCount(hud.enemyBar) == 4, "enemyBar lights 4 segments at 14/64 hp")

	codyP2.invincible = false
	codyP2.takeDamage(50)
	await get_tree().process_frame
	check(codyP2.hp == 0, "enemy hp reduced to 0")
	check(not hud.enemyBar.visible, "enemyBar hidden when enemy hp reaches 0")

	hud.setLevel(3)
	check(hud.levelLabel.text == "LEVEL 3", "level label shows LEVEL 3")
	hud.setExp(45, 125)
	check(hud.expLabel.text == "EXP 045/125", "exp label shows EXP 045/125")
	hud.setLives(3)
	check(hud.livesLabel.text == "PL ×3", "lives label shows PL x3")
