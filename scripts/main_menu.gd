extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for button: TextureButton in [$TextureRect/Control/play, $TextureRect/Control/settings]:
		var mask := BitMap.new()
		mask.create_from_image_alpha(button.texture_normal.get_image())
		button.texture_click_mask = mask
	#$TextureRect/settings_menu.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/golfing.tscn")


#func _on_settings_pressed() -> void:
	#$TextureRect/settings_menu.visible = true


#func _on_button_pressed() -> void:
	#_ready()
