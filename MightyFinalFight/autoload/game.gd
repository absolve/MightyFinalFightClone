extends Node
## 全局单例：跨场景共享的枚举与通用数据。

enum PlayerState {
	IDLE,
	WALK,
	ATTACK,
	HURT,
	HIT_FLYING,
	JUMP,
	SKILL,
}

enum Direction {
	UP,
	DOWN,
	LEFT,
	RIGHT,
}

# 玩家 id，用于输入分桶与按键前缀派生
enum PlayId {
	P1,
	P2,
	P3,
	P4,
}

# 对象类型（待填充）
enum GameObjType {
}

enum CharacterId {
	CODY,
	GUY,
	HAGGAR,
}

## 选人结果：参战人数与各槽位选择的角色（值为 CharacterId）。
## 由选人画面写入，关卡与 HUD 读取；原作只有单打，双人是本项目的扩展。
var playerCount: int = 1
var characterIds: Array[int] = [CharacterId.CODY, CharacterId.GUY]

# Autoload 的枚举值不是编译期常量（见 编码规范 §6.4），所以这几张表只能写 var
var characterScenePaths: Array[String] = [
	"res://scene/player/cody.tscn",
	"res://scene/player/guy.tscn",
	"res://scene/player/haggar.tscn",
]
var characterNames: Array[String] = ["CODY", "GUY", "HAGGAR"]


func selectedScenePath(slot: int) -> String:
	return characterScenePaths[characterIds[slot]]


func setSelection(slot: int, characterId: int) -> void:
	characterIds[slot] = characterId
	playerCount = maxi(playerCount, slot + 1)


func resetSelection() -> void:
	playerCount = 1
	characterIds = [CharacterId.CODY, CharacterId.GUY]
