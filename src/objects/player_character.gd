extends CharacterBody3D

@export var max_speed = 5
@export var is_actively_controlled = true

var look_at_position = Vector3.FORWARD * 1000

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	update_wheels_direction()
	update_camera_position()

func update_wheels_direction():
	var velocity_xz = Vector3(self.velocity.x, 0.0, self.velocity.z)
	
	if velocity_xz.length() > 0.1:
		look_at_position = self.global_position + velocity_xz
	
	$Visuals/LowerBody.look_at(look_at_position)

func update_camera_position():
	$CameraContainer.rotation.y -= Input.get_last_mouse_velocity().x * 0.0001

func _physics_process(delta: float) -> void:
	var vec = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var vec3 = Vector3(vec.x, 0.0, vec.y)
	
	self.velocity = vec3 * max_speed + get_gravity()
	
	self.move_and_slide()
