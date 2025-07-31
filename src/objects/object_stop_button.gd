extends Node3D

func _on_area_3d_body_entered(body: Node3D) -> void:
	Signals.stop_pressed.emit()

func _on_area_3d_area_entered(area: Area3D) -> void:
	Signals.stop_pressed.emit()
