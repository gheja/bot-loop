class_name ObjectMovingPlatform
extends Node3D

@export var activation_group_id = 1
@export var speed = 3.0

@onready var path_3d: Path3D = $Path3D
@onready var path_follow_3d: PathFollow3D = $Path3D/PathFollow3D

var activation_state = false
var current_velocity = Vector2.ZERO

func _ready() -> void:
	Signals.trigger_activation_changed.connect(_on_trigger_activation_changed)

func _physics_process(delta: float) -> void:
	var direction = -1
	var last_position = path_follow_3d.position
	
	if activation_state == true:
		direction = 1
	
	var a = path_follow_3d.progress + speed * direction * delta
	
	path_follow_3d.progress = clamp(a, 0, path_3d.curve.get_baked_length())
	
	current_velocity = path_follow_3d.position - last_position

func handle_new_state():
	pass

func _on_trigger_activation_changed(group_id: int, state: bool):
	if group_id == self.activation_group_id:
		# there might be two triggers
		# BUG? when one of the trigger stops it deactivates this
		if state == activation_state:
			return
			
		activation_state = state
		
		handle_new_state()
