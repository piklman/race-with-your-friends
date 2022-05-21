# Credit: https://www.youtube.com/watch?v=si50G3S1XGU&ab_channel=DawnsCrowGames
extends Node


enum lobby_status {Private, Friends, Public, Invisible}
enum search_distance {Close, Default, Far, Worldwide}


onready var steamName = $SteamName
onready var lobbySetName = $Create/LobbyName
onready var lobbyGetName = $Chat/Name
onready var lobbyOutput = $Chat/MessageList
onready var lobbyPopup = $LobbyPopup
onready var lobbyList = $LobbyPopup/Panel/Scroll/VBox
onready var playerCount = $Players/NoOfPlayers
onready var playerList = $Players/PlayerList
onready var chatInput = $Message/TextEdit


func _ready():
	# Set steam name on screen
	steamName.text = SteamGlobals.STEAM_NAME
	
	# Steamwork Connections
	Steam.connect("lobby_created", self, "_on_Lobby_Created")
	Steam.connect("lobby_match_list", self, "_on_Lobby_Match_List")
	Steam.connect("lobby_joined", self, "_on_Lobbby_Joined")
	Steam.connect("lobby_chat_update", self, "_on_Lobby_Chat_Update")
	Steam.connect("lobby_message", self, "_on_Lobby_Message")
	Steam.connect("lobby_data_update", self, "_on_Lobby_Data_Update")
	Steam.connect("join_requested", self, "_on_Lobby_Join_Requested")
	
	#Check for command-line arguments
	check_Command_Line()


## Self-Made Functions


func create_Lobby():
	# Check no other lobbies are running
	if SteamGlobals.LOBBY_ID == 0:
		Steam.createLobby(lobby_status.Public, SteamGlobals.MAX_MEMBERS)


func join_Lobby(lobbyID):
	lobbyPopup.hide()
	
	# Gets value of the "name" key with provided lobbyID
	var name = Steam.getLobbyData(lobbyID, "name")
	display_Message("Joining lobby " + str(name) + "...")
	
	# Clear prev. lobby members lists
	SteamGlobals.LOBBY_MEMBERS.clear()
	
	# Steam join request
	Steam.joinLobby(lobbyID)	


func get_Lobby_Members():
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


func add_Player_List(steam_id, steam_name):
	# Add players to list
	SteamGlobals.LOBBY_MEMBERS.append({"steam_id" : steam_id, "steam_name" : steam_name})
	# Ensure list is cleared
	playerList.clear()
	# Populate player list
	for MEMBER in SteamGlobals.LOBBY_MEMBERS:
		playerList.add_text(str(MEMBER['steam_name']) + "\n")


func display_Message(message):
	# Adds a new message to the chat box.
	lobbyOutput.add_text("\n" + str(message))


## Steam Callbacks


func _on_Lobby_Created(connect, lobbyID):
	if connect == 1:
		# Set Lobby ID
		SteamGlobals.LOBBY_ID = lobbyID
		
		# Equivalent of printing into the chatbox
		display_Message("Created lobby: " + lobbySetName.text)
		
		# Set Lobby Data (Params are key value pairs after lobbyID)
		Steam.setLobbyData(lobbyID, "name", lobbySetName.text)
		var name = Steam.getLobbyData(lobbyID, "name")
		lobbyGetName.text = str(name)


func _on_Lobby_Joined(lobbyID, perms, locked, response):
	# Set lobby ID
	SteamGlobals.LOBBY_ID = lobbyID
	
	# Get lobby name
	var name = Steam.getLobbyData(lobbyID, "name")
	lobbyGetName.text = str(name)
	
	# Get lobby members
	get_Lobby_Members()


func _on_Lobby_Join_Requested(lobbyID, friendID):
	# Callback occurs when attempting to join via Steam overlay
	
	# Get lobby owner's name
	var OWNER_NAME = Steam.getFriendPersonaName(friendID)
	display_Message("Joining " + str(OWNER_NAME) + "'s lobby...")
	
	# Join the lobby
	join_Lobby(lobbyID)


func _on_Lobby_Data_Update(success, lobbyID, memberID, key):
	# Will complain if this callback is not handled
	print("Success: "+str(success)+", Lobby ID: "+str(lobbyID)+", Member ID: "+str(memberID)+", Key: "+str(key))


func _on_Lobby_Chat_Update(lobbyID, changedID, changeMakerID, chatState):
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


func _on_Lobby_Match_List(lobbies):
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


func _on_Leave_pressed():
	pass # Replace with function body.


func _on_Message_pressed():
	pass # Replace with function body.


func _on_Close_pressed():
	lobbyPopup.hide()
