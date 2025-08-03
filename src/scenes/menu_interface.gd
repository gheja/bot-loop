class_name MenuInterface
extends CanvasLayer

func _ready():
	self.hide()

func show2(is_main_menu: bool):
	$PauseContent2.visible = not is_main_menu
	$MainMenuContent.visible = is_main_menu
	AudioManager.start_menu_music()
	self.show()

func _process(delta: float) -> void:
	if self.visible:
		if Input.is_action_just_pressed("ui_action_start"):
			AudioManager.start_main_music()
			Signals.unpause.emit()
		elif Input.is_action_just_pressed("ui_action_pause"):
			AudioManager.start_main_music()
			Signals.unpause.emit()
	else:
		if Input.is_action_just_pressed("ui_action_pause"):
			Signals.pause.emit()
