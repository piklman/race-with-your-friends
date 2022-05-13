extends Node


func _ready():
	connect("button_down", self, "_on_pressed")


func _on_pressed():
	get_parent()._on_button_pressed(get_child(0).name)
