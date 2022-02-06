extends Node

# Network
const DEFAULT_IP = "127.0.0.1"
const DEFAULT_PORT = 6007

var network = NetworkedMultiplayerENet.new()
var selected_IP
var selected_port

var local_player_id = 0
remotesync var player_info = {}
var ready = false

var my_player


func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")


func _join_network():
	get_tree().connect("connected_to_server", self, "_connected_ok")
	network.create_client(DEFAULT_IP, DEFAULT_PORT)
	get_tree().set_network_peer(null)
	get_tree().set_network_peer(network)


func _player_connected(id):
	if id != 1:
		# ID 1 is our own default ID, which is not the true ID.
		# We will add our own data later.
		player_info[id] = {}
	print("Player: " + str(id) + " connected")


func _player_disconnected(id):
	player_info.erase(id)
	print("Player: " + str(id) + " disconnected")


func _connected_ok():
	print("Successfully connected to server")


func _connected_fail():
	print("Failed to connect")


func _server_disconnected():
	print("Server disconnected")


remotesync var players_done = []


remote func pre_configure_game():
	print("GOT")
	print("HI")
	# Ensure the game loads once all clients are ready.
	get_tree().set_pause(true)
	
	local_player_id = get_tree().get_network_unique_id()
	
	# We finally know our own ID, so add it to the player info.
	player_info[Server.local_player_id] = {}
	
	# Load Scene
	var scene = load("res://Scenes/Scene.tscn").instance()
	get_node("/root").add_child(scene)
	
	# Load my Player and Camera
	my_player = preload("res://Scenes/Player.tscn").instance()
	my_player.set_name(str(local_player_id))
	my_player.set_network_master(local_player_id)
	var players = get_node("/root/Scene/Players")
	players.add_child(my_player)
	
	var my_cam = preload("res://Scenes/Cam.tscn").instance()
	my_cam.set_name("CAM_" + str(local_player_id))
	var cameras = get_node("/root/Scene/Cameras")
	cameras.add_child(my_cam)
	
	# Load other Players and their Cameras
	for player_id in player_info:
		var player = preload("res://Scenes/Player.tscn").instance()
		player.set_name(str(player_id))
		player.set_network_master(player_id)
		players.add_child(player)
		
		var cam = preload("res://Scenes/Cam.tscn").instance()
		cam.set_name("CAM_" + str(player_id))
		cameras.add_child(cam)
	
	rpc_id(1, "client_loaded", Server.local_player_id)


remote func post_configure_game():
	get_tree().set_pause(false)
	ready = true


func _process(delta):
	if ready:
		rpc_unreliable_id(1, "update_position", int(local_player_id), my_player.position)


remote func update_position(id, position):
	if id != local_player_id:
		get_node("/root/Scene/Players/" + str(id)).position = position
