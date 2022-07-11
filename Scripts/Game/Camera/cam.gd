extends Camera2D

const DEFAULT_ZOOM = 1
const SCROLL_INC = Vector2(0.1, 0.1)
const SCROLL_MIN = Vector2(0.1, 0.1)
const SCROLL_MAX = Vector2(2, 2)

var player


func _ready():
	zoom = Vector2(DEFAULT_ZOOM, DEFAULT_ZOOM)
	player = get_parent()
	rotating = true
	var delta_angle = Global._find_vector_angle(transform.x, player.transform.x)
	rotate(-delta_angle)


func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			# Zoom In
			if event.button_index == BUTTON_WHEEL_UP and zoom - SCROLL_INC > SCROLL_MIN:
				zoom -= SCROLL_INC
				
			# Zoom out
			elif event.button_index == BUTTON_WHEEL_DOWN and zoom + SCROLL_INC < SCROLL_MAX:
				zoom += SCROLL_INC
