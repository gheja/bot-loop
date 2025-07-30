extends Node3D

@onready var main_interface: MainInterface = $MainInterface

func _ready() -> void:
	Signals.stop_pressed.connect(_on_stop_pressed)
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$Timer.start()

func _process(delta: float) -> void:
	main_interface.update($Timer.time_left)


func _on_stop_pressed():
	print($Timer.time_left)
	$Timer.stop()
