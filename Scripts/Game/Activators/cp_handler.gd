extends Node2D

var checkpoints = []
var last_checkpoint = 0
var count_lap = true
var lap = 1
var lap_count = 3
onready var race_debug = $"/root/Scene/Canvas/Race"


func _ready():
	for child in get_children():
		checkpoints.append(child)
	race_debug.get_node("CheckpointCount").text = "Checkpoint: 0/" + str(len(checkpoints) - 1)


func _process(delta):
	#if Server.ready:
	#	get_tree().call_group("Checkpoints", "on_cp_body_entered")
	pass


func _on_cp_entered(body, cp_name):
	race_debug.get_node("CheckpointCount").text = "Checkpoint: " + cp_name + "/" + str(len(checkpoints) - 1)

	# 0 -> 4 -> 0 is a problem
	if int(cp_name) == 0:
		if count_lap and int(last_checkpoint) == len(checkpoints) - 1:
			if lap < lap_count:
				lap += 1
			elif lap == lap_count:
				print("Race complete.")
		else:
			# Either player went 1 -> 0 or cheated this lap.
			# Don't count this lap, but count the next assuming player behaves.
			count_lap = true
	elif int(cp_name) != int(last_checkpoint) + 1 \
	and int(cp_name) != int(last_checkpoint) \
	and int(cp_name) != int(last_checkpoint) - 1:
		# The player cheated, or the checkpoints are badly designed.
		count_lap = false
	
	race_debug.get_node("LapCount").text = "Lap: " + str(lap) + "/" + str(lap_count)
	last_checkpoint = cp_name
