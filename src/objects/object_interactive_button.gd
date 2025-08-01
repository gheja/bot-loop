extends Node3D

@export var activation_group_id = 1

func _on_area_3d_area_entered(area: Area3D) -> void:
	Signals.trigger_activation_changed.emit(activation_group_id, true)

func _on_area_3d_area_exited(area: Area3D) -> void:
	Signals.trigger_activation_changed.emit(activation_group_id, false)
