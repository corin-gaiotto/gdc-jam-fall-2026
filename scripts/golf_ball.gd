extends RigidBody3D

class_name GolfBall

var camera_rotation: Vector3 = Vector3(deg_to_rad(-30), deg_to_rad(45), 0)

@onready var aim_visuals = [$RayCast3D/AimVisual1, $RayCast3D/AimVisual2, $RayCast3D/AimVisual3]
@onready var aim_shadows = [$RayCast3D/AimShadow1, $RayCast3D/AimShadow2, $RayCast3D/AimShadow3]

@export var wind_controller: WindController
@export var gridmap: GolfMap

enum BALL_STATE {AIMABLE, IN_MOTION, RESTING, HAZARD}
enum CHEATS {NONE, WIND, BALL, MOLE, TILT}
## STATE DESCRIPTIONS:
#    AIMABLE:   ball is at rest, and the player is able to control the aim angle before firing. Visual indicator of firing angle is visible.
#    IN_MOTION: ball has been hit. After some time (say, 3 seconds) of not being in motion, will become RESTING.
#    RESTING:   hide ball, show visual indicator of distance to hole, etc. Transition to AIMABLE after player confirmation or after time has passed.
#    HAZARD:    hide ball, after short amount of time teleport ball back to old position and show ball, transitioning to RESTING.
var state: BALL_STATE = BALL_STATE.AIMABLE

var selected_cheat: CHEATS = CHEATS.NONE
var mouse_direction: float = 0 # used for wind and tilt cheats
var mouse_strength: float = 0 # used for wind and tilt cheats

var cheated: bool = 0

var stroke_count: int = 0
@onready var previous_position: Vector3 = global_position

const resting_frames_required: int = 3 * 60
var resting_frames: int = 0

const hazard_frames_required: int = 3 * 60
var hazard_frames: int = 0

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

const launch_percent_change: float = 1.0/48.0 # amount the bar changes per physics tick
var launching: bool = false
var launch_percent_direction: float = 1 # whether bar is moving up or down (1 or -1)
var launch_percent: float = 0
var launch_strength: float = 10 # strength of the strongest shot

func set_cheated():
	cheated = true
	selected_cheat = CHEATS.NONE

func get_mouse_properties():
	var rawPosition = get_viewport().get_mouse_position() - Vector2(1920/2, 1080/2)
	var correctedPosition = Vector3(rawPosition.x, rawPosition.y, 0) * Basis.from_euler(camera_rotation)
	mouse_direction = atan2(correctedPosition.y, correctedPosition.x)
	mouse_strength = sqrt((correctedPosition.x ** 2) + (correctedPosition.y ** 2))
	

func _physics_process(delta: float) -> void:
	if is_grounded():
		var hit_point = $RayCast3D.get_collision_point()
		var current_distance = global_position.distance_to(hit_point)
		
		# Calculate spring compression force
		var distance_error = 0.13 - current_distance
		if distance_error > 0:
			var normal = $RayCast3D.get_collision_normal()
			var vertical_velocity = linear_velocity.dot(normal)
			
			var spring_force = (distance_error * 500) - (vertical_velocity * 30)
			apply_force(normal * max(0.0, spring_force))
		apply_ground_properties()
	else:
		linear_damp = 0
		angular_damp = 0
		
		# wind
		apply_central_force(Vector3(cos(wind_controller.wind_direction), 0, sin(wind_controller.wind_direction)) * wind_controller.wind_strength * delta)
	match state:
		BALL_STATE.AIMABLE:
			if $RayCast3D.is_colliding():
				position.y += 0.01
			linear_velocity = Vector3.ZERO
			angular_velocity = Vector3.ZERO
			self.set_axis_lock(PhysicsServer3D.BODY_AXIS_LINEAR_X, true)
			self.set_axis_lock(PhysicsServer3D.BODY_AXIS_LINEAR_Y, true)
			self.set_axis_lock(PhysicsServer3D.BODY_AXIS_LINEAR_Z, true)
			match selected_cheat:
				CHEATS.NONE:
					if cheated:
						$CanvasLayer/CheatMenu.hide()
					else:
						$CanvasLayer/CheatMenu.show()
					if launching:
						launching_controls()
					else:
						aiming_controls()
					draw_aiming()
				CHEATS.WIND:
					hide_aiming()
					$CanvasLayer/CheatMenu.hide()
					get_mouse_properties()
					wind_controller.wind_direction = mouse_direction
					wind_controller.wind_strength = clampf(mouse_strength, 0, 300)
					if Input.is_action_just_pressed("cheat_confirm"):
						set_cheated()
				CHEATS.BALL:
					hide_aiming()
					$CanvasLayer/CheatMenu.hide()
				CHEATS.MOLE:
					hide_aiming()
					$CanvasLayer/CheatMenu.hide()
					var hole_pos = gridmap.get_hole_position()
					if Input.is_action_just_pressed("ball_angle_down"):
						var temp = [gridmap.get_cell_item(hole_pos + Vector3i(0, 0, 1)), gridmap.get_cell_item_orientation(hole_pos + Vector3i(0, 0, 1))]
						gridmap.set_cell_item(hole_pos + Vector3i(0, 0, 1), 6, 0)
						gridmap.set_cell_item(hole_pos, temp[0], temp[1])
						set_cheated()
					elif Input.is_action_just_pressed("ball_angle_up"):
						var temp = [gridmap.get_cell_item(hole_pos + Vector3i(0, 0, -1)), gridmap.get_cell_item_orientation(hole_pos + Vector3i(0, 0, -1))]
						gridmap.set_cell_item(hole_pos + Vector3i(0, 0, -1), 6, 0)
						gridmap.set_cell_item(hole_pos, temp[0], temp[1])
						set_cheated()
					elif Input.is_action_just_pressed("ball_angle_left"):
						var temp = [gridmap.get_cell_item(hole_pos + Vector3i(-1, 0, 0)), gridmap.get_cell_item_orientation(hole_pos + Vector3i(-1, 0, 0))]
						gridmap.set_cell_item(hole_pos + Vector3i(-1, 0, 0), 6, 0)
						gridmap.set_cell_item(hole_pos, temp[0], temp[1])
						set_cheated()
					elif Input.is_action_just_pressed("ball_angle_right"):
						var temp = [gridmap.get_cell_item(hole_pos + Vector3i(1, 0, 0)), gridmap.get_cell_item_orientation(hole_pos + Vector3i(1, 0, 0))]
						gridmap.set_cell_item(hole_pos + Vector3i(1, 0, 0), 6, 0)
						gridmap.set_cell_item(hole_pos, temp[0], temp[1])
						set_cheated()
				CHEATS.TILT:
					hide_aiming()
					$CanvasLayer/CheatMenu.hide()
					get_mouse_properties()
					gridmap.rotation = Vector3(cos(mouse_direction) * deg_to_rad(2) * clampf(mouse_strength/300, 0, 1), 0, sin(mouse_direction) * deg_to_rad(2) * clampf(mouse_strength/300, 0, 1))
					if Input.is_action_just_pressed("cheat_confirm"):
						set_cheated()
		BALL_STATE.IN_MOTION:
			$CanvasLayer/CheatMenu.hide()
			hide_aiming()
			check_resting()
		BALL_STATE.RESTING:
			$CanvasLayer/CheatMenu.hide()
			hide_aiming()
			previous_position = global_position
			
			wind_controller.randomize_wind()
			state = BALL_STATE.AIMABLE
			gridmap.rotation = Vector3(0, 0, 0)
			gravity_scale = 1.0
			
			## LATER: run the roll for if you're caught cheating here
			
			cheated = false
		BALL_STATE.HAZARD:
			$CanvasLayer/CheatMenu.hide()
			linear_velocity = Vector3.ZERO
			angular_velocity = Vector3.ZERO
			self.set_axis_lock(PhysicsServer3D.BODY_AXIS_LINEAR_X, true)
			self.set_axis_lock(PhysicsServer3D.BODY_AXIS_LINEAR_Y, true)
			self.set_axis_lock(PhysicsServer3D.BODY_AXIS_LINEAR_Z, true)
			hide_aiming()
			if hazard_frames >= hazard_frames_required:
				hazard_frames = 0
				global_position = previous_position
				self.set_axis_lock(PhysicsServer3D.BODY_AXIS_LINEAR_X, false)
				self.set_axis_lock(PhysicsServer3D.BODY_AXIS_LINEAR_Y, false)
				self.set_axis_lock(PhysicsServer3D.BODY_AXIS_LINEAR_Z, false)
				linear_velocity = Vector3.ZERO
				angular_velocity = Vector3.ZERO
				show()
				state = BALL_STATE.RESTING
			hazard_frames += 1

func check_resting():
	if linear_velocity.length() < 0.2 and angular_velocity.length() < 0.2:
		resting_frames += 1
	else:
		resting_frames = 0
	
	if resting_frames >= resting_frames_required:
		state = BALL_STATE.RESTING

func apply_ground_properties():
	var ground_type = get_ground_type()
	if ground_type == "undefined":
		return
	else:
		match ground_type.split("_")[0]:
			"rough":
				linear_damp = 2.5
				angular_damp = 2.0
			"fairway":
				linear_damp = 0.5
				angular_damp = 0.5
			"green":
				linear_damp = 0.2
				angular_damp = 0.2
			"sand":
				linear_damp = 10.0
				angular_damp = 10.0
				linear_velocity *= 0.9
			"water":
				if state != BALL_STATE.HAZARD:
					hazard_frames = 0
					state = BALL_STATE.HAZARD
					hide()
			_:
				pass

func is_grounded():
	return $RayCast3D.is_colliding()

func get_ground_type():
	var gridMap: GridMap = $RayCast3D.get_collider()
	
	var cell_coords = gridMap.local_to_map(gridMap.to_local(global_position + Vector3(0, -0.135, 0)))
	
	if gridMap.get_cell_item(cell_coords) < 2:
		return "undefined"
	
	var tile_name = gridMap.mesh_library.get_item_name(gridMap.get_cell_item(cell_coords))
	
	return tile_name

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
		launching = true
		launch_percent = 0
		launch_percent_direction = 1

func launching_controls():
	if Input.is_action_just_pressed("ball_launch"):
		self.set_axis_lock(PhysicsServer3D.BODY_AXIS_LINEAR_X, false)
		self.set_axis_lock(PhysicsServer3D.BODY_AXIS_LINEAR_Y, false)
		self.set_axis_lock(PhysicsServer3D.BODY_AXIS_LINEAR_Z, false)
		apply_central_impulse(Vector3(
			cos(ball_yaw) * cos(ball_pitch) * launch_strength * launch_percent,
			sin(ball_pitch) * launch_strength * launch_percent,
			sin(ball_yaw) * cos(ball_pitch) * launch_strength * launch_percent
			))
		stroke_count += 1
		state = BALL_STATE.IN_MOTION
		resting_frames = 0
		launching = false
	
	launch_percent += launch_percent_change * launch_percent_direction
	
	if launch_percent >= 1 or launch_percent <= 0:
		launch_percent_direction *= -1

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
		


func _on_wind_cheat_pressed() -> void:
	selected_cheat = CHEATS.WIND


func _on_ball_cheat_pressed() -> void:
	set_cheated()
	gravity_scale = 0.5


func _on_mole_cheat_pressed() -> void:
	selected_cheat = CHEATS.MOLE


func _on_tilt_cheat_pressed() -> void:
	selected_cheat = CHEATS.TILT
