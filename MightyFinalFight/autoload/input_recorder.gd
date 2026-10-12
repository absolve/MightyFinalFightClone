extends Node
## 输入录制单例：按玩家维护输入缓冲，时间戳衰减，供搓招匹配。
##
## 每玩家的输入以「动作名 + 记录时刻」形式存入独立缓冲；
## 超过 [member bufferWindow] 的最旧条目自动剔除（修正旧版 pop_back 方向错误）。

signal inputRecorded(playerId: int, action: StringName)

const DEFAULT_BUFFER_WINDOW: float = 0.5

# 单条输入最长保留时间（秒）
var bufferWindow: float = DEFAULT_BUFFER_WINDOW
# playerId -> Array[InputEntry]
var buffers: Dictionary = {}

func record(playerId: int, action: StringName) -> void:
	if not buffers.has(playerId):
		buffers[playerId] = []
	var buffer: Array = buffers[playerId]
	buffer.append(InputEntry.new(action, Time.get_ticks_msec() / 1000.0))
	inputRecorded.emit(playerId, action)


func getBuffer(playerId: int) -> Array[String]:
	var result: Array[String] = []
	if not buffers.has(playerId):
		return result
	var buffer: Array = buffers[playerId]
	var now: float = Time.get_ticks_msec() / 1000.0
	# 从头部剔除最旧的过期条目
	while buffer.size() > 0 and now - buffer[0].time > bufferWindow:
		buffer.pop_front()
	for entry in buffer:
		result.append(entry.action)
	return result


func clearBuffer(playerId: int) -> void:
	if buffers.has(playerId):
		buffers[playerId].clear()


class InputEntry:
	var action: StringName
	var time: float

	func _init(newAction: StringName, newTime: float) -> void:
		action = newAction
		time = newTime
