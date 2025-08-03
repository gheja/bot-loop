class_name MenuInterface
extends CanvasLayer

var first_unpause = true

func _ready():
	self.hide()
	$AnimationPlayer.play("main_menu")

func show2(is_main_menu: bool):
	$PauseContent2.visible = not is_main_menu
	$MainMenuContent.visible = is_main_menu
	AudioManager.start_menu_music()
	self.show()

func _process(delta: float) -> void:
	if self.visible:
		if GameState.state == GameState.STATE_INTRO:
			if Input.is_action_just_pressed("ui_action_start"):
				print("play")
				AudioManager.play_sound(2)
				Signals.unpause.emit()
		else:
			if Input.is_action_just_pressed("ui_action_pause"):
				print("unpause")
				AudioManager.start_main_music()
				AudioManager.play_sound(2)
				Signals.unpause.emit()
	else:
		if Input.is_action_just_pressed("ui_action_pause"):
			print("pause")
			AudioManager.start_menu_music()
			AudioManager.play_sound(2) 
			Signals.pause.emit()
