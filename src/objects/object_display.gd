class_name ObjectDisplay
extends Node3D

@onready var small_label: Label3D = $SmallLabel
@onready var big_label: Label3D = $BigLabel

func _ready() -> void:
	big_label.hide()
	big_label.text = ""
	small_label.text = ""
	
	Signals.set_display_text.connect(set_text)

func _process(delta: float) -> void:
	pass

func set_text(s: String):
	small_label.text = s
