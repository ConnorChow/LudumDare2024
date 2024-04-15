extends Node2D
@onready var panel_container = $PanelContainer
@onready var panel_container_2 = $PanelContainer2
@onready var panel_container_3 = $PanelContainer3




func _input(event):
	if Input.is_action_just_pressed("help"):
		panel_container.visible = !panel_container.visible
		panel_container_2.visible = !panel_container_2.visible
		panel_container_3.visible = !panel_container_3.visible


func _on_button_pressed():
	panel_container.visible = !panel_container.visible
	panel_container_2.visible = !panel_container_2.visible
	panel_container_3.visible = !panel_container_3.visible
