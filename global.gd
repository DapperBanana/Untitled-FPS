extends Node


signal instance_player(id)
signal toggle_network_setup(toggle)

#Kill the game if we press escape
func _input(event):
	if event is InputEventKey:
		if event.scancode == KEY_ESCAPE:
			get_tree().quit()
