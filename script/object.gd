extends KinematicBody2D

export var hp=0   #血量
var invincible=false #是否无敌
var state=null  #状态
var zPos=0  #z轴
var speed=300 #速度
var gravity=980 #重力
var level=0
var attack=0  #攻击力
var vec=Vector2.ZERO #速度
var inAir=false #在空中
var zVec=0 #z轴速度
var keyMapPrefix='p1' #按键前缀 标记那个玩家
var playerId=null

func _ready():
	if playerId==Game.PlayId.p1:
		keyMapPrefix='p1'
	elif playerId==Game.PlayId.p2:
		keyMapPrefix='p2'
	elif playerId==Game.PlayId.p3:
		keyMapPrefix='p3'
	elif playerId==Game.PlayId.p4:
		keyMapPrefix='p4'
