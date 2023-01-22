extends "res://scenes/objects/components/popups/popup_base.gd"

onready var _step_time_box : SpinBox = $Content/MarginContainer/VBoxContainer/GridContainer/SpinBox
onready var _volume_slider : HSlider = $Content/MarginContainer/VBoxContainer/GridContainer/HSlider

var _settings = load("res://scenes/game/main.gd").Settings.new()

func setup(settings):
	_step_time_box.value = settings.time_per_step
	_volume_slider.value = _settings.volume

# override and do error checking
func _on_ok_pressed():
	_settings.time_per_step = _step_time_box.value
	_settings.volume = _volume_slider.value
	emit_signal("ok", {"settings":_settings})
	queue_free()
