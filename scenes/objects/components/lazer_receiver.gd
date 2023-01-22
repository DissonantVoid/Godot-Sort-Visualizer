extends VBoxContainer

onready var _animator : AnimationPlayer = $AnimationPlayer
onready var _audio_player : AudioStreamPlayer = $AudioStreamPlayer
onready var _particles : CPUParticles2D = $CPUParticles2D
onready var _texture : TextureRect = $Texture

var _color : Color
var _index : int
var _is_active : bool = false


func setup(is_brocken : bool, color : Color, tune_path : String = "", index : int = -1):
	_color = color
	_texture.modulate = color
	
	if is_brocken:
		_texture.texture.region.position.x = 192
	else:
		_animator.play("off")
		_audio_player.stream = load(tune_path)
		_index = index

func lazer_changed(lazer_index : int, sync_time : float):
	var should_activate : bool = lazer_index == _index
	
	if should_activate == _is_active:
		if should_activate: _audio_player.play(sync_time)
		return
	
	_is_active = should_activate
	if _is_active:
		_animator.play("on")
		_particles.emitting = true
		_audio_player.play(sync_time)
	else:
		_animator.play("off")
		_particles.emitting = false
		_audio_player.stop()
