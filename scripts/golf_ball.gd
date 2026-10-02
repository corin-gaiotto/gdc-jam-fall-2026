extends RigidBody3D

@onready var aim_visuals = [$AimVisual1, $AimVisual2, $AimVisual3]
@onready var aim_shadows = [$AimShadow1, $AimShadow2, $AimShadow3]

enum BALL_STATE {AIMABLE, IN_MOTION, RESTING}
## STATE DESCRIPTIONS:
#    AIMABLE:   ball is at rest, and the player is able to control the aim angle before firing. Visual indicator of firing angle is visible.
#    IN_MOTION: ball has been hit. After some time (say, 5 seconds) of not being in motion, will become RESTING.
#    RESTING:   hide ball, show visual indicator of distance to hole, etc. Transition to AIMABLE after player confirmation or after time has passed.
var state: BALL_STATE = BALL_STATE.AIMABLE

var launch_strength: float = 5

# aiming direction
var ball_yaw: float = 0.0
var ball_pitch: float = PI/4

# aim clamping constraints (yaw is unclamped, pitch is clamped at fully horizontal and vertical)
const ball_min_pitch: float = 0.0
const ball_max_pitch: float = PI/2

const ball_change_step: float = PI/72

const ball_change_max_cd: int = 6 # number of frames before another movement is registered
var ball_yaw_change_cd: int = 0
var ball_pitch_change_cd: int = 0

func _physics_process(delta: float) -> void:
	match state:
		BALL_STATE.AIMABLE:
			aiming_controls()
			draw_aiming()
			print(ball_yaw, ball_pitch)
		BALL_STATE.IN_MOTION:
			hide_aiming()
		BALL_STATE.RESTING:
			hide_aiming()

func aiming_controls():
	if ball_yaw_change_cd < 1:
		var yaw_axis = Input.get_axis("ball_angle_left", "ball_angle_right")
		if yaw_axis != 0:
			ball_yaw = ball_yaw + ball_change_step * yaw_axis
			ball_yaw_change_cd = ball_change_max_cd
	if ball_pitch_change_cd < 1:
		var pitch_axis = Input.get_axis("ball_angle_down", "ball_angle_up")
		if pitch_axis != 0:
			ball_pitch = clamp(ball_pitch + ball_change_step * pitch_axis, ball_min_pitch, ball_max_pitch)
			ball_pitch_change_cd = ball_change_max_cd
	ball_yaw_change_cd -= 1
	ball_pitch_change_cd -= 1
	
	if Input.is_action_just_pressed("ball_launch"):
		apply_central_impulse(Vector3(
			cos(ball_yaw) * cos(ball_pitch) * launch_strength,
			sin(ball_pitch) * launch_strength,
			sin(ball_yaw) * cos(ball_pitch) * launch_strength
			))
		state = BALL_STATE.IN_MOTION

func hide_aiming():
	for vis in aim_visuals:
		vis.hide()
	for sha in aim_shadows:
		sha.hide()

func draw_aiming():
	for i in range(len(aim_visuals)):
		var vis = aim_visuals[i]
		var sha = aim_shadows[i]
		vis.show()
		sha.show()
		vis.position.y = sin(ball_pitch) * (i + 1) * 0.5
		vis.position.x = cos(ball_yaw) * cos(ball_pitch) * (i + 1) * 0.5
		vis.position.z = sin(ball_yaw) * cos(ball_pitch) * (i + 1) * 0.5
		
		sha.position.y = 0
		sha.position.x = cos(ball_yaw) * cos(ball_pitch) * (i + 1) * 0.5
		sha.position.z = sin(ball_yaw) * cos(ball_pitch) * (i + 1) * 0.5
		
