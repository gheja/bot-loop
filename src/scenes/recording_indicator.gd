class_name RecordingIndicator
extends Control

@onready var visuals: Control = $Visuals
@onready var record_progress_bar: TextureProgressBar = $Visuals/RecordProgressBar
@onready var save_progress_bar: TextureProgressBar = $Visuals/SaveProgressBar
@onready var rich_text_label: RichTextLabel = $Visuals/RichTextLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	# visuals.hide()
	set_record_progress(0.0, 1.0)
	set_save_progress(0.0, 1.0)
	set_status_text("Standby")
	
	Signals.stop_pressed.connect(_on_stop_pressed)
	Signals.timer_started.connect(_on_timer_started)
	Signals.timer_stopped.connect(_on_timer_stopped)
	Signals.timer_failed.connect(_on_timer_failed)

func set_status_text(message: String):
	rich_text_label.text = "[center]" + message + "[/center]"

func set_record_progress(value: float, max: float):
	record_progress_bar.max_value = max
	record_progress_bar.value = value

func set_save_progress(value: float, max: float):
	save_progress_bar.max_value = max
	save_progress_bar.value = value

func _on_stop_pressed():
	pass

func _on_timer_started():
	animation_player.play("recording")
	set_status_text("Recording...")

func _on_timer_stopped():
	animation_player.play("finished")
	set_status_text("Saved!")

func _on_timer_failed():
	animation_player.play("saving")
	set_status_text("Saving...")
