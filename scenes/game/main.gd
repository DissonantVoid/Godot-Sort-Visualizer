extends Control

class Settings:
	# NOTE: a class instead of a dict, because dict keys are not checked untill runtime
	# making them prone to error and hard to keep track of reads/writes to the same key
	# this functions more like like a c++ Struct
	var time_per_step : float = 25.0
	var volume : float = 100
	var language: String = "en"
	
	var _file : ConfigFile = ConfigFile.new()
	var _settings_file_path : String
	const _section_name : String = "settings"
	
	func _init():
		# create save file if doesn't exist
		var dir : Directory = Directory.new()
		if OS.has_feature("standalone"):
			_settings_file_path = OS.get_executable_path().get_base_dir() + "/settings"
		else:
			_settings_file_path = "res://settings"
			
		if dir.dir_exists(_settings_file_path) == false:
			dir.make_dir(_settings_file_path)
		
		_settings_file_path += "/settings.cfg"
		if dir.file_exists(_settings_file_path):
			_file.load(_settings_file_path)
			read()
	
	func read():
		time_per_step = _file.get_value(_section_name, "time_per_step", time_per_step)
		volume = _file.get_value(_section_name, "volume", volume)
		language = _file.get_value(_section_name, "language", language)
		# ...
	
	func write():
		_file.set_value(_section_name, "time_per_step", time_per_step)
		_file.set_value(_section_name, "volume", volume)
		_file.set_value(_section_name, "language", language)
		# ...
		_file.save(_settings_file_path)

onready var _interface : CanvasLayer = $MainInterface
onready var _continous_timer : Timer = $ContinuousTimer

const _initial_visualizer : String = "VERTICAL_TITLE"
const _initial_sorter : String = "BUBBLESORT"
var _sorter : Sorter = null
var _visualizer = null

enum RunningMode {step, continuous} # step requires user input to do next sort, continous relies on timer
var _running_mode : int = RunningMode.step
var _is_waiting_for_visualizer : bool = false
var _is_stoping_next : bool = false

var _settings : Settings = Settings.new()


func _ready():
	# apply settings from file
	_apply_settings()
	
	# initial sorter/visualizer
	_set_visualizer(load(FilesTracker.get_visualizers_dict()[_initial_visualizer]["scene"]).instance())
	_visualizer.reset()
	
	_sorter = load(FilesTracker.get_sorters_dict()[_initial_sorter]).new()
	_sorter.setup(_visualizer.get_content_count(), funcref(_visualizer, "determine_priority"))
	
	_interface.setup(_initial_visualizer, _initial_sorter)

func _apply_settings():
	_continous_timer.wait_time = _settings.time_per_step / 1000
	if _settings.volume == 0:
		AudioServer.set_bus_mute(0, true)
	else:
		if AudioServer.is_bus_mute(0): AudioServer.set_bus_mute(0, false)
		AudioServer.set_bus_volume_db(0, range_lerp(_settings.volume, 0, 100, -40, 0))
	TranslationServer.set_locale(_settings.language)
	if _sorter != null:
		_interface.setup(_sorter.get_sorter_name(), _visualizer.get_visualizer_name())

func _on_interface_sorter_changed(new_sorter):
	_sorter = new_sorter
	_reset()

func _on_interface_visualizer_changed(new_visualizer):
	_set_visualizer(new_visualizer)
	_reset()

func _on_interface_options_changed(settings : Settings):
	_settings = settings
	_apply_settings()
	
	_settings.write()

func _on_interface_ui_visibility_changed(is_visible : bool):
	_visualizer.set_ui_visibility(is_visible)

func _on_interface_button_pressed(button : String):
	match button:
		"options":
			_interface.show_options_popup(_settings)
		"start", "continue":
			_running_mode = RunningMode.continuous
			_continous_timer.start()
		"next":
			_next_step() 
		"pause":
			_running_mode = RunningMode.step
			_continous_timer.stop()
		"stop":
			_is_stoping_next = true
		"last":
			_continous_timer.stop()
			_is_waiting_for_visualizer = true
			_interface.set_ui_active(false)
			_visualizer.update_all(_sorter.skip_to_last_step())
		"restart":
			_reset()

func _set_visualizer(visualizer):
	if _visualizer != null:
		_visualizer.queue_free()
	
	_visualizer = visualizer
	add_child(_visualizer)
	move_child(_visualizer, 0)
	_visualizer.connect("updated_indexes", self, "_on_visualizer_updated_indexes")
	_visualizer.connect("updated_all", self, "_on_visualizer_updated_all")
	_visualizer.connect("finished", self, "_on_visualizer_finished")

func _on_visualizer_updated_indexes():
	_is_waiting_for_visualizer = false
	_interface.set_ui_active(true)
	
	if _is_stoping_next:
		_is_stoping_next = false
		_reset()
	elif _running_mode == RunningMode.continuous && _continous_timer.is_stopped():
		_continous_timer.start()

func _on_visualizer_updated_all():
	_visualizer.finish()

func _on_visualizer_finished():
	_is_waiting_for_visualizer = false
	_interface.set_ui_active(true)
	_interface.sorter_finished()

func _on_continuous_timeout():
	if _is_waiting_for_visualizer == false:
		_next_step()

func _next_step():
	var step_data : Dictionary = _sorter.next_step()
	assert(step_data.has("done"), "no 'done' entry in sorter.next_step() return")
	
	_is_waiting_for_visualizer = true
	_interface.set_ui_active(false)
	
	if step_data["done"]:
		if _is_stoping_next: _is_stoping_next = false # in case we press stop right before the last iteration
		if _running_mode == RunningMode.continuous:
			_continous_timer.stop()
		_visualizer.finish()
	else:
		assert(step_data.has("action"), "no 'action' entry in sorter.next_step() return")
		assert(Sorter.SortAction.values().has(step_data["action"]), " action' entry in sorter.next_step() isn't of type Sorter.SortAction")
		
		assert(step_data.has("indexes"), "no 'indexes' entry in sorter.next_step() return")
		assert(step_data["indexes"].size() == 2, "'indexes' entry in sorter.next_step() return must have 2 indexes")
		
		# NOTE: this line should be last in case update_indexes() emits immediately like in visualizer_vertical_lines
		_visualizer.update_indexes(step_data["action"], step_data["indexes"][0], step_data["indexes"][1])

func _reset():
	_running_mode = RunningMode.step
	_continous_timer.stop()
	_interface.set_ui_active(true) # in case we change sorter mid sort
	_visualizer.reset()
	_sorter.setup(_visualizer.get_content_count(), funcref(_visualizer, "determine_priority"))
