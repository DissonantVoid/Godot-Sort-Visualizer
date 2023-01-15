extends "res://scenes/objects/components/popups/popup_base.gd"

onready var _step_time_box : SpinBox = $Content/MarginContainer/VBoxContainer/GridContainer/SpinBox

var _settings = load("res://scenes/game/main.gd").Settings.new()

func setup(settings):
	_step_time_box.value = settings.time_per_step

# override and do error checking
func _on_ok_pressed():
	_settings.time_per_step = _step_time_box.value
	emit_signal("ok", {"settings":_settings})
	queue_free()
