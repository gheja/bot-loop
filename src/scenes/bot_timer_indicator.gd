class_name BotTimerIndicator
extends Control

@onready var visuals: Control = $Visuals
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var timer_progress_bar: TextureProgressBar = $Visuals/TimerProgressBar

func _ready() -> void:
	pass

func update_progress_bar(value: float, max: float):
	timer_progress_bar.max_value = max
	timer_progress_bar.value = value
