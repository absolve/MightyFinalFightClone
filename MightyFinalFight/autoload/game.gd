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
