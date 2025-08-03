class_name MenuInterface
extends CanvasLayer

var first_unpause = true

func _ready():
	self.hide()

func show2(is_main_menu: bool):
	$PauseContent2.visible = not is_main_menu
	$MainMenuContent.visible = is_main_menu
	AudioManager.start_menu_music()
	self.show()

func _process(delta: float) -> void:
	# TODO: lots of stuffs here could be avoided by handling state in one place...
	if self.visible:
		if Input.is_action_just_pressed("ui_action_start"):
			# don't start the main music when leaving the main menu
			if first_unpause:
				first_unpause = false
			else:
				AudioManager.start_main_music()
			AudioManager.play_sound(2)
			Signals.unpause.emit()
		elif Input.is_action_just_pressed("ui_action_pause"):
			first_unpause = false
			AudioManager.start_main_music()
			AudioManager.play_sound(2)
			Signals.unpause.emit()
	else:
		if Input.is_action_just_pressed("ui_action_pause"):
			AudioManager.play_sound(2)
			Signals.pause.emit()
