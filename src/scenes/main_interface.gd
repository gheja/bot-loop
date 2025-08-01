class_name MainInterface
extends CanvasLayer

@onready var timer_label: Label = $MarginContainer/TimerLabel
@onready var big_message_label: Label = $BigMessageLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	big_message_label.modulate = Color(0, 0, 0, 0)

func pop_up_big_message(s: String):
	big_message_label.text = s
	animation_player.play("big_text")

func update(time_left: float):
	timer_label.text = str(time_left).pad_decimals(2)
