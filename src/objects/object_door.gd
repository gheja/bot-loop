extends StaticBody3D

@export var activation_group_id = 1
var activation_state = false

func _ready() -> void:
	Signals.trigger_activation_changed.connect(_on_trigger_activation_changed)
	$AnimationPlayer.play("main_action")
	$AnimationPlayer.pause()

func handle_new_state():
	var pos = $AnimationPlayer.current_animation_position
	
	if activation_state == true:
		$AnimationPlayer.play()
	else:
		$AnimationPlayer.play_backwards()
	
	$AnimationPlayer.seek(pos)

func _on_trigger_activation_changed(group_id: int, state: bool):
	if group_id == self.activation_group_id:
		# there might be two triggers
		# BUG? when one of the trigger stops it deactivates this
		if state == activation_state:
			return
			
		activation_state = state
		
		handle_new_state()
