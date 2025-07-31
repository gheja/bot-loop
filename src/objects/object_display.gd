class_name ObjectDisplay
extends Node3D

var text = "Hello world\nNice to see you!"

@onready var label_3d: Label3D = $Label3D

func _ready() -> void:
	Signals.set_display_text.connect(set_text)

func _process(delta: float) -> void:
	pass

func set_text(s: String):
	label_3d.text = s
