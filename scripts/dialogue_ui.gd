extends ColorRect

class_name DialogueHandler

@onready var player_portrait: DialoguePortrait = $VBoxContainer/HBoxContainer/VBoxContainer/PlayerPortrait
@onready var opponent_portrait: DialoguePortrait = $VBoxContainer/HBoxContainer/VBoxContainer3/OpponentPortrait

@onready var dialogue_box: DialogueBox = $VBoxContainer/HBoxContainer/VBoxContainer2/DialogueBox

@onready var dialogue_option_buttons: Array[Button] = [
	$VBoxContainer/VBoxContainer/Option1,
	$VBoxContainer/VBoxContainer/Option2,
	$VBoxContainer/VBoxContainer/Option3
]

var timing: bool = false
var timing_result: int = -1 # -1 for timeout, 0, 1, 2 for the options
var option_timer_max: int = 600 # in frames
var option_timer: int = 0 # when it reaches 0, automatically end dialogue and gain embarrassment

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
		var result = await run_command(data[command_index], opponent_name)
		if result == -1:
			return
		command_index += 1

func run_timed_options(options):
	for i in range(len(options)):
		var button = dialogue_option_buttons[i]
		button.text = options[i]["text"]
	option_timer = option_timer_max
	timing = true
	
	await timed_options_done
	
	for i in range(len(options)):
		var button = dialogue_option_buttons[i]
		button.text = ""
	
	return timing_result


signal timed_options_done
func _physics_process(delta: float) -> void:
	if option_timer < 1 and timing:
		timing_result = -1
		timed_options_done.emit()
	option_timer -= 1

func run_command(command: Dictionary, opponent_name: String):
	match command["type"]:
		"narrator":
			var auto_advance = false
			if "auto_advance" in command.keys():
				auto_advance = command["auto_advance"]
			await dialogue_box.play_paragraphs("narrator", command["text"], auto_advance)
		"player":
			var auto_advance = false
			if "auto_advance" in command.keys():
				auto_advance = command["auto_advance"]
			await dialogue_box.play_paragraphs("gopher", command["text"], auto_advance)
		"opponent":
			var auto_advance = false
			if "auto_advance" in command.keys():
				auto_advance = command["auto_advance"]
			await dialogue_box.play_paragraphs(opponent_name, command["text"], auto_advance)
		"player_portrait":
			player_portrait.change_portrait("gopher", command["expression"])
		"opponent_portrait":
			opponent_portrait.change_portrait(opponent_name, command["expression"])
		"sound_effect":
			pass
		"timed_options":
			var result = await run_timed_options(command["options"])
			
			if result == -1:
				# add embarrassment and end
				return -1
			else:
				# TODO: roll for success or failure instead of picking success arbitrarily
				await play_dialogue(command["options"][result]["result_success"], opponent_name)
		_:
			pass
	return 0


func _on_option_1_pressed() -> void:
	timing_result = 0
	timed_options_done.emit()


func _on_option_2_pressed() -> void:
	timing_result = 1
	timed_options_done.emit()


func _on_option_3_pressed() -> void:
	timing_result = 2
	timed_options_done.emit()
