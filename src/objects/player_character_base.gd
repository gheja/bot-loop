class_name ObjectPlayerCharacter
extends CharacterBody3D

@export var max_speed = 5
@export var is_actively_controlled = false
@export var has_primary_action = true
@export var controls_help_text = "[E] [Click] Use hammer"
@export var recording_length: float = 10.0

@export_enum("hammer", "roomba", "mini") var bot_class = "hammer"

@onready var camera_pivot = $Node3D/CameraPivot
@onready var camera = $Node3D/CameraPivot/SpringArm3D/Camera3D
@onready var lower_body = $Visuals/LowerBody
@onready var upper_body = $Visuals/UpperBody
@onready var action_animation_player: AnimationPlayer = $ActionAnimationPlayer
@onready var moving_platform_raycast: RayCast3D = $MovingPlatformRaycast
@onready var ghost_indicator: CSGSphere3D = $Visuals/Indicators/GhostIndicator
@onready var selection_indicator: CSGSphere3D = $Visuals/Indicators/SelectionIndicator
@onready var timer: Timer = $Timer
var bot_timer_indicator: BotTimerIndicator = null

@onready var effect_scene = preload("res://effects/effect_broken_down.tscn")
@onready var effect_light_beam_scene = preload("res://effects/effect_light_beam.tscn")

var recording = false
var starter_bot = false
var recording_index = 0
var frame_number = -1 # we will increase it right at the beginning of the physics frame handling
var is_broken_down = false
var break_down_effect: Node3D = null
var main_interface: MainInterface = null

var current_recording = []

var start_position: Vector3 = Vector3.ZERO

# just to ensure the light beam effect is not played on start
var first_reset = true

# NOTE: maybe we should handle all of these in _physics_process()
var inputs = {
	"vec": Vector2.ZERO,
	"action_pressed": false,
	"jump_pressed": false,
	"upper_body_rotation": 0.0,
}

func _ready() -> void:
	bot_timer_indicator = Lib.get_first_node_in_group("bot_timer_indicators")
	main_interface = Lib.get_first_node_in_group("main_interfaces")
	
	start_position = self.global_position
	timer.wait_time = recording_length
	
	if bot_class == "mini":
		starter_bot = true
		$PlayerSelectionArea.monitoring = true
	else:
		$PlayerSelectionHitbox.monitorable = true
	
	ghost_indicator.hide()
	selection_indicator.hide()
	
	Signals.save_player_recording.connect(_on_save_player_recording)

func reset_bot():
	if not first_reset:
		create_light_beam_effect()
	
	Signals.bot_was_reset.emit(self)
	
	first_reset = false
	recording = false
	is_actively_controlled = false
	
	# _physics_process() starts with adding one
	frame_number = -1
	
	self.global_position = start_position
	is_broken_down = false
	
	if break_down_effect != null and is_instance_valid(break_down_effect):
		break_down_effect.queue_free()
	
	timer.stop()
	
	if not starter_bot:
		timer.start()

func make_active():
	recording = true
	is_actively_controlled = true
	
	# if we wanted to continue recording we might just need to trim the extra frames?
	# start a new recording
	current_recording = []
	
	# a good starting angle
	camera_pivot.rotation.x = -0.6
	camera_pivot.rotation.y = 0.0
	
	Signals.set_active_camera.emit(camera, false)
	
	main_interface.set_controls_label_text(
		"[Arrow keys] [W-A-S-D] Move\n[Mouse] Look around\n" +
		"[color=#ff0]" +
		self.controls_help_text +
		"[/color]\n" +
		"\n" +
		"[color=#0ff]" +
		("[R] Restart loop\n[Q] Back to Mini\n" if self.bot_class != "mini" else "") +
		"[P] Pause[/color]"
	)
	
	Signals.bot_was_activated.emit(self)

func _process(delta: float) -> void:
	update_body_visual_rotation()
	
	if is_actively_controlled:
		bot_timer_indicator.update_progress_bar(timer.time_left, timer.wait_time)
	# BUG, TODO: _process() is only handled on each displayed frame, but
	# _physics_proces() might happen multiple times, so the
	# inputs.action_pressed might not get processed properly, leading to
	# missed inputs
	
	if has_primary_action:
		if inputs.action_pressed:
			if bot_class == "mini":
				bot_class_mini_action()
			else:
				action_animation_player.play("primary_action")

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
	frame_number += 1
	
	if recording:
		var vec = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		
		# correct the angle based on the look direction
		vec = vec.rotated(-camera_pivot.rotation.y)
		
		inputs.vec = vec
		inputs.action_pressed = Input.is_action_just_pressed("action_primary")
		inputs.jump_pressed = false
		inputs.upper_body_rotation = lerp(upper_body.rotation.y, camera_pivot.rotation.y + PI, 0.15)
		
		if not starter_bot:
			current_recording.append(inputs.duplicate())
	else:
		if current_recording.size() <= frame_number:
			# print("No recording for frame, skipping physics frame")
			return
		
		inputs = current_recording[frame_number]
	
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

func break_down():
	AudioManager.play_sound(1)
	break_down_effect = effect_scene.instantiate()
	self.add_child(break_down_effect)
	is_broken_down = true

func _on_hit_box_area_entered(area: Area3D) -> void:
	if bot_class == "hammer":
		pass
	elif bot_class == "roomba":
		var parent = area.get_parent()
		if parent is ObjectTrap:
			parent.queue_free()
			return
	elif bot_class == "mini":
		return
	
	break_down()

var highlighted_character: ObjectPlayerCharacter = null

func set_highlight(value: bool):
	selection_indicator.visible = value

func _on_player_selection_area_area_entered(area: Area3D) -> void:
	if highlighted_character:
		highlighted_character.set_highlight(false)
		highlighted_character = null

	highlighted_character = Lib.get_parent_of_type(area, "CharacterBody3D")
	highlighted_character.set_highlight(true)

func _on_player_selection_area_area_exited(area: Area3D) -> void:
	if highlighted_character:
		highlighted_character.set_highlight(false)
		highlighted_character = null

func start_playback():
	pass

func reset_and_activate():
	reset_bot()
	make_active()

func swap_player_for(obj: ObjectPlayerCharacter):
	obj.reset_and_activate()

func bot_class_mini_action():
	if not highlighted_character:
		return
	
	BotManager.swap_to_bot(self, highlighted_character, true)
	# swap_player_for(highlighted_character)

func create_light_beam_effect():
	var effect = effect_light_beam_scene.instantiate() as Node3D
	effect.global_position = self.global_position
	Lib.get_first_node_in_group("level_object_containers").add_child(effect)

func _on_timer_timeout() -> void:
	var was_actively_controlled = is_actively_controlled
	
	BotManager.deactivate_and_restart_bot(self, is_actively_controlled)
	
	if was_actively_controlled:
		Signals.bot_was_deactivated.emit(self)
