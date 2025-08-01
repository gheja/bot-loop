extends StaticBody3D

@export var activation_group_id = 1
var activation_state = false

func _ready() -> void:
	Signals.trigger_activation_changed.connect(_on_trigger_activation_changed)

func handle_new_state():
	$AnimationPlayer.stop()
	
	if activation_state == true:
		$AnimationPlayer.play("door_open")
	else:
		$AnimationPlayer.play("door_close")

func _on_trigger_activation_changed(group_id: int, state: bool):
	if group_id == self.activation_group_id:
		if state == activation_state:
			return
			
		activation_state = state
		
		handle_new_state()
