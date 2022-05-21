extends Node2D

var level = 0
onready var race_debug = $"/root/Scene/Canvas/Race"


func _ready():
	race_debug.get_node("StageHeight").text = "Level (Height): 0"


func _process(delta):
	#if Server.ready:
	#	get_tree().call_group("Checkpoints", "on_cp_body_entered")
	pass


func _on_lv_entered(body, lv):
	race_debug.get_node("StageHeight").text = "Level (Height): " + lv
	Global.STAGE_HEIGHT = int(lv)
