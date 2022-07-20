extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var vehicles = Global.VEHICLE_BASE_STATS.keys()
	var my_vehicle = vehicles[randi() % vehicles.size()]
	var my_player = load("res://Scenes/Vehicles/" + my_vehicle + ".tscn").instance()
	var players = get_node("/root/Scene/Players")
	players.add_child(my_player)
	
	# Spectating an AI:
	#var my_cam = preload("res://Scenes/Cam.tscn").instance()
	#my_cam.name = "CAM_" + str(SteamGlobals.STEAM_ID)
	#var cams = get_node("/root/Scene/Cameras")
	#my_player.add_child(my_cam)
