extends Control



func _on_algorithm_panel_button_clicked(button : String):
	match button:
		"options":
			pass
		"hide":
			pass
		
		"start":
			pass
		"next":
			pass
		"pause":
			pass
		"stop":
			pass
		"continue":
			pass
		"last":
			pass


func _on_algorithm_title_input(event):
	if event is InputEventMouseButton && event.pressed && event.button_index == BUTTON_LEFT:
		pass
