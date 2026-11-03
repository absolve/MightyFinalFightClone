extends Resource
class_name StageData
## 一关的房间清单。
##
## 存的是房间 .tres 的路径而不是 Resource 引用：直接引用会在本资源加载时
## 把所有房间连同敌人场景一次性拉进来，就失去了「逐间加载 + 预加载下一间」的意义。

@export var title: String = ""
@export var roomPaths: Array[String] = []
