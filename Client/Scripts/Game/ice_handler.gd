extends Node2D

var ice_areas_in_contact_with_player = []
var on_ice = false

onready var on_ice_value = $"/root/Scene/Canvas/Stats/Physics/OnIce"


func _process(delta):
	on_ice = len(ice_areas_in_contact_with_player) > 0
	Global.PLAYER_ON_ICE = on_ice
	on_ice_value.text = "On Ice: " + str(on_ice)


func _on_ice_entered(body, name):
	if not (name in ice_areas_in_contact_with_player):
		ice_areas_in_contact_with_player.append(name)


func _on_ice_exited(body, name):
	ice_areas_in_contact_with_player.remove(name)
