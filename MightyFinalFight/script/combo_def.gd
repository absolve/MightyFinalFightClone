extends Resource
class_name ComboDef
## 单个搓招（必杀）定义：一条 .tres 对应一个输入序列，数据驱动。
##
## 同一必杀有多个输入序列（如 ←拳 / →拳）时，各建一条 .tres 资源。

# 必杀名，用于查 [member skillAnims] 得到实际播放的动画
@export var skillName: StringName = &""
# 时序输入序列，如 [&"right", &"left", &"punch"]
@export var inputs: Array[StringName] = []
# 同长度序列冲突时数字大者优先
@export var priority: int = 0
# 预留：该招允许的最大输入时长（当前由 InputRecorder.bufferWindow 统一约束）
@export var timeWindow: float = 0.4
@export var damage: int = 10
# 消耗自身血量（原作必杀扣血机制，预留）
@export var costHp: int = 0
