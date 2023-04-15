extends "res://scenes/objects/components/popups/popup_base.gd"

onready var _step_time_box   : SpinBox = $Content/MarginContainer/VBoxContainer/GridContainer/SpinBox
onready var _volume_slider	 : HSlider = $Content/MarginContainer/VBoxContainer/GridContainer/HSlider
onready var _language_choice : OptionButton = $Content/MarginContainer/VBoxContainer/GridContainer/OptionButton
onready var _locales : Array = TranslationServer.get_loaded_locales()

var _settings = load("res://scenes/game/main.gd").Settings.new()

func setup(settings):
	_step_time_box.value = settings.time_per_step
	_volume_slider.value = settings.volume
	for locale in _locales:
		_language_choice.add_item(locale)
	_language_choice.select(_locales.find(settings.language))

# override and do error checking
func _on_ok_pressed():
	_settings.time_per_step = _step_time_box.value
	_settings.volume = _volume_slider.value
	_settings.language = _locales[_language_choice.selected]
	emit_signal("ok", {"settings":_settings})
	queue_free()
