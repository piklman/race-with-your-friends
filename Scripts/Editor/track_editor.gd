extends CanvasItem

onready var brush = $Sidebar/Brush/Button
onready var rubber = $Sidebar/Rubber/Button
onready var bucket = $Sidebar/Bucket/Button

enum BrushMode {
	BRUSH = 1,
	RUBBER = 2,
	FILL = 3
}

var brush_mode = 0
var tex = ImageTexture.new()


func _ready():
	tex.set("width", 1920)
	tex.set("height", 1080)


func _on_button_pressed(nodepath):
	var node = get_node(nodepath)
	if node == brush:
		brush_mode = BrushMode.BRUSH
	elif node == rubber:
		brush_mode = BrushMode.RUBBER
	elif node == bucket:
		brush_mode = BrushMode.FILL


func _draw():
	if Input.is_action_just_pressed("click") and brush_mode == BrushMode.BRUSH:
		var point = PoolVector2Array( [get_global_mouse_position()] )
		var colour = PoolColorArray( [Color.red] ) # same as above
		draw_primitive(point, colour, PoolVector2Array(), tex) # third argument is UV, disregarded here, used to map texture


func _process(delta):
	update()
