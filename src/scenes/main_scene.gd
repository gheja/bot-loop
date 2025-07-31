extends Node3D

@onready var main_interface: MainInterface = $MainInterface
@onready var timer: Timer = $Timer
@onready var timer_starter_timer: Timer = $TimerStarterTimer
@onready var main_light: DirectionalLight3D = $MainLight
@onready var world_environment: WorldEnvironment = $WorldEnvironment

func _ready() -> void:
	Signals.stop_pressed.connect(_on_stop_pressed)
	Signals.timer_started.connect(_on_timer_started)
	Signals.timer_stopped.connect(_on_timer_stopped)
	Signals.timer_failed.connect(_on_timer_failed)

	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	timer.timeout.connect(_on_timer_timeout)
	
	Signals.timer_stopped.emit()
	timer_starter_timer.start()

func _process(delta: float) -> void:
	main_interface.update(timer.time_left)

func _on_timer_timeout():
	Signals.timer_failed.emit()

func _on_stop_pressed():
	timer.stop()
	print(timer.time_left)
	Signals.timer_stopped.emit()

func _on_timer_starter_timer_timeout() -> void:
	Signals.timer_started.emit()
	timer.start()

func _on_timer_started():
	main_light.light_color = Color("#ffcbb5")
	world_environment.environment.ambient_light_color = Color("#dce9ec")
	world_environment.environment.ambient_light_energy = 0.25

func _on_timer_stopped():
	main_light.light_color = Color("#ffffff")
	world_environment.environment.ambient_light_color = Color("#e7ffff")
	world_environment.environment.ambient_light_energy = 0.25

func _on_timer_failed():
	main_light.light_color = Color("#ff0000")
	# world_environment.environment.ambient_light_energy = 0.0
	world_environment.environment.ambient_light_color = Color("#ff0088")
	world_environment.environment.ambient_light_energy = 0.1
