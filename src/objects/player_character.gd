extends CharacterBody3D

@export var max_speed = 5
@export var is_actively_controlled = true

# TODO: should be global
@export_range(0.0, 1.0) var mouse_sensitivity = 0.01

@onready var camera_pivot = $Node3D/CameraPivot
@onready var camera = $Node3D/CameraPivot/SpringArm3D/Camera3D
@onready var lower_body = $Visuals/LowerBody
@onready var upper_body = $Visuals/UpperBody


func _process(delta: float) -> void:
	update_body_visual_rotation()

func update_body_visual_rotation():
	upper_body.rotation.y = camera_pivot.rotation.y
	
	var velocity_2d = Vector2(self.velocity.x, self.velocity.z)
	if velocity_2d.length() > 0.1:
		var angle = Vector2.ZERO.angle_to_point(velocity_2d) + PI/2
		lower_body.rotation.y = - angle

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
