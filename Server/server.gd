extends Node

var network = NetworkedMultiplayerENet.new()
const IP_SERVER = "127.0.0.1"
const PORT = 43110
const MAX_PLAYERS = 4
var socketUDP = PacketPeerUDP.new()

onready var start_game = $CenterContainer/StartGame

var player_info = {}
var players_done = {}

var char_select = false
var pre_config = false
var post_config = false

enum PacketType {
	UPDATE_POS = 0,
}


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


remote func upload_vehicle(player_id, vehicle):
	# During the char select menu, all clients all upload their vehicles.
	player_info[player_id]["vehicle"] = vehicle
	for id in player_info:
		rpc_id(id, "update_vehicle", player_id, vehicle)
	players_done["upload_vehicle"].append(player_id)


remote func client_loaded(id):
	# Pre-config
	players_done["client_loaded"].append(id)
	if len(players_done["client_loaded"]) == len(player_info):
		for id in player_info:
			rpc_id(id, "post_configure_game")


remote func update_position(player_id, pos):
	for recipient_id in player_info:
		rpc_id(recipient_id, "update_position", player_id, pos)
	#player_info[player_id]["position"] = pos


remote func update_rotation(player_id, rot):
	for recipient_id in player_info:
		rpc_id(recipient_id, "update_rotation", player_id, rot)
	#player_info[player_id]["rotation"] = rot


func _on_StartGame_pressed():	
	if not char_select:
		for id in player_info:
			rpc_id(id, "load_character_select")
		char_select = true
	
	elif not pre_config:
		for id in player_info:
			rpc_id(id, "pre_configure_game")
