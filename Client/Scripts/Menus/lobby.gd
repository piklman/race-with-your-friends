extends Node2D

onready var localPlayerID = get_node("LocalPlayerID")

func _ready():
	Server._join_network() # Must be first, as this sets the local player ID.
	localPlayerID.text = "LocalPlayerID:\n" + str(Server.local_player_id)


func _process(delta):
	if Server.char_select:
		var char_sel = load("res://Scenes/CharSelect.tscn").instance()
		get_node("/root").add_child(char_sel)
		self.queue_free()
