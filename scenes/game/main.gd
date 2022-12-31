extends Control

export(NodePath) var _visualizer_path : NodePath

onready var _algo_picker : MarginContainer = $AlgorithmPicker
onready var _continous_timer : Timer = $ContinuousTimer
var _visualizer : Control

var _time_per_step_ms : float = 50 # when continuesly sorting
var _current_sorter = null

enum RunningMode {step, continuous}
var _running_mode : int = RunningMode.step
var _is_running : bool = false

func _ready():
	assert(_visualizer_path != null)
	_visualizer = get_node(_visualizer_path)
	
	# setup
	_continous_timer.wait_time = _time_per_step_ms / 1000
	
	_algo_picker.connect("algorithm_changed", self, "_on_picker_algo_changed")
	_algo_picker.connect("options_changed", self, "_on_picker_options_changed")
	_algo_picker.connect("button_pressed", self, "_on_picker_button_pressed")

func _on_picker_algo_changed(new_sorter):
	_current_sorter = new_sorter 
	_reset()

func _on_picker_options_changed(data : Dictionary):
	_continous_timer.wait_time = _time_per_step_ms

func _on_picker_button_pressed(button : String):
	match button:
		"start":
			_running_mode = RunningMode.continuous
			_is_running = true
			_continous_timer.start()
		"next":
			_next_step() 
		"pause":
			_is_running = false
			_continous_timer.stop()
		"stop":
			_reset()
		"continue":
			_running_mode = RunningMode.continuous
			_continous_timer.start()
		"last":
			_visualizer.switch_all(_current_sorter.step_all())
			_visualizer.finish()
			_pause()
		"restart":
			_reset()

func _on_continuous_timeout():
	_next_step()
	_continous_timer.start()

func _next_step():
	var step_data : Dictionary = _current_sorter.next_step()
	if step_data["done"]:
		_algo_picker.sorter_finished()
		_visualizer.finish()
		_pause()
	else:
		_visualizer.switch_items(step_data["items"][0], step_data["items"][1])

func _pause():
	_is_running = false
	if _continous_timer.is_stopped() == false:
		_continous_timer.stop()

func _reset():
	_pause()
	
	_visualizer.reset()
	_current_sorter.setup(_visualizer.get_content_size(), funcref(_visualizer, "sort_callback"))
