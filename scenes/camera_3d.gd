extends Camera3D

@export var tracking_ball: RigidBody3D
var tracking_offset: Vector3 = Vector3(2, 2, 2)

func _physics_process(delta: float) -> void:
	position = lerp(position, tracking_ball.position + tracking_offset, 0.15)
