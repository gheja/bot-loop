extends Node3D

@onready var main_interface: MainInterface = $MainInterface
@onready var timer: Timer = $Timer
@onready var main_camera: Camera3D = $MainCamera
@onready var main_light: DirectionalLight3D = $MainLight
@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var level_container: Node3D = $LevelContainer
@onready var intro_animation_player: AnimationPlayer = $IntroStuffs/IntroAnimationPlayer
@onready var intro_camera: Camera3D = $IntroStuffs/IntroCamera

@export var level_list: Array[PackedScene]

var current_level: LevelClass

func _ready() -> void:
	var level = level_list[GameState.current_level_index].instantiate()
	level_container.add_child(level)
	
	current_level = get_tree().get_nodes_in_group("level_root_object")[0]
	
	Signals.stop_pressed.connect(_on_stop_pressed)
	Signals.timer_started.connect(_on_timer_started)
	Signals.timer_stopped.connect(_on_timer_stopped)
	Signals.timer_failed.connect(_on_timer_failed)
	Signals.set_controls_lock.connect(_on_set_controls_lock)

	timer.wait_time = current_level.time_limit
	timer.timeout.connect(_on_timer_timeout)
	
	GameState.loops += 1
	
	clear_controls_help_text()
	reset_colors()
	
	Signals.set_controls_lock.emit(false)
	
	if GameState.play_intro:
		GameState.play_intro = false
		
		if current_level.has_intro:
			# this should really be part of the level, not the main script...
			start_intro()
	else:
		start_player_selection()

func get_available_player_indexes():
	var result = []
	
	for obj in get_tree().get_nodes_in_group("player_objects"):
		result.append((obj as ObjectPlayerCharacter).player_index)
	
	return result

func start_player_selection():
	GameState.state = GameState.STATE_PLAYER_SELECTION
	var player_indexes = get_available_player_indexes()
	
	if player_indexes.size() == 1:
		set_active_player(player_indexes[0])
		return
	
	var s = ""
	
	for i in get_available_player_indexes():
		s += "[" + str(i) + "] "
	
	main_interface.set_controls_label_text("[color=#0f0]Select your robot:\n" + s + "[/color]")

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
	main_interface.set_controls_label_text(
		"[Arrow keys] [W-A-S-D] Move\n[Mouse] Look around\n" +
		"[color=#ff0]" +
		player_obj.controls_help_text +
		"[/color]"
	)
	var player_camera = player_obj.find_child("Camera3D")
	assert(player_camera, "Could not locate player camera")
	follow_camera(player_camera, false)
	
	start_main_timer()

var _camera_to_follow: Camera3D
var _camera_follow_progress = 1.0

func follow_camera(new_camera: Camera3D, snap: bool = false):
	_camera_to_follow = new_camera
	
	if snap:
		_camera_follow_progress  = 1.0
	else:
		_camera_follow_progress = 0.0

func follow_camera_step(delta: float):
	if not _camera_to_follow:
		return
	
	# fixed 1 second transition
	_camera_follow_progress = min(_camera_follow_progress + delta, 1.0)
	
	# this is wildly inaccurate
	main_camera.global_position = main_camera.global_position + (_camera_to_follow.global_position - main_camera.position) * _camera_follow_progress
	main_camera.global_rotation = main_camera.global_rotation + (_camera_to_follow.global_rotation - main_camera.rotation) * _camera_follow_progress

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

func start_intro():
	follow_camera(intro_camera, true)
	intro_animation_player.play("intro")

func start_main_timer():
	if GameState.loops > 1:
		main_interface.pop_up_big_message("Loop " + str(GameState.loops))
	
	timer.start()
	GameState.state = GameState.STATE_RUNNING
	Signals.set_controls_lock.emit(true)
	Signals.update_timer.emit(timer.time_left)
	Signals.timer_started.emit()

func restart_level_with_wait(success: bool):
	# wait with setting the state because the player can still interact now
	
	await get_tree().create_timer(2.0).timeout
	
	GameState.state = GameState.STATE_RESTARTING
	
	# right before restarting we should save, up until this point the player has
	# a chance to restart the run therefore discarding the recording
	Signals.save_player_recording.emit()
	
	if success:
		Signals.start_transition.emit()
	else:
		Signals.start_transition.emit("#441100")

func clear_controls_help_text():
	main_interface.set_controls_label_text("")

func _on_set_controls_lock(state: bool):
	GameState.controls_locked = state
	
	if state:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func restart_pressed():
	if GameState.state == GameState.STATE_RESTARTING:
		return
	
	Signals.start_transition.emit("#330066")

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_action_restart"):
		restart_pressed()
	
	if GameState.state == GameState.STATE_PLAYER_SELECTION:
		for i in get_available_player_indexes():
			if Input.is_action_just_pressed("ui_action_select_" + str(i)):
				set_active_player(i)
	
	follow_camera_step(delta)
	main_interface.update(timer.time_left)
	Signals.update_timer.emit(timer.time_left)

func _on_timer_timeout():
	Signals.timer_failed.emit()

func _on_stop_pressed():
	GameState.current_level_index += 1
	
	clear_controls_help_text()
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
	
	clear_controls_help_text()
	GameState.state = GameState.STATE_FINISHED
	Signals.set_controls_lock.emit(false)
	restart_level_with_wait(true)

func _on_timer_failed():
	main_light.light_color = Color("#ff0000")
	world_environment.environment.ambient_light_color = Color("#ff0088")
	world_environment.environment.ambient_light_energy = 0.1
	
	clear_controls_help_text()
	GameState.state = GameState.STATE_FINISHED
	Signals.set_controls_lock.emit(false)
	restart_level_with_wait(false)

func intro_finished():
	start_player_selection()
