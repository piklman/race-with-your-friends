extends KinematicBody2D

# Text
export (Color, RGB) var DEBUG_DEFAULT
export (Color, RGB) var DEBUG_WARN

# Stats UI
onready var pos_value = get_node("../../Canvas/Stats/Position/PosValue")
onready var pos_button = get_node("../../Canvas/Stats/Position/PosButton")

onready var spd_slider = get_node("../../Canvas/Stats/MaxSpeed/MaxSpdSlider")
onready var spd_value = get_node("../../Canvas/Stats/MaxSpeed/MaxSpdValue")

onready var acc_slider = get_node("../../Canvas/Stats/Acc/AccSlider")
onready var acc_value = get_node("../../Canvas/Stats/Acc/AccValue")

onready var turn_slider = get_node("../../Canvas/Stats/Turn/TurnSlider")
onready var turn_value = get_node("../../Canvas/Stats/Turn/TurnValue")

onready var friction_slider = get_node("../../Canvas/Stats/Friction/FrictionSlider")
onready var friction_value = get_node("../../Canvas/Stats/Friction/FrictionValue")

onready var e_slider = get_node("../../Canvas/Stats/CoefficientOfRestitution/CoRSlider")
onready var e_value = get_node("../../Canvas/Stats/CoefficientOfRestitution/CoRValue")

#When moving a kinematic body, you should not set its position directly. Instead, you use the move_and_collide() or move_and_slide() methods. These methods move the body along a given vector, and it will instantly stop if a collision is detected with another body. After the body has collided, any collision response must be coded manually.

class Stats:
	var max_speed = 10
	var acc = 0.2
	var turn = 0.1
		
	func set(property: String, value):
		
		if property == "max_speed":
			max_speed = value
		
		elif property == "acc":
			acc = value
			
		elif property == "turn":
			turn = value
			
	func get(property: String):
		
		if property == "max_speed":
			return max_speed
			
		elif property == "acc":
			return acc
		
		elif property == "turn":
			return turn

var stats = Stats.new()

var direction = Vector2.ZERO
var speed = 0 # Cheeky use of speed with negative quantities allowed

var e = 0.2 # Coefficient of restitution
var friction = 0.1


func _ready():
	$ID.text = name


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if int(name) == Server.local_player_id:
		_handle_debug()
		_handle_input()


func _physics_process(delta):
	if int(name) == Server.local_player_id:
		direction = Vector2(cos(rotation), sin(rotation))
		
		_handle_driving()
		_handle_friction()
		var collision_info = move_and_collide(speed * direction * delta)
		if collision_info:
			speed *= -e


func _accelerate(acc):
	if abs(speed + acc) < stats.max_speed:
		speed += acc


func _handle_debug():
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
			
	elif speed != 0:
		pos_value.text = "(" + str(stepify(position.x, 0.1)) + ", " + str(stepify(position.y, 0.1)) + ")"
	
	# max speed
	spd_value.text = str(spd_slider.value)
	stats.max_speed = spd_slider.value
	
	# acc
	acc_value.text = str(acc_slider.value)
	stats.acc = acc_slider.value
	
	if (acc_slider.value >= spd_slider.value
		or acc_slider.value == 0
		or acc_slider.value <= friction_slider.value):
		spd_value.set("custom_colors/font_color", DEBUG_WARN)
		acc_value.set("custom_colors/font_color", DEBUG_WARN)
		friction_value.set("custom_colors/font_color", DEBUG_WARN)
	else:
		spd_value.set("custom_colors/font_color", DEBUG_DEFAULT)
		acc_value.set("custom_colors/font_color", DEBUG_DEFAULT)
		friction_value.set("custom_colors/font_color", DEBUG_DEFAULT)
	
	# turn
	turn_value.text = str(turn_slider.value)
	stats.turn = turn_slider.value
	
	# friction
	friction_value.text = str(friction_slider.value)
	friction = friction_slider.value
	
	# e
	e_value.text = str(e_slider.value)
	e = e_slider.value


func _handle_input():
	# Handles user input events.
	if Input.is_action_pressed("forward"):
		_accelerate(stats.acc)
		
	if Input.is_action_pressed("backward"):
		_accelerate(-stats.acc)
		
	if Input.is_action_pressed("left"):
		rotate(deg2rad(-stats.turn))
		
	if Input.is_action_pressed("right"):
		rotate(deg2rad(stats.turn))
		
	if Input.is_action_pressed("teleport"):
		global_position = get_global_mouse_position()


func _handle_driving():
	position += speed * direction


func _handle_friction():
	# Friction is applied with the use of the unit vector of the raw velocity.
	# raw_velocity.normalized() is the unit vector of raw_velocity.
	
	if speed - friction > 0:
		speed -= friction
	
	elif speed + friction < 0:
		speed += friction
		
	else:
		# Then applying friction would change the direction of velocity, but we want the
		# speed to go to 0, so simply set the speed to 0.
		speed = 0
