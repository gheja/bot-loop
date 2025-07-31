class_name ObjectDisplay
extends Node3D

@onready var small_label: Label3D = $SmallLabel
@onready var big_label: Label3D = $BigLabel

func _ready() -> void:
	big_label.hide()
	
	Signals.set_display_text.connect(set_text)
	Signals.timer_started.connect(_on_timer_started)
	Signals.update_timer.connect(_on_update_timer)

func _process(delta: float) -> void:
	pass

func set_text(s: String):
	small_label.text = s

func _on_timer_started():
	small_label.hide()
	big_label.show()

func _on_update_timer(time: float):
	big_label.text = str(time).pad_decimals(2)
