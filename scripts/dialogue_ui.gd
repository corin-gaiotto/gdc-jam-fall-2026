extends ColorRect

class_name DialogueHandler

@onready var player_portrait: DialoguePortrait = $VBoxContainer/HBoxContainer/VBoxContainer/PlayerPortrait
@onready var opponent_portrait: DialoguePortrait = $VBoxContainer/HBoxContainer/VBoxContainer3/OpponentPortrait

@onready var dialogue_box: DialogueBox = $VBoxContainer/HBoxContainer/VBoxContainer2/DialogueBox

@onready var dialogue_option_buttons = [
	$VBoxContainer/VBoxContainer/Option1,
	$VBoxContainer/VBoxContainer/Option2,
	$VBoxContainer/VBoxContainer/Option3
]

func _ready() -> void:
	var chippy_data = read_dialogue_file("res://assets/dialogue/chippy.json")
	play_dialogue(chippy_data["cheat_noticed"][0], "chippy")

func read_dialogue_file(filename):
	# reads the JSON file into a GDScript object
	var file = FileAccess.open(filename, FileAccess.READ)
	var out = JSON.parse_string(file.get_as_text())
	file.close()
	return out

func play_dialogue(data: Array[Variant], opponent_name: String):
	# plays the Dialogue Object
	var command_index = 0
	while command_index < len(data):
		await run_command(data[command_index], opponent_name)
		command_index += 1

func run_command(command, opponent_name: String):
	match command["type"]:
		"narrator":
			await dialogue_box.play_paragraphs("narrator", command["text"])
		"player":
			await dialogue_box.play_paragraphs("gopher", command["text"])
		"opponent":
			await dialogue_box.play_paragraphs(opponent_name, command["text"])
		"player_portrait":
			player_portrait.change_portrait("gopher", command["expression"])
		"opponent_portrait":
			opponent_portrait.change_portrait(opponent_name, command["expression"])
		"sound_effect":
			pass
		"timed_options":
			pass
		_:
			pass
		
