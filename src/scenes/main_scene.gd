extends Node3D

@onready var main_interface: MainInterface = $MainInterface
@onready var timer: Timer = $Timer

func _ready() -> void:
	Signals.stop_pressed.connect(_on_stop_pressed)
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	timer.timeout.connect(_on_timer_timeout)
	timer.start()

func _process(delta: float) -> void:
	main_interface.update(timer.time_left)

func _on_timer_timeout():
	Signals.start_transition.emit()

func _on_stop_pressed():
	print(timer.time_left)
	timer.stop()
