extends Node3D

@onready var main_interface: MainInterface = $MainInterface
@onready var main_camera: Camera3D = $MainCamera
@onready var main_light: DirectionalLight3D = $MainLight
@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var level_container: Node3D = $LevelContainer
@onready var intro_animation_player: AnimationPlayer = $IntroStuffs/IntroAnimationPlayer
@onready var intro_camera: Camera3D = $IntroStuffs/IntroCamera
@onready var menu_interface: MenuInterface = $MenuInterface

var completed_interface_scene = preload("res://scenes/completed_interface.tscn")

@export var level_list: Array[PackedScene]

var current_level: LevelClass

func _ready() -> void:
	# first thing to do, even before the robots exist
	if GameState.reset_recordings_on_start:
		# TODO: hackish, if we have more robots, then add more arrays here
		GameState.player_recordings = [[],[],[],[],[],[]]
		GameState.reset_recordings_on_start = false
		
	var level = level_list[GameState.current_level_index].instantiate()
	level_container.add_child(level)
	
	current_level = Lib.get_first_node_in_group("level_root_object")
	
	Signals.set_controls_lock.connect(_on_set_controls_lock)
	Signals.pause.connect(_on_pause)
	Signals.unpause.connect(_on_unpause)
	Signals.update_music.connect(_on_update_music)
	Signals.set_active_camera.connect(_on_set_active_camera)
	Signals.check_win_lose_conditions.connect(_on_check_win_lose_conditions)
	Signals.level_completed.connect(_on_level_completed)
	Signals.goal_block_reached.connect(_on_goal_block_reached)
	Signals.bot_was_activated.connect(_on_bot_was_activated)
	Signals.bot_was_deactivated.connect(_on_bot_was_deactivated)
	
	GameState.loops += 1
	
	clear_controls_help_text()
	reset_colors()
	
	Signals.set_controls_lock.emit(false)
	
	BotManager.setup_bots()
	
	init_level()
	update_music()
	
	# NOTE: the intro will trigger the main menu

func update_music():
	if get_tree().paused:
		AudioManager.start_menu_music()
	elif GameState.state == GameState.STATE_RUNNING:
		AudioManager.start_main_music()
	else:
		AudioManager.start_menu_music()

func activate_level_camera(snap: bool):
	var level_camera = level_container.get_child(0).find_child("LevelCamera3D")
	assert(level_camera, "Could not locate level camera")
	Signals.set_active_camera.emit(level_camera, snap)

func show_main_menu():
	# menu_interface.show()
	menu_interface.show2(true)
	get_tree().paused = true

func init_level():
	if GameState.play_intro:
		GameState.play_intro = false
		
		if current_level.has_intro:
			# this should really be part of the level, not the main script...
			start_intro()
		else:
			start_current_level()
	else:
		start_current_level()

func start_current_level():
	GameState.state = GameState.STATE_RUNNING
	
	Signals.set_controls_lock.emit(true)
	
	# show the hint for this level
	var level_obj: LevelClass = level_container.get_child(0).find_child("LevelBase")
	main_interface.set_hint(level_obj.hint_text)
	
	BotManager.activate_starter_bot()

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
	
	# some ease with the transition (might be still too fast)
	_camera_follow_progress = min(_camera_follow_progress + delta * 0.25, 1.0)
	
	# this is wildly inaccurate
	main_camera.global_position = main_camera.global_position + (_camera_to_follow.global_position - main_camera.position) * _camera_follow_progress
	main_camera.global_rotation = main_camera.global_rotation + (_camera_to_follow.global_rotation - main_camera.rotation) * _camera_follow_progress

func start_intro_text():
	var intro_text = "#Hey!\n.#.#.#*Are you still\nthere?\n.#.#.#*Nevermind, I\nwill just reboot\nthis thing.#.#.#*Push the STOP\nbutton if you're\nthere.#.#.#"
	var text = ""
	var ch
	
	for i in intro_text.length():
		ch = intro_text[i]
		
		if ch == "#":
			await get_tree().create_timer(0.25).timeout
			continue
		elif ch == "*":
			text = ""
		else:
			text += ch
		
		Signals.set_display_text.emit(text)
		await get_tree().create_timer(0.05).timeout

func start_intro():
	Signals.set_active_camera.emit(intro_camera, true)
	intro_animation_player.play("intro")
	Signals.intro_started.emit()

func start_main_timer():
	if GameState.loops > 1:
		main_interface.pop_up_big_message("Loop " + str(GameState.loops))
	
	GameState.state = GameState.STATE_RUNNING
	Signals.set_controls_lock.emit(true)
	update_music()

func restart_level_with_wait(success: bool):
	# wait with setting the state because the player can still interact now
	
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
		# BUG: there is a bug with handling mouse events over Remote Desktop,
		# see: https://github.com/godotengine/godot/issues/95501
		# tldr: use MOUSE_MODE_CONFINED over Remote Desktop
		
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		# Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func restart_pressed():
	if GameState.state == GameState.STATE_RESTARTING:
		return
	
	Signals.start_transition.emit("#330066")

func _process(delta: float) -> void:
	if GameState.state == GameState.STATE_RUNNING:
		if Input.is_action_just_pressed("ui_action_back"):
			BotManager.deactivate_and_restart_bot_by_index(BotManager.get_active_bot_index(), true)
		if Input.is_action_just_pressed("ui_action_restart"):
			BotManager.restart_active_bot()
	
	follow_camera_step(delta)

func prepare_for_next_level():
	GameState.reset_recordings_on_start = true
	GameState.current_level_index += 1

func show_game_completed():
	GameState.state = GameState.STATE_GAME_COMPLETED
	var obj = completed_interface_scene.instantiate()
	get_tree().root.add_child(obj)

func level_completed():
	if level_list.size() == GameState.current_level_index + 1:
		show_game_completed()
	else:
		prepare_for_next_level()
	
	clear_controls_help_text()

func reset_colors():
	main_light.light_color = Color("#ffffff")
	world_environment.environment.ambient_light_color = Color("#e7ffff")
	world_environment.environment.ambient_light_energy = 0.25

func _on_pause():
	menu_interface.show2(false)
	get_tree().paused = true
	Signals.set_controls_lock.emit(false)

func _on_unpause():
	menu_interface.hide()
	get_tree().paused = false
	
	# NOTE: we should store and restore the state before, but this is still good enough for now
	Signals.set_controls_lock.emit(true)

func show_main_menu_if_needed():
	if GameState.first_loop:
		GameState.first_loop = false
		show_main_menu()

func intro_finished():
	start_current_level()

var _last_time = -1
func _on_update_timer(time: float):
	if GameState.state != GameState.STATE_RUNNING:
		return
	
	if floor(time) != floor(_last_time):
		# print(time)
		if int(floor(time)) in [2,1,0]:
			AudioManager.play_sound(3)
			main_interface.warn_blink()
	
	_last_time = time

func _on_update_music():
	update_music()

func _on_set_active_camera(camera: Camera3D, snap: bool):
	follow_camera(camera, snap)

func _on_check_win_lose_conditions():
	var win = true
	
	for button: ObjectGoalButton in get_tree().get_nodes_in_group("goal_buttons"):
		if button.state != true:
			win = false
			break
	
	if win:
		Signals.level_completed.emit()

func _on_level_completed():
	main_light.light_color = Color("#ddffdd")
	world_environment.environment.ambient_light_color = Color("#ddeeff")
	world_environment.environment.ambient_light_energy = 0.25
	
	GameState.state = GameState.STATE_FINISHED

	if GameState.current_level_index < 3:
		main_interface.set_hint("[b]Hint[/b]: Nice job! Now go to the green portal.")

func _on_goal_block_reached():
	# prepare_for_next_level()
	level_completed()
	restart_level_with_wait(true)

func _on_bot_was_activated(bot: ObjectPlayerCharacter):
	# for tutorial purposes
	if GameState.current_level_index == 0 and bot.bot_class == "hammer":
		main_interface.set_hint("[b]Hint[/b]: All Bots have limited time to operate, after that\nthey will replay your moves.")

func _on_bot_was_deactivated(bot: ObjectPlayerCharacter):
	# for tutorial purposes
	if GameState.current_level_index == 0 and bot.bot_class == "hammer":
		main_interface.set_hint("[b]Hint[/b]: You can use them again anytime.")
