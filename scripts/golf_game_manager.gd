extends Node3D

## TODO: add support for switching maps

var opponents = [
	{
		"name": "chippy",
		"stats": {
			"perception": 1,
			"gullibility": 3,
			"greed": 2,
			"emotional_stability": 0
		},
		"dialogue_file": "chippy.json",
		"maps": [
			preload("res://scenes/golfMaps/test_golf_map.tscn"),
			preload("res://scenes/golfMaps/test_golf_map.tscn"),
			preload("res://scenes/golfMaps/test_golf_map.tscn")
		]
	}
]
