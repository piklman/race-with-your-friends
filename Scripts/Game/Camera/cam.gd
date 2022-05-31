extends Camera2D

const DEFAULT_ZOOM = 1
const SCROLL_INC = Vector2(0.1, 0.1)
const SCROLL_MIN = Vector2(0.1, 0.1)
const SCROLL_MAX = Vector2(2, 2)


func _ready():
	zoom = Vector2(DEFAULT_ZOOM, DEFAULT_ZOOM)


func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():			
			# Zoom In
			if event.button_index == BUTTON_WHEEL_UP and zoom - SCROLL_INC > SCROLL_MIN:
				zoom -= SCROLL_INC
				
			# Zoom out
			elif event.button_index == BUTTON_WHEEL_DOWN and zoom + SCROLL_INC < SCROLL_MAX:
				zoom += SCROLL_INC

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# maybe need to check if id == 1?
	position = get_node("../../Players/{id}".format({"id": SteamGlobals.STEAM_ID})).position
