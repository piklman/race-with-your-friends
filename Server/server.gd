extends Node

var network = NetworkedMultiplayerENet.new()
const PORT = 6007
const MAX_PLAYERS = 4

onready var start_game = $CenterContainer/StartGame
var configured_game = false

remotesync var player_info = {}
remotesync var players_done = []


func _ready():
	_network_init()


func _network_init():
	network.create_server(PORT, MAX_PLAYERS)
	get_tree().set_network_peer(network)
	network.connect("peer_connected", self, "_player_connected")
	network.connect("peer_disconnected", self, "_player_disconnected")


func _player_connected(id):
	#rpc_id(id, "register_player")
	player_info[id] = {}
	print("Player: " + str(id) + " connected")


func _player_disconnected(id):
	print("Player: " + str(id) + " disconnected")


func _connected_ok():
	pass


func _server_disconnected():
	pass


func _connected_fail():
	pass


func _process(delta):
	if start_game.pressed and !configured_game:
		for id in player_info:
			rpc_id(id, "pre_configure_game")
			configured_game = true


remote func client_loaded(id):
	players_done.append(id)
	if len(players_done) == len(player_info):
		for id in player_info:
			rpc_id(id, "post_configure_game")


remote func update_position(id, position):
	player_info[id]["position"] = position
	for id in player_info:
		rpc_id(id, "update_position", id, position)
