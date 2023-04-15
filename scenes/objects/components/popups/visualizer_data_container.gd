extends Control

signal pressed(title, path)

onready var _title_label : Label = $HBoxContainer/TextContainer/VBoxContainer/Title
onready var _description_label : RichTextLabel = $HBoxContainer/TextContainer/VBoxContainer/MarginContainer/Desc
onready var _image : TextureRect = $HBoxContainer/ImageContainer/MarginContainer/Image
onready var _panel_stylebox : StyleBoxFlat = $HBoxContainer/TextContainer.get("custom_styles/panel")

var _title : String
var _path : String


func setup(title : String, image_path : String, description : String, path : String):
	_title = tr(title)
	_title_label.text = _title
	if image_path.empty() == false:
		_image.texture = load(FilesTracker.screenshots_path + image_path)
	_description_label.bbcode_text = tr(description)
	_path = path

func _on_gui_input(event):
	if event is InputEventMouseButton && event.pressed && event.button_index == BUTTON_LEFT:
		emit_signal("pressed", _title, _path)

func _on_mouse(is_in : bool):
	_panel_stylebox.bg_color =\
		Color("ff6973") if is_in else Color("46425e")
