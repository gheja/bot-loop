class_name ObjectPlayerCharacter
extends CharacterBody3D

@export var tmp_my_loop_index = 0
@export var max_speed = 5
@export var is_actively_controlled = false
@export var player_index = -1

# TODO: should be global
@export_range(0.0, 1.0) var mouse_sensitivity = 0.01

@onready var camera_pivot = $Node3D/CameraPivot
@onready var camera = $Node3D/CameraPivot/SpringArm3D/Camera3D
@onready var lower_body = $Visuals/LowerBody
@onready var upper_body = $Visuals/UpperBody

var recording = false
var recording_index = 0
var frame_number = -1 # we will increase it right at the beginning of the physics frame handling

# NOTE: maybe we should handle all of these in _physics_process()
var inputs = {
	"vec": Vector2.ZERO,
	"action_pressed": false,
	"jump_pressed": false,
	"upper_body_rotation": 0.0,
}

func _ready() -> void:
	assert(player_index != -1, "Player object is not set up correctly")
	
	recording_index = tmp_my_loop_index

func make_active():
	recording = true
	is_actively_controlled = true
	GameState.player_recordings[recording_index] = []
	camera.make_current()

func _process(delta: float) -> void:
	update_body_visual_rotation()
	if inputs.action_pressed:
		$AnimationPlayer.play("hammer_hit")

# thanks Nermit!
# https://forum.godotengine.org/t/rotation-wrap-around-issue/16014/2
static func _short_angle_dist(from, to):
	var max_angle = PI * 2
	var difference = fmod(to - from, max_angle)
	return fmod(2 * difference, max_angle) - difference

func update_body_visual_rotation():
	var velocity_2d = Vector2(self.velocity.x, self.velocity.z)
	if velocity_2d.length() > 0.1:
		var target_angle = Vector2.ZERO.angle_to_point(velocity_2d) - PI/2
		var target_rotation = lower_body.rotation.y + _short_angle_dist(lower_body.rotation.y, -target_angle)
		
		lower_body.rotation.y = lerp(lower_body.rotation.y, target_rotation, 0.15)

func _physics_process(delta: float) -> void:
	if not GameState.controls_locked:
		return
	
	if not GameState.state == GameState.STATE_RUNNING:
		return
	
	frame_number += 1
	
	if recording:
		var vec = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		
		# correct the angle based on the look direction
		vec = vec.rotated(-camera_pivot.rotation.y)
		
		inputs.vec = vec
		inputs.action_pressed = Input.is_action_just_pressed("action_primary")
		inputs.jump_pressed = false
		inputs.upper_body_rotation = lerp(upper_body.rotation.y, camera_pivot.rotation.y + PI, 0.15)

		GameState.player_recordings[recording_index].append(inputs.duplicate())
	else:
		if GameState.player_recordings[recording_index].size() <= frame_number:
			print("No recording for frame, skipping physics frame")
			return
		
		inputs = GameState.player_recordings[recording_index][frame_number]
	
	var vec3 = Vector3(inputs.vec.x, 0.0, inputs.vec.y)
	
	self.velocity = vec3 * max_speed + get_gravity()
	upper_body.rotation.y = inputs.upper_body_rotation
	self.move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		camera_pivot.rotation.x -= event.relative.y * mouse_sensitivity
		camera_pivot.rotation.x = clampf(camera_pivot.rotation.x, deg_to_rad(-85), deg_to_rad(-15))
		camera_pivot.rotation.y += -event.relative.x * mouse_sensitivity
