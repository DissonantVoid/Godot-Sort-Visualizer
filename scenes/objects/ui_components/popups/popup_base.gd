extends Control

signal ok(data) # data : dictionary
signal cancel

func _on_background_gui_input(event):
	if event is InputEventMouseButton && event.pressed && event.button_index == BUTTON_LEFT:
		emit_signal("cancel")
		queue_free()

# override and do error checking
func _on_ok_pressed():
	emit_signal("cancel")
	queue_free()

# override
func _on_cancel_pressed():
	emit_signal("cancel")
	queue_free()
