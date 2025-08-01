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
	Signals.set_controls_lock.connect(_on_set_controls_lock)

	timer.timeout.connect(_on_timer_timeout)
	
	GameState.loops += 1
	
	if GameState.loops > 1:
		main_interface.pop_up_big_message("Loop " + str(GameState.loops))
	
	reset_colors()
	
	Signals.set_controls_lock.emit(false)
	
	if GameState.play_intro:
		GameState.play_intro = false
		start_intro_text()
	else:
		start_player_selection()

func start_player_selection():
	# temporarily auto-select
	if GameState.loops == 1:
		set_active_player(1)
	elif GameState.loops == 2:
		set_active_player(2)
	
	start_main_timer()

func set_active_player(index: int):
	var player_obj: ObjectPlayerCharacter = null
	
	for obj in get_tree().get_nodes_in_group("player_objects"):
		obj = obj as ObjectPlayerCharacter
		if obj.player_index == index:
			player_obj = obj
			break
	
	if not player_obj:
		print("Could not find player object by index")
		return
	
	player_obj.make_active()

func start_intro_text():
	var intro_text = ".#.#.#*#Hello world!#\nNice to see you!\n#.#.#.#*#How are you?\n#.#.#.#*Ah, well...\nGood luck!\n#;)#"
	var text = ""
	var ch
	
	for i in intro_text.length():
		ch = intro_text[i]
		
		if ch == "#":
			await get_tree().create_timer(0.5).timeout
			continue
		elif ch == "*":
			text = ""
		else:
			text += ch
		
		Signals.set_display_text.emit(text)
		await get_tree().create_timer(0.05).timeout
	
	start_player_selection()

func start_main_timer():
	timer.start()
	GameState.state = GameState.STATE_RUNNING
	Signals.set_controls_lock.emit(true)
	Signals.update_timer.emit(timer.time_left)
	Signals.timer_started.emit()

func restart_level_with_wait(success: bool):
	await get_tree().create_timer(2.0).timeout
	
	# right before restarting we should save, up until this point the player has
	# a chance to restart the run therefore discarding the recording
	Signals.save_player_recording.emit()
	
	if success:
		Signals.start_transition.emit()
	else:
		Signals.start_transition.emit("#441100")

func _on_set_controls_lock(state: bool):
	GameState.controls_locked = state
	
	if state:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

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
	
	GameState.state = GameState.STATE_FINISHED
	Signals.set_controls_lock.emit(false)
	restart_level_with_wait(true)

func _on_timer_failed():
	main_light.light_color = Color("#ff0000")
	world_environment.environment.ambient_light_color = Color("#ff0088")
	world_environment.environment.ambient_light_energy = 0.1
	
	GameState.state = GameState.STATE_FINISHED
	Signals.set_controls_lock.emit(false)
	restart_level_with_wait(false)
