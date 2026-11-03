extends Control
class_name CharacterSelect
## 选人画面：P1 先选，P2 按自己的键加入后各选一个，双方确认后按 start 开局。
##
## 选择结果写进 Game 单例：关卡按它生成玩家，HUD 按它决定显示几个槽位。
## 原作只有单打，双人是本项目的扩展（doc/原作资料.md §5、后续实现计划.md 阶段 10）。
## 界面节点在代码里搭出来，和 SegmentBar 一样按数据表生成，改角色只动 CARDS。

const STAGE1_SCENE: String = "res://scene/level/stage1.tscn"
const FONT_PATH: String = "res://font/title.tres"
const CARD_SIZE: Vector2 = Vector2(76, 92)
const CARD_GAP: float = 26.0
const PORTRAIT_SCALE: float = 2.0
const CURSOR_COLORS: Array[Color] = [Color(1, 0.85, 0.2, 1), Color(0.35, 0.8, 1, 1)]

# 头像取各角色第一条帧条的首帧（统一 48x48 画幅，与关卡内一致）
const CARDS: Array[Dictionary] = [
	{"texture": "res://sprite/player/Cody_4_6x1.png", "region": Rect2(0, 0, 48, 48)},
	{"texture": "res://sprite/player/Guy_9_6x1.png", "region": Rect2(0, 0, 48, 48)},
	{"texture": "res://sprite/player/Haggar_2_6x1.png", "region": Rect2(0, 0, 48, 48)},
]

const SLOT_ACTIONS: Array[Dictionary] = [
	{"left": "p1_left", "right": "p1_right", "confirm": "p1_punch"},
	{"left": "p2_left", "right": "p2_right", "confirm": "p2_punch"},
]

var p1Index: int = 0
var p2Index: int = 2
var p1Confirmed: bool = false
var p2Joined: bool = false
var p2Confirmed: bool = false

var cardNodes: Array[Control] = []
var cursors: Array[ColorRect] = []
var titleNode: Label
var statusNode: Label
var labelSettings: LabelSettings


func _ready() -> void:
	RenderingServer.set_default_clear_color("#000")
	Game.resetSelection()
	buildLabelSettings()
	buildTitle()
	buildCards()
	buildCursors()
	buildStatus()
	refresh()


func _physics_process(_delta: float) -> void:
	readSlot(0, true)
	readSlot(1, p2Joined)
	if Input.is_action_just_pressed("start") and canStart():
		startStage()
		return
	refresh()


# P2 只要碰自己的任意键就加入，加入后才参与光标轮询；确认后该槽位不再响应
func readSlot(slot: int, active: bool) -> void:
	if not active:
		if slot == 1 and anySlotKeyPressed(1):
			p2Joined = true
		return
	if slotConfirmed(slot):
		return
	var actions: Dictionary = SLOT_ACTIONS[slot]
	if Input.is_action_just_pressed(String(actions["left"])):
		setSlotIndex(slot, getSlotIndex(slot) - 1)
	if Input.is_action_just_pressed(String(actions["right"])):
		setSlotIndex(slot, getSlotIndex(slot) + 1)
	if Input.is_action_just_pressed(String(actions["confirm"])):
		confirmSlot(slot)


func anySlotKeyPressed(slot: int) -> bool:
	var actions: Dictionary = SLOT_ACTIONS[slot]
	for actionName: String in actions.values():
		if Input.is_action_just_pressed(actionName):
			return true
	return Input.is_action_just_pressed("p2_up") or Input.is_action_just_pressed("p2_down") \
			or Input.is_action_just_pressed("p2_jump")


func getSlotIndex(slot: int) -> int:
	return p1Index if slot == 0 else p2Index


func setSlotIndex(slot: int, index: int) -> void:
	var clamped: int = clampi(index, 0, CARDS.size() - 1)
	if slot == 0:
		p1Index = clamped
	else:
		p2Index = clamped


func confirmSlot(slot: int) -> void:
	Game.setSelection(slot, getSlotIndex(slot))
	if slot == 0:
		p1Confirmed = true
	else:
		p2Confirmed = true


func canStart() -> bool:
	return p1Confirmed and (not p2Joined or p2Confirmed)


func startStage() -> void:
	Game.playerCount = 2 if (p2Joined and p2Confirmed) else 1
	get_tree().change_scene_to_file(STAGE1_SCENE)


func slotConfirmed(slot: int) -> bool:
	return p1Confirmed if slot == 0 else p2Confirmed


# ---------------------------------------------------------------- 构建界面

func buildLabelSettings() -> void:
	labelSettings = LabelSettings.new()
	labelSettings.font = load(FONT_PATH)
	labelSettings.font_size = 8
	labelSettings.outline_size = 2
	labelSettings.outline_color = Color(0, 0, 0, 1)
	labelSettings.font_color = Color(1, 1, 1, 1)


func buildTitle() -> void:
	titleNode = makeLabel("SELECT YOUR FIGHTER", Vector2(0, 48))
	titleNode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titleNode.size.x = 640


func buildCards() -> void:
	var rowWidth: float = CARDS.size() * CARD_SIZE.x + (CARDS.size() - 1) * CARD_GAP
	var startX: float = (640.0 - rowWidth) * 0.5
	for index: int in CARDS.size():
		var card: Control = Control.new()
		card.position = Vector2(startX + index * (CARD_SIZE.x + CARD_GAP), 96)
		card.size = CARD_SIZE
		add_child(card)
		var portrait: TextureRect = TextureRect.new()
		var atlas: AtlasTexture = AtlasTexture.new()
		atlas.atlas = load(String(CARDS[index]["texture"]))
		atlas.region = CARDS[index]["region"]
		portrait.texture = atlas
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.size = CARD_SIZE
		card.add_child(portrait)
		var nameNode: Label = makeLabel(Game.characterNames[index], Vector2(0, CARD_SIZE.y - 16))
		nameNode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nameNode.size.x = CARD_SIZE.x
		card.add_child(nameNode)
		cardNodes.append(card)


func buildCursors() -> void:
	for slot: int in CURSOR_COLORS.size():
		var cursor: ColorRect = ColorRect.new()
		cursor.color = CURSOR_COLORS[slot]
		cursor.size = CARD_SIZE + Vector2(8, 8)
		cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(cursor)
		cursors.append(cursor)


func buildStatus() -> void:
	statusNode = makeLabel("", Vector2(0, 300))
	statusNode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	statusNode.size.x = 640


func makeLabel(text: String, corner: Vector2) -> Label:
	var node: Label = Label.new()
	node.text = text
	node.position = corner
	node.label_settings = labelSettings
	add_child(node)
	return node


# ---------------------------------------------------------------- 刷新

func refresh() -> void:
	setCursor(0, p1Index)
	if p2Joined:
		setCursor(1, p2Index)
		cursors[1].visible = true
	else:
		cursors[1].visible = false
	statusNode.text = buildStatusText()


func setCursor(slot: int, index: int) -> void:
	var card: Control = cardNodes[index]
	cursors[slot].position = card.position - Vector2(4, 4)
	cursors[slot].color = CURSOR_COLORS[slot] if slotConfirmed(slot) else Color(1, 1, 1, 0.35)


func buildStatusText() -> String:
	var lines: Array[String] = []
	lines.append("1P %s" % ["PRESS PUNCH" if not p1Confirmed else "READY"])
	if p2Joined:
		lines.append("2P %s" % ["PRESS PUNCH" if not p2Confirmed else "READY"])
	else:
		lines.append("2P PRESS ANY P2 KEY TO JOIN")
	if canStart():
		lines.append("PRESS START")
	return "\n".join(lines)
