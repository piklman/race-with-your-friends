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
