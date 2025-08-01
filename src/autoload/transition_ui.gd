extends Control

func _ready() -> void:
	Signals.start_transition.connect(_on_start_transition)

func _on_start_transition(color: Color = Color("#262626")):
	$ColorRect.color = color
	$AnimationPlayer.play("transition")

func switch_scene():
	get_tree().reload_current_scene()
