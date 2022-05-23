extends KinematicBody2D

### DEBUG

onready var pos_value = get_node("../../Canvas/Stats/Position/PosValue")
onready var pos_button = get_node("../../Canvas/Stats/Position/PosButton")

onready var spd_value = get_node("../../Canvas/Stats/Speed/SpeedValue")
onready var spd_button = get_node("../../Canvas/Stats/Speed/SpeedButton")
onready var spd_0er = get_node("../../Canvas/Stats/Speed/SpeedZeroer")

onready var max_spd_slider = get_node("../../Canvas/Stats/MaxSpeed/MaxSpdSlider")
onready var max_spd_value = get_node("../../Canvas/Stats/MaxSpeed/MaxSpdValue")

onready var acc_slider = get_node("../../Canvas/Stats/Acc/AccSlider")
onready var acc_value = get_node("../../Canvas/Stats/Acc/AccValue")

onready var turn_slider = get_node("../../Canvas/Stats/Turn/TurnSlider")
onready var turn_value = get_node("../../Canvas/Stats/Turn/TurnValue")

onready var e_slider = get_node("../../Canvas/Stats/Physics/CoRSlider")
onready var e_value = get_node("../../Canvas/Stats/Physics/CoRValue")

onready var friction_value = get_node("../../Canvas/Stats/Physics/Friction")

### END DEBUG

# Base friction stat for all vehicles (decreases with offroad)
var moving = false
var friction
var std_friction = 0.8
var ice_friction = 0.4

# Text
export (Color, RGB) var DEBUG_DEFAULT
export (Color, RGB) var DEBUG_WARN

var my_data: Dictionary
var stats: Dictionary
var velocity: Vector2

func _ready():	
	# Variable definition
	friction = std_friction
	
	# Get player data
	my_data = SteamGlobals.PLAYER_DATA[int(name)]
	print(my_data["vehicle"])
	stats = Global.VEHICLE_BASE_STATS[my_data["vehicle"]]
	$PlayerName/Name.text = my_data["steam_name"]
	
	# When moving a kinematic body, you should not set its position directly.
	# Instead, you use the move_and_collide() or move_and_slide() methods.
	# These methods move the body along a given vector, and it will instantly
	# stop if a collision is detected with another body. After the body has
	# collided, any collision response must be coded manually.

	velocity = Vector2.ZERO


func _find_vector_angle(v1, v2):
	if v1 != Vector2.ZERO and v2 != Vector2.ZERO:
		# Cosine rule. Gives result in rads
		var angle = acos(v1.dot(v2) / (v1.length() * v2.length()))
		return angle
	return 0 # If a /0 error would occur, return 0


func _find_vector_direction(v1, v2):
	var direction = 1
	if abs(_find_vector_angle(v1, v2)) >= PI/4:
		direction = -1
	return direction


func _process(delta):
	if Global.PLAYER_ON_ICE:
		friction = ice_friction
	else:
		friction = std_friction
	_handle_debug()


func _physics_process(delta):
	if int(name) == SteamGlobals.STEAM_ID:
		var collision_info = move_and_collide(velocity * delta)
		if collision_info:
			velocity *= -Global.e
		
		_handle_input()
		if moving == false: _handle_friction()


var debug_setup = false
func _handle_debug():
	
	if !debug_setup:
		max_spd_slider.value = stats["SPD"]
		acc_slider.value = stats["ACC"]
		turn_slider.value = stats["HDL"]
		e_slider.value = Global.e
		
		debug_setup = true
	
	# Stats UI
	# pos
	if pos_button.pressed:
		var pos_text = pos_value.text
		if pos_text != str(position):
			var y_entered = false
			var x_value = ""
			var y_value = ""
			for i in range(0, len(pos_text)):
				if pos_text[i] == ",":
					y_entered = true
				
				if not y_entered and pos_text[i] != "," and pos_text[i] != "(":
					x_value += pos_text[i]
				
				elif y_entered and pos_text[i] != "," and pos_text[i] != " " and pos_text[i] != ")":
					y_value += pos_text[i]
					
			position = Vector2(float(x_value), float(y_value))
			
	elif position != Vector2.ZERO:
		pos_value.text = "(" + str(stepify(position.x, 0.1)) + ", " + str(stepify(position.y, 0.1)) + ")"
		
	spd_value.text = str(velocity.length())
	
	if spd_0er.pressed:
		velocity = Vector2.ZERO
	
	# max speed
	max_spd_value.text = str(max_spd_slider.value)
	stats["SPD"] = max_spd_slider.value
	
	# acc
	acc_value.text = str(acc_slider.value)
	stats["ACC"] = acc_slider.value
	
	if (acc_slider.value >= max_spd_slider.value
		or acc_slider.value == 0):
		max_spd_value.set("custom_colors/font_color", DEBUG_WARN)
		acc_value.set("custom_colors/font_color", DEBUG_WARN)
	else:
		max_spd_value.set("custom_colors/font_color", DEBUG_DEFAULT)
		acc_value.set("custom_colors/font_color", DEBUG_DEFAULT)
	
	# turn
	turn_value.text = str(turn_slider.value)
	stats["HDL"] = turn_slider.value
	
	# e
	e_value.text = str(e_slider.value)
	Global.e = e_slider.value
	
	# friction
	friction_value.text = "Friction: " + str(friction)
	
	# timer
	


func _accelerate(acc, max_spd):
	var direction = _find_vector_direction(velocity, transform.x)
	if acc > 0 and direction * velocity.length() + acc < max_spd:
		velocity += acc * transform.x
	elif acc < 0 and direction * velocity.length() - acc > -max_spd:
		velocity += acc * transform.x
	else:
		velocity = velocity.normalized() * max_spd


func _turn(dir, hdl):
	# d1
	var previous_forward_vector = transform.x
	
	rotation_degrees += dir * hdl * (velocity.length() / (200 + stats["SPD"] * 40))
	
	# d2
	var new_forward_vector = transform.x
	
	# Align the car's velocity with the direction it is now facing.
	# d1->d2 = d2 - d1
	var forward_vector_traversal = new_forward_vector - previous_forward_vector
	
	# Add the vector traversal for direction to velocity, multiplied by the magnitude of velocity
	# We also need to consider forward and reverse motion: for forward, traversal is added,
	# and for reverse, traversal is subtracted.
	# (As transform.x is a unit vector)
	var direction = _find_vector_direction(velocity, previous_forward_vector)
	velocity += direction * forward_vector_traversal * velocity.length()


func _handle_input():
	# Handles user input events.
	
	# Movement
	if Input.is_action_pressed("forward"):
		moving = true
		_accelerate(stats["ACC"] * 1, (200 + stats["SPD"] * 40))
	
	if Input.is_action_just_released("forward"):
		moving = false
		
	if Input.is_action_pressed("reverse"):
		moving = true
		_accelerate(-stats["ACC"] * 1, (200 + stats["SPD"] * 40))
	
	if Input.is_action_just_released("reverse"):
		moving = false
	
	# Turning	
	if Input.is_action_pressed("left"):
		_turn(-1, stats["HDL"])
		
	if Input.is_action_pressed("right"):
		_turn(1, stats["HDL"])
	
	
	if Input.is_action_just_pressed("teleport"):
		global_position = get_global_mouse_position()


func _handle_friction():
	var fraction_of_max_spd = velocity.length() / (200 + stats["SPD"] * 40)
	var vel_dir = velocity.normalized()
	
	# Friction has a minimum value (friction) and increases with speed 
	var final_friction = (friction + fraction_of_max_spd)
	
	if (velocity - vel_dir * final_friction).length() < final_friction:
		velocity = Vector2.ZERO
	else:
		velocity -= vel_dir * final_friction
