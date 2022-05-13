extends Node

var COEFFICIENT_OF_RESTITUTION = 0.1
var e = COEFFICIENT_OF_RESTITUTION

var PLAYER_ON_ICE
var PLAYER_ICE_FRICTION_APPLIED

var SELECTED_VEHICLE

# Stats:
# HP
# SPD: Max Speed
# ACC
# HDL: Turning
#
# ITM: Luck and Ability

var VEHICLE_BASE_STATS = {
	
	# Total stats: 15
	
	"mini_car" : {
		"HP" : 1,
		"SPD" : 1,
		"ACC" : 5,
		"HDL" : 5,
		"ITM" : 3
	},
	
	"jcl" : {
		"HP" : 2,
		"SPD" : 2,
		"ACC" : 2,
		"HDL" : 5,
		"ITM" : 4
	}
}
