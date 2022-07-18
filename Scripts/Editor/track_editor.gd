extends Control

const BrushMode = preload("res://Scripts/Enum/BrushMode.gd")

export (Texture) var texture setget _set_texture
export (Texture) var coloured_texture

onready var brush = $Sidebar/Brush/Button
onready var rubber = $Sidebar/Rubber/Button
onready var bucket = $Sidebar/Bucket/Button

onready var size_modifier = $Sliders/BrushSlider/VSlider
onready var size_display = $Sliders/BrushSlider/Label
onready var colour_modifier = $Sliders/ColourSlider/ColorPickerButton

var brush_mode = BrushMode.BrushMode.NONE
var brush_size: int
var colour = Color()
var canvas_texture: ImageTexture
var items_to_draw: Array = []


func _set_texture(value):
	texture = value
	update()


func _on_button_pressed(brush_type):
	brush_mode = brush_type
	
	if brush_mode == BrushMode.BrushMode.RUBBER:
		yield(VisualServer,"frame_post_draw")
		var img = $Viewport.get_viewport().get_texture().get_data()

		img.flip_y()
		img.convert(Image.FORMAT_ETC2_RGBA8)


func _draw():
	if canvas_texture == null:
		yield(VisualServer,"frame_post_draw")
		var img = $Viewport.get_viewport().get_texture().get_data()

		img.flip_y()
		img.convert(Image.FORMAT_RGBA8)
		canvas_texture = ImageTexture.new()
		canvas_texture.create_from_image(img)
	elif !items_to_draw.empty():
		for item in items_to_draw:
			draw_texture_rect(texture, Rect2(item["pos"], Vector2(item["size"], item["size"])), true, item["colour"])
		draw_texture(canvas_texture, Vector2.ZERO)
		yield(VisualServer,"frame_post_draw")
		var img = $Viewport.get_viewport().get_texture().get_data()

		img.flip_y()
		img.convert(Image.FORMAT_RGBA8)
		canvas_texture.create_from_image(img)
	else:
		draw_texture(canvas_texture, Vector2.ZERO)

func _process(delta):
	brush_size = size_modifier.value
	size_display.text = "Brush (" + str(brush_size) + ")"
	colour = colour_modifier.color
	
	if Input.is_action_pressed("click") and brush_mode == BrushMode.BrushMode.BRUSH:
		items_to_draw.append({"pos": get_global_mouse_position(), "size": brush_size, "colour": colour})
		
	elif Input.is_action_pressed("click") and brush_mode == BrushMode.BrushMode.RUBBER:
		items_to_draw.append({"pos": get_global_mouse_position(), "size": brush_size, "colour": Color(0, 0, 0, 0)})
	
	update()
