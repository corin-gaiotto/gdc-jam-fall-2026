extends Camera3D

@export var tracking_ball: GolfBall
var tracking_offset: Vector3 = Vector3(2, 2, 2)
var zoom_out: float = 16

func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("zoom"):
		position = lerp(position, tracking_ball.position + tracking_offset + zoom_out * self.basis.z, 0.3)
		size = lerp(size, 16.0, 0.3)
	else:
		position = lerp(position, tracking_ball.position + tracking_offset + 8 * self.basis.z, 0.15)
		size = lerp(size, 4.0, 0.3)
	rotation = tracking_ball.camera_rotation
	var dir = tracking_ball.wind_controller.wind_direction
	$WindIndicator.global_rotation = Vector3(PI/2, PI/2 - dir, 0)
	$WindIndicator.scale.y = tracking_ball.wind_controller.wind_strength/300
