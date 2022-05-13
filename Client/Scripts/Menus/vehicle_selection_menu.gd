extends GridContainer

var vehicle_buttons = []

func _ready():
	for child in get_children():
		vehicle_buttons.append(child)


func _on_button_pressed(vehicle):
	Global.SELECTED_VEHICLE = vehicle
	Server.my_vehicle = vehicle
	if Server.active:
		Server._upload_vehicle()
	else:
		Server._pre_config()
	self.queue_free()
