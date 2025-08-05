class_name MainInterface
extends CanvasLayer

@onready var big_message_label: Label = $BigMessageLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var controls_label: RichTextLabel = $ControlsLabel
@onready var hint_text: RichTextLabel = $HintText
@onready var hint_animation_player: AnimationPlayer = $HintAnimationPlayer

func _ready() -> void:
	Signals.timer_started.connect(_on_timer_started)
	big_message_label.modulate = Color(0, 0, 0, 0)
	hint_text.text = ""

func set_controls_label_text(text: String):
	controls_label.text = text

func pop_up_big_message(s: String):
	big_message_label.text = s
	animation_player.play("big_text")

func warn_blink():
	$WarnBlinkAnimationPlayer.play("warn_blink")

func set_hint(s: String):
	hint_text.modulate = Color(1.0, 1.0, 1.0, 0.0)
	hint_text.text = "[center]" + s + "[/center]"
	hint_animation_player.play("show_hint")

func _on_timer_started():
	hint_text.hide()
