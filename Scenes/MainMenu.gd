extends Node

@onready var optionsMenu = $Control/PanelContainer2
@onready var streamer_mode = $Control/PanelContainer2/VBoxContainer/StreamerMode

func _ready():
	pass # Replace with function body.




func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/World.tscn")



func _on_options_button_pressed():
	optionsMenu.visible = ! optionsMenu.visible



func _on_streamer_mode_pressed():
	OptionsController.streamerMode = streamer_mode.button_pressed



func _on_difficulty_slider_drag_ended(value_changed):
	OptionsController.difficulty = $Control/PanelContainer2/VBoxContainer/DifficultySlider.value

