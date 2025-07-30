class_name MainInterface
extends CanvasLayer

@onready var timer_label: Label = $MarginContainer/TimerLabel

func update(time_left: float):
	timer_label.text = str(time_left).pad_decimals(2)
