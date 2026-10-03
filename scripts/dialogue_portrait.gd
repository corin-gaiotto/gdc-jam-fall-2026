extends Control

class_name DialoguePortrait

@onready var portrait_texture_rect = $TextureRect
@onready var portrait_name_label = $RichTextLabel

@export var portrait_data: Dictionary[String, PortraitData]

func change_portrait(portrait_name: String, portrait_expression: String):
	portrait_name_label.text = portrait_name.capitalize()
	portrait_texture_rect.texture = portrait_data[portrait_name].data[portrait_expression]

func reset_portrait():
	portrait_name_label.text = ""
	portrait_texture_rect.texture = null
