extends Control

export(NodePath) var _visualizer_path : NodePath

onready var _algo_picker : MarginContainer = $AlgorithmPicker
onready var _continous_timer : Timer = $ContinuousTimer
var _visualizer : Control

var _time_per_step_ms : float = 40 # when continuesly sorting
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
	_time_per_step_ms = data["step_time"]
	_continous_timer.wait_time = _time_per_step_ms / 1000

func _on_picker_button_pressed(button : String):
	match button:
		"options":
			_algo_picker.show_options_popup({"step_time":_time_per_step_ms})
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
			_visualizer.update_all(_current_sorter.skip_to_last_step())
			_visualizer.finish()
			_pause()
		"restart":
			_reset()

func _on_continuous_timeout():
	_next_step()
	_continous_timer.start()

func _next_step():
	var step_data : Dictionary = _current_sorter.next_step()
	assert(step_data.has("done"), "no 'done' entry in sorter.next_step() return")
	
	if step_data["done"]:
		_algo_picker.sorter_finished()
		_visualizer.finish()
		_pause()
	else:
		assert(step_data.has("items"), "no 'items' entry in sorter.next_step() return")
		assert(step_data["items"].size() == 2, "'items' entry in sorter.next_step() return must have 2 items")
		
		_visualizer.update_indexes(step_data["items"][0], step_data["items"][1])

func _pause():
	_is_running = false
	if _continous_timer.is_stopped() == false:
		_continous_timer.stop()

func _reset():
	_pause()
	
	_visualizer.reset()
	_current_sorter.setup(_visualizer.get_content_count(), funcref(_visualizer, "determine_priority"))
