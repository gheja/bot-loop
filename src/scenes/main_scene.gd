extends Node3D

@onready var main_interface: MainInterface = $MainInterface
@onready var timer: Timer = $Timer
@onready var main_light: DirectionalLight3D = $MainLight
@onready var world_environment: WorldEnvironment = $WorldEnvironment

func _ready() -> void:
	Signals.stop_pressed.connect(_on_stop_pressed)
	Signals.timer_started.connect(_on_timer_started)
	Signals.timer_stopped.connect(_on_timer_stopped)
	Signals.timer_failed.connect(_on_timer_failed)
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	timer.timeout.connect(_on_timer_timeout)
	
	reset_colors()
	start_intro_text()

func start_intro_text():
	var text = ".#.#.#*#Hello world!#\nNice to see you!\n#.#.#.#*#How are you?\n#.#.#.#*Ah, well...\nGood luck!\n#;)#"
	var s = ""
	var c
	
	for i in text.length():
		c = text[i]
		
		if c == "#":
			await get_tree().create_timer(0.5).timeout
			continue
		elif c == "*":
			s = ""
		else:
			s += c
		
		Signals.set_display_text.emit(s)
		await get_tree().create_timer(0.05).timeout
	
	start_main_timer()

func start_main_timer():
	timer.start()
	Signals.update_timer.emit(timer.time_left)
	Signals.timer_started.emit()

func restart_level_with_wait():
	await get_tree().create_timer(2.0).timeout
	Signals.start_transition.emit()

func _process(delta: float) -> void:
	main_interface.update(timer.time_left)
	Signals.update_timer.emit(timer.time_left)

func _on_timer_timeout():
	Signals.timer_failed.emit()

func _on_stop_pressed():
	timer.stop()
	Signals.timer_stopped.emit()

func _on_timer_started():
	main_light.light_color = Color("#ffcbb5")
	world_environment.environment.ambient_light_color = Color("#dce9ec")
	world_environment.environment.ambient_light_energy = 0.25

func reset_colors():
	main_light.light_color = Color("#ffffff")
	world_environment.environment.ambient_light_color = Color("#e7ffff")
	world_environment.environment.ambient_light_energy = 0.25

func _on_timer_stopped():
	reset_colors()
	
	restart_level_with_wait()

func _on_timer_failed():
	main_light.light_color = Color("#ff0000")
	world_environment.environment.ambient_light_color = Color("#ff0088")
	world_environment.environment.ambient_light_energy = 0.1
	
	restart_level_with_wait()
