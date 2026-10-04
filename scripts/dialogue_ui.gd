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

var golf_game_manager: GolfGameManager

var timing: bool = false
var timing_result: int = -1 # -1 for timeout, 0, 1, 2 for the options
var option_timer_max: int = 600 # in frames
var option_timer: int = 0 # when it reaches 0, automatically end dialogue and gain embarrassment

func _ready() -> void:
	pass

func read_dialogue_file(filename):
	# reads the JSON file into a GDScript object
	var file = FileAccess.open(filename, FileAccess.READ)
	var out = JSON.parse_string(file.get_as_text())
	file.close()
	return out

func play_dialogue(data: Array[Variant], opponent_name: String):
	# plays the Dialogue Object
	player_portrait.reset_portrait()
	opponent_portrait.reset_portrait()
	var command_index = 0
	timing = false
	timing_result = -1
	option_timer = 0
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
				golf_game_manager.embarrassment += 2
				return -1
			else:
				# roll for success or failure
				var chance = 0.0
				match command["options"][result]["stat"]:
					"greed":
						chance = golf_game_manager.opponents[golf_game_manager.opponent_index]["stats"]["greed"]/3.0
					"emotional_stability":
						chance = 1 - golf_game_manager.opponents[golf_game_manager.opponent_index]["stats"]["emotional_stability"]/3.0
					"gullibility":
						chance = golf_game_manager.opponents[golf_game_manager.opponent_index]["stats"]["gullibility"]/3.0
				if randf() < chance:
					## increase/decrease relevant stats on success
					golf_game_manager.embarrassment += command["options"][result]["embarrassment_change"]
					golf_game_manager.suspicion += command["options"][result]["suspicion_change"]
					
					if command["options"][result]["stat"] == "greed":
						golf_game_manager.beetroots -= 1
					
					golf_game_manager.embarrassment = clamp(golf_game_manager.embarrassment, 0, golf_game_manager.max_embarrassment)
					golf_game_manager.suspicion = clamp(golf_game_manager.suspicion, 0, golf_game_manager.max_suspicion)
					
					await play_dialogue(command["options"][result]["result_success"], opponent_name)
				else:
					await play_dialogue(command["options"][result]["result_failure"], opponent_name)
		_:
			pass
	return 0


func _on_option_1_pressed() -> void:
	if golf_game_manager.beetroots > 0:
		timing_result = 0
		timed_options_done.emit()
	else:
		if dialogue_option_buttons[0].text:
			dialogue_option_buttons[0].text = "Not enough beetroots!"


func _on_option_2_pressed() -> void:
	timing_result = 1
	timed_options_done.emit()


func _on_option_3_pressed() -> void:
	timing_result = 2
	timed_options_done.emit()
