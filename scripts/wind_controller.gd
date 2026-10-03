extends Node3D

class_name WindController

var wind_direction: float = PI/4

var wind_strength: float = 200

@export var wind_strength_curve: Curve

func randomize_wind():
	wind_direction = randf_range(0, 2 * PI)
	wind_strength = wind_strength_curve.sample(randf_range(0, 1))
