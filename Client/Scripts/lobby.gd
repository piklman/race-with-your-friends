extends CanvasLayer

onready var startClient = get_node("StartClient")
onready var localPlayerID = get_node("LocalPlayerID")

var joined_network = false

func _process(delta):
	localPlayerID.text = "LocalPlayerID:\n" + str(Server.local_player_id)
	if startClient.pressed and !joined_network:
		Server._join_network()
		joined_network = true
