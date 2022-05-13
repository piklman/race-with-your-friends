extends Node

var scene_loaded = false


func _process(delta):
	if !scene_loaded:
		if $MenuContainer/OnlineButton.pressed:
			Server.active = true
			var lobby = load("res://Scenes/Lobby.tscn").instance()
			get_node("/root").add_child(lobby)
			scene_loaded = true
			self.queue_free()
		elif $MenuContainer/OfflineButton.pressed:
			Server.active = false
			var char_select = load("res://Scenes/CharSelect.tscn").instance()
			get_node("/root").add_child(char_select)
			scene_loaded = true
			self.queue_free()
		elif $MenuContainer/StatsButton.pressed:
			pass
		elif $SettingsButton.pressed:
			pass
		elif $BackButton.pressed:
			var title_screen = load("res://Scenes/TitleScreen.tscn").instance()
			get_node("/root").add_child(title_screen)
			scene_loaded = true
			self.queue_free()
