extends CharacterBody3D

@export var max_speed = 5
@export var is_actively_controlled = true

# TODO: should be global
@export_range(0.0, 1.0) var mouse_sensitivity = 0.01

@onready var camera_pivot = $Node3D/CameraPivot
@onready var camera = $Node3D/CameraPivot/SpringArm3D/Camera3D
@onready var lower_body = $Visuals/LowerBody
@onready var upper_body = $Visuals/UpperBody


func _ready() -> void:
	if is_actively_controlled:
		camera.make_current()

func _process(delta: float) -> void:
	update_body_visual_rotation()
	if Input.is_action_just_pressed("action_primary"):
		$AnimationPlayer.play("hammer_hit")

# thanks Nermit!
# https://forum.godotengine.org/t/rotation-wrap-around-issue/16014/2
static func _short_angle_dist(from, to):
	var max_angle = PI * 2
	var difference = fmod(to - from, max_angle)
	return fmod(2 * difference, max_angle) - difference

func update_body_visual_rotation():
	# BUG: TODO: the upper body has collision, so it is not just visual!!!
	
	# upper_body.rotation.y = camera_pivot.rotation.y + PI
	upper_body.rotation.y = lerp(upper_body.rotation.y, camera_pivot.rotation.y + PI, 0.15)
	
	var velocity_2d = Vector2(self.velocity.x, self.velocity.z)
	if velocity_2d.length() > 0.1:
		var target_angle = Vector2.ZERO.angle_to_point(velocity_2d) - PI/2
		var target_rotation = lower_body.rotation.y + _short_angle_dist(lower_body.rotation.y, -target_angle)
		
		lower_body.rotation.y = lerp(lower_body.rotation.y, target_rotation, 0.15)

func _physics_process(delta: float) -> void:
	var vec = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# correct the angle based on the look direction
	vec = vec.rotated(-camera_pivot.rotation.y)
	
	var vec3 = Vector3(vec.x, 0.0, vec.y)
	
	self.velocity = vec3 * max_speed + get_gravity()
	
	self.move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		camera_pivot.rotation.x -= event.relative.y * mouse_sensitivity
		camera_pivot.rotation.x = clampf(camera_pivot.rotation.x, deg_to_rad(-75), deg_to_rad(-15))
		camera_pivot.rotation.y += -event.relative.x * mouse_sensitivity
