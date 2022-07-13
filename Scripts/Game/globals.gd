extends Node

var COEFFICIENT_OF_RESTITUTION = 0.1
var e = COEFFICIENT_OF_RESTITUTION

var SELECTED_VEHICLE
var SELECTED_MAP

# Stats:
# HP
# SPD: Max Speed
# ACC
# HDL: Turning
#
# ITM: Luck and Ability

var VEHICLE_BASE_STATS = {
	
	# Total stats: 20
	# Note: most vehicles have mini_car stats as a placeholder
	
	"cock" : {
		"HP" : 1,
		"SPD" : 1,
		"ACC" : 1,
		"HDL" : 1,
		"WGT" : 1,
		"ITM" : 1
	}, # 6
	
	"mini_car" : {
		"HP" : 1,
		"SPD" : 1,
		"ACC" : 5,
		"HDL" : 5,
		"WGT" : 1,
		"ITM" : 3
	}, # 16
	
	"cunt_car" : {
		"HP" : 1,
		"SPD" : 1,
		"ACC" : 5,
		"HDL" : 5,
		"WGT" : 2,
		"ITM" : 3
	}, # 17
	
	"dankamobil" : {
		"HP" : 1,
		"SPD" : 1,
		"ACC" : 5,
		"HDL" : 2,
		"WHT" : 3,
		"ITM" : 3
	}, # 15
	
	"short_limo" : {
		"HP" : 2,
		"SPD" : 2,
		"ACC" : 4,
		"HDL" : 4,
		"WHT" : 3,
		"ITM" : 3
	}, # 18
	
	"long_limo" : {
		"HP" : 2,
		"SPD" : 3,
		"ACC" : 3,
		"HDL" : 3,
		"WHT" : 4,
		"ITM" : 4
	}, # 19
	
	"jcl" : {
		"HP" : 2,
		"SPD" : 3,
		"ACC" : 2,
		"HDL" : 2,
		"WHT" : 5,
		"ITM" : 5
	} # 20
}

var PLAYER_ON_ICE = false
var PLAYER_ICE_FRICTION_APPLIED = false

# Controls multi-layer levels (going under some stage elements)
var STAGE_HEIGHT = 0


func _find_vector_angle(v1, v2):
	# Returns the angle between v1 and v2
	if v1 != Vector2.ZERO and v2 != Vector2.ZERO:
		# Cosine rule. Gives result in rads
		var angle = acos(v1.dot(v2) / (v1.length() * v2.length()))
		return angle
	return 0 # If a /0 error would occur, return 0


func _find_vector_direction(v1, v2):
	# Returns 1 if the second vector is over 90 degrees "away" from the
	# first vector. Makes the most sense with normalized vectors.
	var direction = 1
	if abs(_find_vector_angle(v1, v2)) >= PI/4:
		direction = -1
	return direction
