# Credit: https://www.youtube.com/watch?v=si50G3S1XGU&ab_channel=DawnsCrowGames
extends Node

# Steam Variables
var OWNED = false
var ONLINE = false
var STEAM_ID = 0
var STEAM_NAME = ""

# Lobby Variables
var DATA
var LOBBY_ID = 0
var LOBBY_MEMBERS = []
var LOBBY_INVITE_ARG
var MAX_MEMBERS = 4


func _ready():
	# Initialise steam
	var INIT = Steam.steamInit()
	
	if INIT['status'] != 1:
		# E.g. If user tries to load the game without being signed into Steam
		print("Failed to initialise Steam. " + str(INIT["verbal"]) + " Shutting down...")
		get_tree().quit()
	
	ONLINE = Steam.loggedOn()
	STEAM_ID = Steam.getSteamID()
	STEAM_NAME = Steam.getPersonaName()
	OWNED = Steam.isSubscribed()
	
	if !OWNED:
		print("User doesn't own this game.")
		get_tree().quit()


func _process(delta):
	Steam.run_callbacks()
