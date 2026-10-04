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
			preload("res://scenes/golfMaps/golf_map1.tscn"),
			preload("res://scenes/golfMaps/golf_map2.tscn"),
			preload("res://scenes/golfMaps/golf_map3.tscn")
		]
	},
	{
		"name": "prohog",
		"stats": {
			"perception": 2.0,
			"gullibility": 2.0,
			"greed": 0.0,
			"emotional_stability": 1.0
		},
		"dialogue_data": $DialogueUI.read_dialogue_file("res://assets/dialogue/prohog.json"),
		"maps": [
			preload("res://scenes/golfMaps/golf_map4.tscn"),
			preload("res://scenes/golfMaps/golf_map3.tscn"),
			preload("res://scenes/golfMaps/golf_map3.tscn")
		]
	},
	{
		"name": "voleip",
		"stats": {
			"perception": 3.0,
			"gullibility": 1.0,
			"greed": 3.0,
			"emotional_stability": 3.0
		},
		"dialogue_data": $DialogueUI.read_dialogue_file("res://assets/dialogue/voleip.json"),
		"maps": [
			preload("res://scenes/golfMaps/golf_map3.tscn"),
			preload("res://scenes/golfMaps/golf_map3.tscn"),
			preload("res://scenes/golfMaps/golf_map3.tscn")
		]
	}
]

var opponent_index: int = 1
var opponent_map_index: int = 0

func _ready():
	$DialogueUI.golf_game_manager = self
	$DialogueUI.hide()
	$GolfBall.check_if_caught.connect(check_if_caught)
	
	await introduce_opponent()
	
	load_map()
	
	await play_tutorial()

func play_tutorial():
	$GolfBall.state = GolfBall.BALL_STATE.DIALOGUE
	
	$DialogueUI.show()
	await $DialogueUI.play_dialogue($DialogueUI.read_dialogue_file("res://assets/dialogue/mole_tutorial.json"), "mole")
	
	$GolfBall.cheated = false
	$GolfBall.state = GolfBall.BALL_STATE.RESTING
	$GolfBall.show()
	$DialogueUI.hide()

func load_map():
	if $GolfBall.gridmap:
		$GolfBall.gridmap.queue_free()
	var map: GolfMap = opponents[opponent_index]["maps"][opponent_map_index].instantiate()
	add_child(map)
	$GolfBall.gridmap = map
	
	# place ball at position of gridmap marker
	$GolfBall.position = map.get_node("SpawnPoint").position
	
	# find hole, and place win area in it
	var hole_coords: Vector3i = map.get_hole_position()
	
	$WinArea.position = map.map_to_local(hole_coords)

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

func next_map():
	$GolfBall.cheated = false
	$GolfBall.state = GolfBall.BALL_STATE.RESTING
	opponent_map_index += 1
	if opponent_map_index > 2:
		opponent_map_index = 0
		opponent_index += 1
		if opponent_index > 2:
			print("win!")
		else:
			$GolfBall.state = GolfBall.BALL_STATE.DIALOGUE
			await introduce_opponent()
	load_map()

func _on_win_area_body_entered(body: Node3D) -> void:
	$WinArea/GPUParticles3D.emitting = true
	await get_tree().create_timer(5.0).timeout
	if $GolfBall.cheated:
		$GolfBall.state = GolfBall.BALL_STATE.DIALOGUE
		await check_if_caught()
	await next_map()


func _on_death_barrier_body_entered(body: Node3D) -> void:
	$GolfBall.hazard_frames = 0
	$GolfBall.state = GolfBall.BALL_STATE.HAZARD
	$GolfBall.hide()
