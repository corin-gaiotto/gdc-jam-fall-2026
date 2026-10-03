extends Node3D

class_name GolfGameManager

var suspicion: int = 0
var embarrassment: int = 0

var max_suspicion: int = 20
var max_embarrassment: int = 20

## TODO: add support for switching maps

@onready var opponents = [
	{
		"name": "chippy",
		"stats": {
			"perception": 1.0,
			"gullibility": 3.0,
			"greed": 2.0,
			"emotional_stability": 0.0
		},
		"dialogue_data": $DialogueUI.read_dialogue_file("res://assets/dialogue/chippy.json"),
		"maps": [
			preload("res://scenes/golfMaps/test_golf_map.tscn"),
			preload("res://scenes/golfMaps/test_golf_map.tscn"),
			preload("res://scenes/golfMaps/test_golf_map.tscn")
		]
	}
]

var opponent_index: int = 0
var opponent_map_index: int = 0

func _ready():
	$DialogueUI.golf_game_manager = self
	$DialogueUI.hide()
	$GolfBall.check_if_caught.connect(check_if_caught)
	
	await introduce_opponent()

func introduce_opponent():
	$GolfBall.state = GolfBall.BALL_STATE.DIALOGUE
	
	$DialogueUI.show()
	await $DialogueUI.play_dialogue(opponents[opponent_index]["dialogue_data"]["intro"], opponents[opponent_index]["name"])
	
	$GolfBall.cheated = false
	$GolfBall.state = GolfBall.BALL_STATE.RESTING
	$GolfBall.show()
	$DialogueUI.hide()

func check_if_caught():
	# add suspicion based on perception regardless
	suspicion += opponents[opponent_index]["stats"]["perception"]
	var chance = opponents[opponent_index]["stats"]["perception"]/3.0
	if randf() < chance:
		print("caught")
		# caught! freeze player, start dialogue, etc.
		$GolfBall.state = GolfBall.BALL_STATE.DIALOGUE
		
		$DialogueUI.show()
		await $DialogueUI.play_dialogue(opponents[opponent_index]["dialogue_data"]["cheat_noticed"].pick_random(), opponents[opponent_index]["name"])
		
		$GolfBall.cheated = false
		$GolfBall.state = GolfBall.BALL_STATE.RESTING
		$GolfBall.show()
		$DialogueUI.hide()
	else:
		# safe for now. do nothing
		pass
