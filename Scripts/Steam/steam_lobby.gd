extends Node


enum lobby_status {Private, Friends, Public, Invisible}
enum search_distance {Close, Default, Far, Worldwide}
enum send_type {Unreliable, UnreliableNoDelay, Reliable, ReliableNoDelay}


onready var steamName = $SteamName
onready var lobbySetName = $Create/LobbyName
onready var lobbyGetName = $Chat/Name
onready var lobbyOutput = $Chat/MessageList
onready var lobbyPopup = $LobbyPopup
onready var lobbyList = $LobbyPopup/Panel/Scroll/VBox
onready var playerCount = $Players/NoOfPlayers
onready var playerList = $Players/PlayerList
onready var chatInput = $Message/TextEdit

onready var charSelectPopup = $CharSelectPopup
onready var gmSelectPopup = $GMSelectPopup
onready var openCharSelect = $OpenCharSelect
onready var closeCharSelect = $CharSelectPopup/CharSelect/CloseCharSelect

var host: bool = false

var map: Node2D
var checkpoints: Node2D

var time: float = 0
var my_player: Node2D = null
var position_last_update: Vector2 = Vector2.ZERO
var rotation_last_update: int = 0

var lerps: Dictionary = {}

var all_ready: bool = false
var all_pre_configs_complete: bool = false

var local_pre_config_done: bool = false


func _ready():
	# Set steam name on screen
	steamName.text = SteamGlobals.STEAM_NAME
	
	# Steamwork Connections
	Steam.connect("lobby_created", self, "_on_Lobby_Created")
	Steam.connect("lobby_match_list", self, "_on_Lobby_Match_List")
	Steam.connect("lobby_joined", self, "_on_Lobby_Joined")
	Steam.connect("lobby_chat_update", self, "_on_Lobby_Chat_Update")
	Steam.connect("lobby_message", self, "_on_Lobby_Message")
	Steam.connect("lobby_data_update", self, "_on_Lobby_Data_Update")
	Steam.connect("lobby_invite", self, "_on_Lobby_Invite")
	Steam.connect("join_requested", self, "_on_Lobby_Join_Requested")
	Steam.connect("persona_state_change", self, "_on_Persona_Change")
	Steam.connect("p2p_session_request", self, "_on_P2P_Session_Request")
	Steam.connect("p2p_session_connect_fail", self, "_on_P2P_Session_Connect_Fail")
	
	#Check for command-line arguments
	check_Command_Line()


func _process(delta):
	# If the player is connected, read packets
	if SteamGlobals.LOBBY_ID > 0:
		read_All_P2P_Packets()
	
	if SteamGlobals.GAME_STARTED:
		time += 1/(2.5*delta) # Will take 0.025 seconds
		if time >= 1/delta:
			time = 0
			if my_player.position != position_last_update:
				send_P2P_Packet("all", {"position": my_player.position})
				position_last_update = my_player.position
			if my_player.rotation != rotation_last_update:
				send_P2P_Packet("all", {"rotation": my_player.rotation})
				rotation_last_update = my_player.rotation
	
	for player_id in lerps:
		var player = get_node("/root/Scene/Players/" + str(player_id))
		if lerps[player_id].has("position"):
			player.position = lerp(player.position, lerps[player_id]["position"], 0.2)
			
			if player.position.is_equal_approx(lerps[player_id]["position"]):
				lerps[player_id].erase("position")
			
		if lerps[player_id].has("rotation"):
			player.rotation = lerp_angle(player.rotation, lerps[player_id]["rotation"], 0.2)
			
			if is_equal_approx(player.rotation, lerps[player_id]["rotation"]):
				lerps[player_id].erase("rotation")
		
		# Needs to be at the end of this loop (cascading)
		if lerps[player_id] == {}:
			lerps.erase(player_id)


func read_All_P2P_Packets(read_count: int = 0):
	if read_count >= SteamGlobals.PACKET_READ_LIMIT:
		return
	if Steam.getAvailableP2PPacketSize(0) > 0:
		read_P2P_Packet()
		read_All_P2P_Packets(read_count + 1)


## Frequency Functions


func get_random_vehicle():
	var valid_vehicles: Array = Global.VEHICLE_BASE_STATS.keys()
	randomize()
	var vehicle = valid_vehicles[randi() % valid_vehicles.size()]
	return vehicle


## Self-Made Functions


func create_Lobby() -> void:
	# Check no other lobbies are running
	if SteamGlobals.LOBBY_ID == 0:
		Steam.createLobby(lobby_status.Public, SteamGlobals.MAX_MEMBERS)
	host = true


func join_Lobby(lobbyID) -> void:
	lobbyPopup.hide()
	
	# Gets value of the "name" key with provided lobbyID
	var name = Steam.getLobbyData(lobbyID, "name")
	display_Message("Joining lobby " + str(name) + "...")
	
	# Clear prev. lobby members lists
	SteamGlobals.LOBBY_MEMBERS.clear()
	
	# Steam join request
	Steam.joinLobby(lobbyID)


func get_Lobby_Members() -> void:
	# Clear prev. lobby members list
	SteamGlobals.LOBBY_MEMBERS.clear()
	
	# Get number of members in lobby
	var MEMBER_COUNT = Steam.getNumLobbyMembers(SteamGlobals.LOBBY_ID)
	# Update player list count
	playerCount.set_text("Players (" + str(MEMBER_COUNT) + ")")
	
	# Get members data
	for MEMBER in range(0, MEMBER_COUNT):
		# Member's Steam ID
		var MEMBER_STEAM_ID = Steam.getLobbyMemberByIndex(SteamGlobals.LOBBY_ID, MEMBER)
		# Member's Steam Name
		var MEMBER_STEAM_NAME = Steam.getFriendPersonaName(MEMBER_STEAM_ID)
		# Add members to list
		add_Player_List(MEMBER_STEAM_ID, MEMBER_STEAM_NAME)


func add_Player_List(steam_id, steam_name) -> void:
	# Add players to list
	SteamGlobals.LOBBY_MEMBERS.append({"steam_id" : steam_id, "steam_name" : steam_name})
	# Ensure list is cleared
	playerList.clear()
	
	var vehicle = " "
	
	# Populate player list
	for MEMBER in SteamGlobals.LOBBY_MEMBERS:
		
		var text = ""
		
		# Establish player state
		if steam_id == Steam.getLobbyOwner(SteamGlobals.LOBBY_ID):
			text += "(HOST) "
		
		text += MEMBER["steam_name"]
		
		if SteamGlobals.PLAYER_DATA.has(MEMBER["steam_id"]):
			if SteamGlobals.PLAYER_DATA[MEMBER["steam_id"]].has("vehicle"):
				text += " [" + SteamGlobals.PLAYER_DATA[MEMBER["steam_id"]]["vehicle"] + "]"
			if SteamGlobals.PLAYER_DATA[MEMBER["steam_id"]].has("ready"):
				var ready = SteamGlobals.PLAYER_DATA[MEMBER["steam_id"]]["ready"]
				if ready:
					text += " [READY]"
		else:
			SteamGlobals.PLAYER_DATA[MEMBER["steam_id"]] = {"steam_name": MEMBER["steam_name"]}
			
		playerList.add_text(text + "\n")


func send_Chat_Message() -> void:
	# Get chat input
	var MESSAGE = chatInput.text
	
	# If the message is non-empty
	if MESSAGE.length() > 0:
		# Pass message to Steam
		var SENT: bool = Steam.sendLobbyChatMsg(SteamGlobals.LOBBY_ID, MESSAGE)
		
		# Check message sent
		if not SENT:
			display_Message("ERROR: Chat message failed to send.")
	
	# Clear chat input
	chatInput.text = ""


func make_P2P_Handshake() -> void:
	# Sends a P2P handshake to the lobby
	send_P2P_Packet("all", {"message": "handshake"})


func read_P2P_Packet():
	var PACKET_SIZE: int = Steam.getAvailableP2PPacketSize(0)
	var CHANNEL: int = 0
	
	# If there is a packet
	if PACKET_SIZE > 0:
		var PACKET: Dictionary = Steam.readP2PPacket(PACKET_SIZE, CHANNEL)
		
		if PACKET.empty() or PACKET == null:
			print("WARNING: Read an empty packet with non-zero size!")
			
		# Get the remote user's ID
		var PACKET_SENDER: int = PACKET["steam_id_remote"]
		
		# Make the packet readable
		var PACKET_CODE: PoolByteArray = PACKET["data"]
		var READABLE: Dictionary = bytes2var(PACKET_CODE)
		
		# Print the packet to output
		print("Packet: " + str(READABLE))
		
		# Deal with packet data below
		
		## Lobby
		# a "message" packet.
		if READABLE.has("message"):
			print("MESSAGE")
			# Handshake - we send all our data with the newcomer.
			if READABLE["message"] == "handshake":
				var my_data = SteamGlobals.PLAYER_DATA[SteamGlobals.STEAM_ID]
				if my_data.has("vehicle"):
					send_P2P_Packet(str(PACKET_SENDER), {"vehicle": my_data["vehicle"]})
				if my_data.has("ready"):
					send_P2P_Packet(str(PACKET_SENDER), {"ready": my_data["ready"]})
			elif READABLE["message"] == "all_pre_configs_complete":
				_on_All_Pre_Configs_Complete()
		
		
		# a "vehicle" packet.
		if READABLE.has("vehicle"):
			SteamGlobals.PLAYER_DATA[PACKET_SENDER]["vehicle"] = READABLE["vehicle"]
			get_Lobby_Members()
		
		# a "ready" packet. Can assume a steam_id will be provided
		# Note: It is up to the final readier to send an "all_ready" packet.
		if READABLE.has("ready"):
			SteamGlobals.PLAYER_DATA[PACKET_SENDER]["ready"] = READABLE["ready"]
			get_Lobby_Members()
		
		# a "pre_config_complete" packet. Can assume a steam_id will be provided
		# The players pre config one after the other to ensure we can control data in a non-chaotic way.
		# Note: It is up to the final readier to send an "all_pre_configs_complete" message packet.
		if READABLE.has("pre_config_complete"):
			var gets_to_pre_load = false
			if !SteamGlobals.PLAYER_DATA[PACKET_SENDER].has("pre_config_complete"):
				gets_to_pre_load = true
			elif !SteamGlobals.PLAYER_DATA[PACKET_SENDER]["pre_config_complete"]:
				gets_to_pre_load = true
			
			if gets_to_pre_load:
				SteamGlobals.PLAYER_DATA[PACKET_SENDER]["pre_config_complete"] = READABLE["pre_config_complete"]
			
				# Our turn to handle preconfig
				_on_All_Ready()
				
				var all_pre_configs_complete = true
				var ids = SteamGlobals.PLAYER_DATA.keys()
				
				for player_id in ids:
					if SteamGlobals.PLAYER_DATA[player_id].has("pre_config_complete"):
						if SteamGlobals.PLAYER_DATA[player_id]["pre_config_complete"]:
							continue
						else:
							all_pre_configs_complete = false
							break
					else:
						all_pre_configs_complete = false
						break
				
				if all_pre_configs_complete:
					send_P2P_Packet("all", {"message": "all_pre_configs_complete"})
					print("All pre configs complete.")
					_on_All_Pre_Configs_Complete()
		
		# a "bot_vehicle" packet. Will be sent by the host to all clients. Is a Dictionary object.
		if READABLE.has("bot_vehicle"):
			var bot_vehicle: Dictionary = READABLE["bot_vehicle"]
			if !bot_vehicle["name"] in SteamGlobals.BOT_DATA:
				SteamGlobals.BOT_DATA[bot_vehicle["name"]] = {"vehicle": bot_vehicle["vehicle"]}
			else:
				SteamGlobals.BOT_DATA[bot_vehicle["name"]]["vehicle"] = bot_vehicle["vehicle"]
			
			if SteamGlobals.BOT_DATA.size() == SteamGlobals.MAX_MEMBERS - SteamGlobals.PLAYER_DATA.size():
				start_Bot_Config()
				
		
		## In-Game
		# a "position" packet.
		if READABLE.has("position"):
			if PACKET_SENDER != SteamGlobals.STEAM_ID:
				# We don't want to update our correct position with the network's estimated position
				var player = get_node("/root/Scene/Players/" + str(PACKET_SENDER))
				
				if !lerps.has(PACKET_SENDER):
					lerps[PACKET_SENDER] = {}
				lerps[PACKET_SENDER]["position"] = READABLE["position"]
		
		# a "rotation" packet.
		if READABLE.has("rotation"):
			if PACKET_SENDER != SteamGlobals.STEAM_ID:
				# We don't want to update our correct rotation with the network's estimated rotation
				var player = get_node("/root/Scene/Players/" + str(PACKET_SENDER))
				
				if !lerps.has(PACKET_SENDER):
					lerps[PACKET_SENDER] = {}
				lerps[PACKET_SENDER]["rotation"] = READABLE["rotation"]


func send_P2P_Packet(target: String, packet_data: Dictionary) -> void:
	# Assign send_type and channel
	var SEND_TYPE: int = send_type.Reliable
	var CHANNEL: int = 0
	
	# Create a data array to send the data through
	var DATA: PoolByteArray
	DATA.append_array(var2bytes(packet_data))

	# If sending a packet to everyone
	if target == "all":
		# If there is more than one user, send packets
		if SteamGlobals.LOBBY_MEMBERS.size() > 1:
			# Loop through all members that aren't you
			for MEMBER in SteamGlobals.LOBBY_MEMBERS:
				if MEMBER['steam_id'] != SteamGlobals.STEAM_ID:
					Steam.sendP2PPacket(MEMBER['steam_id'], DATA, SEND_TYPE, CHANNEL)

	# Else sending it to someone specific
	else:
		Steam.sendP2PPacket(int(target), DATA, SEND_TYPE, CHANNEL)


func leave_Lobby() -> void:
	# If we are in a lobby, leave it.
	if SteamGlobals.LOBBY_ID != 0:
		display_Message("Leaving lobby...")
		# Send leave request
		Steam.leaveLobby(SteamGlobals.LOBBY_ID)
		# Wipe Lobby ID (to show we aren't in a lobby anymore)
		SteamGlobals.LOBBY_ID = 0
		
		lobbyGetName.text = "Lobby Name"
		playerCount.text = "Players (0)"
		playerList.clear()
		
		# Close any possible sessions with other users
		for MEMBERS in SteamGlobals.LOBBY_MEMBERS:
			Steam.closeP2PSessionWithUser(MEMBERS["steam_id"])
		
		# Clear lobby list
		SteamGlobals.LOBBY_MEMBERS.clear()


func display_Message(message) -> void:
	# Adds a new message to the chat box.
	lobbyOutput.add_text("\n" + str(message))


func start_Pre_Config() -> void:
	if !local_pre_config_done:
		# Load Scene
		var scene = load("res://Scenes/Scene.tscn").instance()
		get_node("/root").add_child(scene)
		
		# Load the Map
		map = load("res://Scenes/Maps/Scorpion/ScorpionMap.tscn").instance()
		var maps = get_node("/root/Scene/Background")
		maps.add_child(map)
		checkpoints = map.get_node("Checkpoints")
		SteamGlobals.NUM_CHECKPOINTS = checkpoints.get_child_count()
		
		# Load my Player and Camera
		var my_vehicle = SteamGlobals.PLAYER_DATA[SteamGlobals.STEAM_ID]["vehicle"]
		my_player = load("res://Scenes/Vehicles/" + my_vehicle + ".tscn").instance()
		my_player.set_name(str(SteamGlobals.STEAM_ID))
		var players = get_node("/root/Scene/Players")
		players.add_child(my_player)
		
		var my_cam = preload("res://Scenes/Cam.tscn").instance()
		my_cam.name = "CAM_" + str(SteamGlobals.STEAM_ID)
		var cams = get_node("/root/Scene/Cameras")
		my_player.add_child(my_cam)
		
		var ids = SteamGlobals.PLAYER_DATA.keys()
		# Load other Players and their Cameras
		
		var num_players = len(ids)
		
		for player_id in ids:
			if int(player_id) != SteamGlobals.STEAM_ID:
				var vehicle = SteamGlobals.PLAYER_DATA[player_id]["vehicle"]
				var player = load("res://Scenes/Vehicles/" + vehicle + ".tscn").instance()
				player.set_name(str(player_id))
				players.add_child(player)
				
				var cam = preload("res://Scenes/Cam.tscn").instance()
				cam.set_name("CAM_" + str(player_id))
				player.add_child(cam)
		
		local_pre_config_done = true
		send_P2P_Packet("all", {"pre_config_complete": true})
		SteamGlobals.PLAYER_DATA[SteamGlobals.STEAM_ID]["pre_config_complete"] = true


func start_Bot_Config() -> void:
	for i in range(SteamGlobals.BOT_DATA.size()):
		var vehicle = SteamGlobals.BOT_DATA["BOT" + str(i)]["vehicle"]
	
		var bot = load("res://Scenes/Vehicles/" + vehicle + ".tscn").instance()
		bot.set_name("BOT" + str(i))
		
		var bots = get_node("/root/Scene/Bots")
		bots.add_child(bot)
		var cam = preload("res://Scenes/Cam.tscn").instance()
		cam.set_name("BOTCAM_" + str(i))
		bot.add_child(cam)


func start_Game() -> void:
	# ! Need to set this to false whenever it ends.
	SteamGlobals.GAME_STARTED = true


## Steam Callbacks


# Lobby (No charselect popup)
func _on_Lobby_Created(connect, lobbyID):
	if connect == 1:
		# Set Lobby ID
		SteamGlobals.LOBBY_ID = lobbyID
		
		# Equivalent of printing into the chatbox
		display_Message("Created lobby: " + lobbySetName.text)
		
		# Make it joinable (this should be done by default anyway)
		Steam.setLobbyJoinable(SteamGlobals.LOBBY_ID, true)
		
		# Set Lobby Data
		Steam.setLobbyData(lobbyID, "name", lobbySetName.text)
		lobbyGetName.text = lobbySetName.text
		
		var RELAY = Steam.allowP2PPacketRelay(true)
		print("Allowing Steam to be relay backup: " + str(RELAY))


func _on_Lobby_Joined(lobbyID, perms, locked, response) -> void:
	# Success
	if response == 1:
		# Set lobby ID
		SteamGlobals.LOBBY_ID = lobbyID
		
		# Get lobby name
		var name = Steam.getLobbyData(lobbyID, "name")
		lobbyGetName.text = str(name)
		
		# Get lobby members
		get_Lobby_Members()
		
		# Make the initial handshake
		make_P2P_Handshake()
	
	# Failure
	else:
		var FAIL_REASON: String
		
		match response:
			2:	FAIL_REASON = "This lobby no longer exists."
			3:	FAIL_REASON = "You don't have permission to join this lobby."
			4:	FAIL_REASON = "The lobby is now full."
			5:	FAIL_REASON = "Uh... something unexpected happened!"
			6:	FAIL_REASON = "You are banned from this lobby."
			7:	FAIL_REASON = "You cannot join due to having a limited account."
			8:	FAIL_REASON = "This lobby is locked or disabled."
			9:	FAIL_REASON = "This lobby is community locked."
			10:	FAIL_REASON = "A user in the lobby has blocked you from joining."
			11:	FAIL_REASON = "A user you have blocked is in the lobby."
		
		# Reopen the lobby list
		_on_Join_pressed()


func _on_Lobby_Join_Requested(lobbyID, friendID) -> void:
	# Callback occurs when attempting to join via Steam overlay
	
	# Get lobby owner's name
	var OWNER_NAME = Steam.getFriendPersonaName(friendID)
	display_Message("Joining " + str(OWNER_NAME) + "'s lobby...")
	
	# Join the lobby
	join_Lobby(lobbyID)


func _on_Lobby_Data_Update(success, lobbyID, memberID, key) -> void:
	# Will complain if this callback is not handled
	print("Success: "+str(success)+", Lobby ID: "+str(lobbyID)+", Member ID: "+str(memberID)+", Key: "+str(key))


func _on_Lobby_Chat_Update(lobbyID, changedID, changeMakerID, chatState) -> void:
	# The user who made the lobby change
	var CHANGER = Steam.getFriendPersonaName(changeMakerID)
	
	# chatState change made
	if chatState == 1:
		display_Message(str(CHANGER) + " has joined the lobby.")
	elif chatState == 2:
		display_Message(str(CHANGER) + " has left the lobby.")
	elif chatState == 4:
		display_Message(str(CHANGER) + " has disconnected from the lobby.")
	elif chatState == 8:
		display_Message(str(CHANGER) + " has been kicked from the lobby.")
	elif chatState == 16:
		display_Message(str(CHANGER) + " has been banned the lobby.")
	else:
		display_Message(str(CHANGER) + " did... something.")
	
	# Update lobby
	get_Lobby_Members()


func _on_Lobby_Match_List(lobbies) -> void:
	# Ensure all lobby buttons from previous searches are deleted
	for child in lobbyList.get_children():
		lobbyList.remove_child(child)
		
	for LOBBY in lobbies:
		# Grab desired lobby data
		var LOBBY_NAME = Steam.getLobbyData(LOBBY, "name")
		
		# Get the current number of members
		var LOBBY_MEMBERS = Steam.getNumLobbyMembers(LOBBY)
		
		# Create button for each lobby
		var LOBBY_BUTTON = Button.new()
		LOBBY_BUTTON.set_text("Lobby " + str(LOBBY) + ": " + str(LOBBY_NAME) + " - " + str(LOBBY_MEMBERS) + " player(s)")
		LOBBY_BUTTON.set_size(Vector2(800, 50))
		LOBBY_BUTTON.set_name("lobby_" + str(LOBBY))
		LOBBY_BUTTON.connect("pressed", self, "join_Lobby", [LOBBY])
		
		# Add lobby to the list
		lobbyList.add_child(LOBBY_BUTTON)


func _on_Lobby_Message(result, user, message, type) -> void:
	# Display the sender and their message
	var SENDER = Steam.getFriendPersonaName(user)
	display_Message(str(SENDER) + ": " + str(message))


func _on_Lobby_Invite():
	pass


func _on_Persona_Change(steam_id: int, flag: int) -> void:
	# A user has had an info change; update the lobby list
	display_Message("Persona change has occurred, lobby list will now refresh.")
	# Update the lobby list
	get_Lobby_Members()


func _on_P2P_Session_Request(remoteID: int) -> void:
	# Get the requester's name
	var REQUESTER: String = Steam.getFriendPersonaName(remoteID)
	
	# Accept the P2P session request
	Steam.acceptP2PSessionWithUser(remoteID)
	
	# Initial handshake
	make_P2P_Handshake()


func _on_P2P_Session_Connect_Fail(steamID: int, session_error: int) -> void:
	# If no error was given
	if session_error == 0:
		print("WARNING: Session failure with "+str(steamID)+" [no error given].")

	# Else if target user was not running the same game
	elif session_error == 1:
		print("WARNING: Session failure with "+str(steamID)+" [target user not running the same game].")

	# Else if local user doesn't own app / game
	elif session_error == 2:
		print("WARNING: Session failure with "+str(steamID)+" [local user doesn't own app / game].")

	# Else if target user isn't connected to Steam
	elif session_error == 3:
		print("WARNING: Session failure with "+str(steamID)+" [target user isn't connected to Steam].")

	# Else if connection timed out
	elif session_error == 4:
		print("WARNING: Session failure with "+str(steamID)+" [connection timed out].")

	# Else if unused
	elif session_error == 5:
		print("WARNING: Session failure with "+str(steamID)+" [unused].")

	# Else no known error
	else:
		print("WARNING: Session failure with "+str(steamID)+" [unknown error "+str(session_error)+"].")


## Other "on" functions


func _on_All_Ready():
	# Initially, only run by the last player to ready up. Then the others are notified in order and they each call this.
	get_tree().set_pause(true)
	start_Pre_Config()
	var ids = SteamGlobals.PLAYER_DATA.keys()
	var num_players = len(ids)
	var num_bots = SteamGlobals.MAX_MEMBERS - num_players
	if host:
		for i in range(num_bots):
			var name = "BOT" + str(i)
			var vehicle = get_random_vehicle()
			if !(name in SteamGlobals.BOT_DATA):
				SteamGlobals.BOT_DATA[name] = {"vehicle": vehicle}
			else:
				SteamGlobals.BOT_DATA[name]["vehicle"] = vehicle
			send_P2P_Packet("all", {"bot_vehicle": {"name": "BOT" + str(i), "vehicle": vehicle}})
		start_Bot_Config()
	get_tree().set_pause(false)


func _on_All_Pre_Configs_Complete():
	get_tree().set_pause(true)
	start_Game()
	get_tree().set_pause(false)


## Command Line Checking


func check_Command_Line():
	var ARGUMENTS = OS.get_cmdline_args()
	
	# Check if detected arguments
	if ARGUMENTS.size() > 0:
		for arg in ARGUMENTS:
			# Invite arg passed
			if SteamGlobals.LOBBY_INVITE_ARG:
				join_Lobby(int(arg))
			
			# Steam connection arg
			if arg == "+connect_lobby":
				SteamGlobals.LOBBY_INVITE_ARG = true


## Button Signal Functions


func _on_Create_pressed():
	create_Lobby()


func _on_Join_pressed():
	lobbyPopup.popup()
	# Set server search distance to worldwide
	Steam.addRequestLobbyListDistanceFilter(search_distance.Worldwide)
	display_Message("Searching for lobbies...")
	
	Steam.requestLobbyList()


func _on_CloseLobbySelect_pressed():
	lobbyPopup.hide()


func _on_Leave_pressed():
	leave_Lobby()


func _on_Message_pressed():
	send_Chat_Message()	


func _on_OpenCharSelect_pressed():
	charSelectPopup.popup()


func _on_CloseCharSelect_pressed():
	charSelectPopup.hide()


func _on_OpenGMSelect_pressed():
	gmSelectPopup.popup()


func _on_CloseGMSelect_pressed():
	gmSelectPopup.hide()


# Lobby (charselect popup)
func _on_Vehicle_Selected(vehicle: String):
	send_P2P_Packet("all", {"vehicle": vehicle})
	SteamGlobals.PLAYER_DATA[SteamGlobals.STEAM_ID]["vehicle"] = vehicle
	# Refresh the lobby as your vehicle has changed.
	get_Lobby_Members()
	charSelectPopup.hide()


func _on_Start_pressed():
	var all_ready = true
	
	if !SteamGlobals.PLAYER_DATA[SteamGlobals.STEAM_ID].has("vehicle"):
		var vehicle = get_random_vehicle()
		SteamGlobals.PLAYER_DATA[SteamGlobals.STEAM_ID]["vehicle"] = vehicle
		send_P2P_Packet("all", {"vehicle": vehicle})
	
	if SteamGlobals.PLAYER_DATA[SteamGlobals.STEAM_ID].has("ready"):
		var ready = SteamGlobals.PLAYER_DATA[SteamGlobals.STEAM_ID]["ready"]
		send_P2P_Packet("all", {"ready": !ready})
		SteamGlobals.PLAYER_DATA[SteamGlobals.STEAM_ID]["ready"] = !ready
		# Refresh the lobby as your readiness has changed.
		get_Lobby_Members()
	else:
		send_P2P_Packet("all", {"ready": true})
		SteamGlobals.PLAYER_DATA[SteamGlobals.STEAM_ID]["ready"] = true
		# Refresh the lobby as your readiness has changed.
		get_Lobby_Members()
	
	for player_id in SteamGlobals.PLAYER_DATA:
		if SteamGlobals.PLAYER_DATA[player_id].has("ready"):
			if SteamGlobals.PLAYER_DATA[player_id].has("vehicle"):
				if SteamGlobals.PLAYER_DATA[player_id]["ready"]:
					continue
				else:
					all_ready = false
					break
			else:
				all_ready = false
				break
		else:
			all_ready = false
			break
	
	if all_ready:
		# Secretly start the preconfig process, then after completing it, notify the others one by one.
		_on_All_Ready()
