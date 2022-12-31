extends "res://scenes/objects/ui_components/popups/popup_base.gd"

onready var _step_time_box : SpinBox = $Content/MarginContainer/VBoxContainer/GridContainer/SpinBox


# override and do error checking
func _on_ok_pressed():
	emit_signal("ok", {"step_time":_step_time_box.value})
	queue_free()
