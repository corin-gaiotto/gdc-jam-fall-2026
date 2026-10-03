extends Panel

class_name DialogueBox

@onready var content_label = $RichTextLabel
@onready var speaker_panel = $Panel
@onready var speaker_label = $Panel/RichTextLabel

signal text_done
signal confirm_pressed

var text_speed: float = 2.5 # frames per text
var text_amount: float = 0

func play_paragraphs(speaker: String, text: Array, auto_advance: bool):
	if speaker == "narrator":
		speaker_panel.hide()
		speaker_label.hide()
	else:
		speaker_panel.show()
		speaker_label.show()
		speaker_label.text = speaker.capitalize()
	var index = 0
	while index < len(text):
		play_text(text[index])
		if not(auto_advance):
			await confirm_pressed
		else:
			await text_done
		index += 1

func play_text(text: String):
	content_label.visible_characters = 0
	text_amount = 0
	content_label.text = text
	await text_done

func _physics_process(delta: float) -> void:
	if content_label.visible_characters >= len(content_label.text):
		text_done.emit()
		if Input.is_action_just_pressed("dialogue_confirm"):
			confirm_pressed.emit()
	
	while text_amount >= text_speed:
		text_amount -= text_speed
		content_label.visible_characters += 1
	
	text_amount += 1
