class_name ObjectPlayerCharacter
extends CharacterBody3D

@export var max_speed = 5
@export var is_actively_controlled = false
@export var player_index = -1
@export var has_primary_action = true
@export var controls_help_text = "[E] [Click] Use hammer"

@export_enum("hammer", "roomba") var bot_class = "hammer"

@onready var camera_pivot = $Node3D/CameraPivot
@onready var camera = $Node3D/CameraPivot/SpringArm3D/Camera3D
@onready var lower_body = $Visuals/LowerBody
@onready var upper_body = $Visuals/UpperBody
@onready var player_index_label: Label3D = $Visuals/PlayerIndexLabel
@onready var moving_platform_raycast: RayCast3D = $MovingPlatformRaycast

@onready var effect_scene = preload("res://effects/effect_broken_down.tscn")

var recording = false
var recording_index = 0
var frame_number = -1 # we will increase it right at the beginning of the physics frame handling
var is_broken_down = false

var current_recording = []

# NOTE: maybe we should handle all of these in _physics_process()
var inputs = {
	"vec": Vector2.ZERO,
	"action_pressed": false,
	"jump_pressed": false,
	"upper_body_rotation": 0.0,
}

func _ready() -> void:
	if player_index == -1:
		# this is hackis but at least this way we don't need to edit the children
		var parent = get_parent()
		if parent is PlayerCharacterSubclass:
			player_index = parent.player_index
	
	assert(player_index != -1, "Player object is not set up correctly")
	
	Signals.save_player_recording.connect(_on_save_player_recording)
	Signals.timer_started.connect(_on_timer_started)
	
	player_index_label.text = str(player_index)
	
	recording_index = player_index - 1

func make_active():
	recording = true
	is_actively_controlled = true
	
	# a good starting angle
	camera_pivot.rotation.x = -0.6
	camera_pivot.rotation.y = 0.0

func _process(delta: float) -> void:
	update_body_visual_rotation()
	if has_primary_action:
		if inputs.action_pressed:
			$AnimationPlayer.play("primary_action")

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

		current_recording.append(inputs.duplicate())
	else:
		if GameState.player_recordings[recording_index].size() <= frame_number:
			# print("No recording for frame, skipping physics frame")
			return
		
		inputs = GameState.player_recordings[recording_index][frame_number]
	
	# we need to handle breakdown even when playing back a recording
	# TODO: should we just stop all processing here? probably... let's see
	
	if is_broken_down:
		inputs.vec = Vector2.ZERO
		inputs.action_pressed = false
		inputs.jump_pressed = false
		inputs.upper_body_rotation = upper_body.rotation.y
	
	var vec3 = Vector3(inputs.vec.x, 0.0, inputs.vec.y)
	
	self.velocity = vec3 * max_speed + get_gravity()
	
	# platform handling
	if moving_platform_raycast.is_colliding():
		var obj = moving_platform_raycast.get_collider() as Node3D
		
		if obj.is_in_group("moving_platform_static_bodies"):
			var platform = obj.get_parent().get_parent().get_parent() as ObjectMovingPlatform
			# NOTE: force-move the object using the global_position
			self.global_position += platform.current_velocity
	
	upper_body.rotation.y = inputs.upper_body_rotation
	self.move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		camera_pivot.rotation.x -= event.relative.y * Constants.MOUSE_SENSITIVITY
		camera_pivot.rotation.x = clampf(camera_pivot.rotation.x, deg_to_rad(-85), deg_to_rad(-15))
		camera_pivot.rotation.y += -event.relative.x * Constants.MOUSE_SENSITIVITY

func _on_save_player_recording():
	if not recording:
		return
	
	GameState.player_recordings[recording_index] = current_recording.duplicate()

func _on_timer_started():
	player_index_label.hide()

func break_down():
	AudioManager.play_sound(1)
	self.add_child(effect_scene.instantiate())
	is_broken_down = true

func _on_hit_box_area_entered(area: Area3D) -> void:
	if bot_class == "hammer":
		pass
	elif bot_class == "roomba":
		var parent = area.get_parent()
		if parent is ObjectTrap:
			parent.queue_free()
			return
	
	break_down()
