extends Button

const BrushMode = preload("res://Scripts/Enum/BrushMode.gd")

onready var core = $"/root/Editor/Core"


func _on_None_pressed():
	core._on_button_pressed(BrushMode.BrushMode.NONE)

func _on_Brush_pressed():
	core._on_button_pressed(BrushMode.BrushMode.BRUSH)
	
func _on_Rubber_pressed():
	print("HI")
	core._on_button_pressed(BrushMode.BrushMode.RUBBER)
	
func _on_Bucket_pressed():
	core._on_button_pressed(BrushMode.BrushMode.BUCKET)
