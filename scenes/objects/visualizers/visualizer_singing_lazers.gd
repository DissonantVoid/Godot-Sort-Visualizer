extends "res://scenes/objects/visualizers/visualizer.gd"

# TODO: lazers are jerky after they dissapear due to _lazers_container sorting them
#       tried multiple solution like using NOTIFICATION_MOVED_IN_PARENT
#       forcing _lazers_container to sort_children,
#       saving children position before sort and restoring it (which worked but was horribly inefficient)
#       I'll try again later. or maybe not I don't know time is running out and I gotta move on to the next project soon

onready var _lazers_container : HBoxContainer = $MarginContainer/Lazers
onready var _receivers_container : HBoxContainer = $MarginContainer/Receivers
onready var _sync_timer : Timer = $MusicSyncTimer
onready var _fireworks_container : Node2D = $Fireworks
onready var _fireworks_timer : Timer = $FireworksTimer

const _lazer_scene : PackedScene = preload("res://scenes/objects/components/lazer_shooter.tscn")
const _lazer_receiver : PackedScene = preload("res://scenes/objects/components/lazer_receiver.tscn")

const _lazers_count : int = 15
const _working_lazers_count : int = 10 # this is based on available music inside resources/music/lazer_receivers/
const _music_lenght : float = 5.16 # each lazer tune is this lenght
const _gradient_colors : Array = [Color.red, Color.orange, Color.yellow, Color.green, Color.blue, Color.indigo, Color.violet]
const _brocken_color : Color = Color.gray

const _firework_pool_size : int = 5
const _firework_intervals_time : float = 2.0
var _curr_pool_index : int = 0


func _ready():
	_sync_timer.wait_time = _music_lenght
	_sync_timer.start()
	_fireworks_timer.wait_time = _firework_intervals_time
	
	for i in _lazers_count:
		var lazer_instance := _lazer_scene.instance()
		_lazers_container.add_child(lazer_instance)
		var receiver_instance := _lazer_receiver.instance()
		_receivers_container.add_child(receiver_instance)
		
		if i < _working_lazers_count:
			# find the right color based on maping i from (int)[0,_working_lazers_count] to (float)[0,_rainbow_colors.size()-1]
			# and using its floored number as index, and its decimal as lerp value
			var normalized_i : float = float(i) / _working_lazers_count
			var color : Color = Utility.lerp_color_arr(_gradient_colors, normalized_i, true)
			
			lazer_instance.setup(false, color, i)
			
			var tune_path : String = "res://resources/music/lazer_receivers/layer" + str(i) + ".mp3"
			receiver_instance.setup(false, color, tune_path, i)
		else:
			lazer_instance.setup(true, _brocken_color, 999) # any index would work as long as it's bigger than _working_lazers_count
			receiver_instance.setup(true, _brocken_color)
	
	# create fireworks pool
	var original_firework : CPUParticles2D = _fireworks_container.get_child(0)
	for i in _firework_pool_size-1:
		_fireworks_container.add_child(original_firework.duplicate())

# override
static func get_metadata() -> Dictionary:
	return {
		"title":"singing_lazers", "image":"singing_lazers.png",
		"description":"Lazers that shoot colorful light into receivers with different colors, each time a lazer matches the right receiver, it will play a tune, once all lazers are in the right position they'll play a nice music (get the reference?)"
	}

# override
func reset():
	_fireworks_timer.stop()
	
	# shuffle lazers
	for lazer in _lazers_container.get_children():
		_lazers_container.move_child(
			lazer, Utility.rng.randi_range(0, _lazers_container.get_child_count())
		)
	
	_update_receivers()

# override
func get_content_count() -> int:
	return _lazers_container.get_child_count()

# override
func determine_priority(idx1 : int, idx2 : int) -> bool:
	return _lazers_container.get_child(idx1).get_order_index() >\
		_lazers_container.get_child(idx2).get_order_index()

# override
func update_indexes(action : int, idx1 : int, idx2 : int):
	match action:
		Sorter.SortAction.switch:
			var child1 := _lazers_container.get_child(idx1)
			var child2 := _lazers_container.get_child(idx2)
			child1.disappear()
			child2.disappear()
			
			yield(Utility.await_multiple_signals(
				[child1, "disappeared", child2, "disappeared"]
			), "all_signals_yielded")
			
			Utility.switch_children(_lazers_container, idx1, idx2)
			
			child1.appear()
			child2.appear()
		
		Sorter.SortAction.move:
			var child := _lazers_container.get_child(idx1)
			child.disappear()
			yield(child, "disappeared")
			
			_lazers_container.move_child(child, idx2)
			child.appear()
		
	_update_receivers()
	
	emit_signal("updated_indexes")

# override
func update_all(new_indexes : Array):
	var signals : Array
	for lazer in _lazers_container.get_children():
		lazer.disappear()
		signals.append(lazer)
		signals.append("disappeared")
	
	yield(Utility.await_multiple_signals(signals), "all_signals_yielded")
	
	# reorder lazers
	var ordered_lazers : Array
	for i in new_indexes:
		ordered_lazers.append(_lazers_container.get_child(i))
	
	for i in range(ordered_lazers.size()-1, -1, -1):
		_lazers_container.move_child(ordered_lazers[i], 0)
	
	for lazer in _lazers_container.get_children():
		lazer.appear()
	_update_receivers()
	emit_signal("updated_all")

# override
func set_ui_visibility(is_visible : bool):
	return

# override
func finish():
	_fireworks_timer.start()
	emit_signal("finished")

func _on_fireworks_timeout():
	var firework : CPUParticles2D = _fireworks_container.get_child(_curr_pool_index)
	firework.global_position = Vector2(
		Utility.rng.randf_range(0, get_viewport().size.x),
		Utility.rng.randf_range(0, get_viewport().size.y)
	)
	firework.color = _gradient_colors[
		Utility.rng.randi_range(0, _gradient_colors.size()-1)
	]
	firework.emitting = true
	_curr_pool_index = (_curr_pool_index + 1) % _firework_pool_size

func _update_receivers():
	# while this is a bit inefficient because we're updating all lazers even
	# if only 2 changed, the performance loss is insignificant and much
	# better than calculating what lazers need to be updated in 4 different places
	# in code
	for i in _working_lazers_count:
		var current_child := _receivers_container.get_child(i)
		
		current_child.lazer_changed(
			_lazers_container.get_child(i).get_order_index(),
			_music_lenght - _sync_timer.time_left
		)
