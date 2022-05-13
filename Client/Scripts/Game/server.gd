extends Node

# Time
var time = 0
var tick_time = 0.02 # Time between ticks

# Network
var active = false

const DEFAULT_IP = "127.0.0.1"
const DEFAULT_PORT = 43110

var network = NetworkedMultiplayerENet.new()

var local_player_id = 0
remotesync var player_info = {}

var char_select = false
var ready = false

var map = null
var checkpoints = null
var total_checkpoints = 0

var my_player = null
var my_vehicle = null
var position_last_update = Vector2.ZERO
var rotation_last_update = 0


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
	local_player_id = get_tree().get_network_unique_id()
	player_info[local_player_id] = {} # Create a dict for me


func _player_connected(id):
	if id != 1 and id != 0:
		# ID 1 is the server. ID 0 is the default for me which is invalid.
		player_info[id] = {} # Create a dict for them
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


remote func update_vehicle(player_id, vehicle):
	# One call of this func per player must be made before the game
	# is preconfigured. Even the local player should update their
	# player_info to reflect this change.
	player_info[player_id]["vehicle"] = vehicle
	#rpc_id(1, "ack_vehicle", local_player_id, player_id)


remote func load_character_select():
	char_select = true # Tell the game to load the char select screen.
	var c_select = load("res://Scenes/CharSelect.tscn").instance()


func _upload_vehicle():
	player_info[local_player_id]["vehicle"] = my_vehicle
	rpc_id(1, "upload_vehicle", local_player_id, my_vehicle)


func _pre_config():
	# Load Scene
	var scene = load("res://Scenes/Scene.tscn").instance()
	get_node("/root").add_child(scene)
	
	# Load the Map
	map = preload("res://Scenes/Maps/The Scorpion Map.tscn").instance()
	var maps = get_node("/root/Scene/Maps")
	maps.add_child(map)
	checkpoints = map.get_node("Checkpoints")
	total_checkpoints = checkpoints.get_child_count()
	
	# Load my Player and Camera
	print(my_vehicle)
	my_player = load("res://Scenes/Vehicles/" + my_vehicle + ".tscn").instance()
	my_player.set_name(str(local_player_id))
	my_player.set_network_master(int(local_player_id))
	var players = get_node("/root/Scene/Players")
	players.add_child(my_player)
	
	var my_cam = preload("res://Scenes/Cam.tscn").instance()
	my_cam.name = "CAM_" + str(local_player_id)
	var cams = get_node("/root/Scene/Cameras")
	cams.add_child(my_cam)
	
	# Load other Players and their Cameras
	for player_id in player_info:
		if player_id != local_player_id:
			var vehicle = player_info[player_id]["vehicle"]
			var player = load("res://Scenes/Vehicles/" + vehicle + ".tscn").instance()
			player.set_name(str(player_id))
			player.set_network_master(int(player_id))
			players.add_child(player)
			
			var cam = preload("res://Scenes/Cam.tscn").instance()
			cam.set_name("CAM_" + str(player_id))
			cams.add_child(cam)
	
	if !active:
		# If singleplayer, we need to manually initiate the next stage.
		_post_config()


remote func pre_configure_game():
	# Configure the game remotely
	get_tree().set_pause(true)
	_pre_config()
	rpc_id(1, "client_loaded", Server.local_player_id)
	get_tree().set_pause(false)


func _post_config():
	ready = true

remote func post_configure_game():
	_post_config()


remote func update_position(player_id, pos):
	if player_id != local_player_id:
		# We don't want to update our correct position with the network's estimated position
		var player = get_node("/root/Scene/Players/" + str(player_id))
		player.position = lerp(player.position, pos, 0.2)


remote func update_rotation(player_id, rot):
	if player_id != local_player_id:
		# We don't want to update our correct rotation with the network's estimated rotation
		var player = get_node("/root/Scene/Players/" + str(player_id))
		
		# Below uses normalised rotations
		player.rotation = lerp_angle(player.rotation, rot, 0.2)


func _process(delta):
	if active:
		time += delta
		if time >= tick_time:
			time = 0
			if my_player != null:
				if my_player.position != position_last_update:
					rpc_id(1, "update_position", local_player_id, my_player.position)
					position_last_update = my_player.position
				if my_player.rotation != rotation_last_update:
					rpc_id(1, "update_rotation", local_player_id, my_player.rotation)
					rotation_last_update = my_player.rotation
