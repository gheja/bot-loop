extends Node3D

var camera_position_obj: Node3D
var camera_target_obj: Node3D

func _ready() -> void:
	camera_position_obj = $LevelBase/LevelObjectContainer/PlayerCharacter2/CameraContainer/CameraPosition
	camera_target_obj = $LevelBase/LevelObjectContainer/PlayerCharacter2/CameraContainer/CameraTarget

func _process(delta: float) -> void:
	$Camera3D.global_position = camera_position_obj.global_position
	$Camera3D.look_at(camera_target_obj.global_position)
