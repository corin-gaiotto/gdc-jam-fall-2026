extends Camera3D

@export var tracking_ball: GolfBall
var tracking_offset: Vector3 = Vector3(2, 2, 2)

func _physics_process(delta: float) -> void:
	position = lerp(position, tracking_ball.position + tracking_offset, 0.15)
	var dir = tracking_ball.wind_controller.wind_direction
	$WindIndicator.global_rotation = Vector3(PI/2, PI/2 - dir, 0)
	$WindIndicator.scale.y = tracking_ball.wind_controller.wind_strength/300
