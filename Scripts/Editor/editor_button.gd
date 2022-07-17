extends Button


func _ready():
	connect("pressed", self, "_on_button_pressed")


func _on_button_pressed():
	$"/root/Editor/Core"._on_button_pressed(self.get_path())
