extends StaticBody3D

@onready var material_running = preload("res://materials/light_strip_running.tres")
@onready var material_stopped = preload("res://materials/light_strip_stopped.tres")
@onready var material_failed = preload("res://materials/light_strip_failed.tres")

func _ready() -> void:
	pass

func set_material_on_obj(name, material):
	var obj = get_node_or_null(name)
	
	if obj:
		(obj as CSGBox3D).material = material

func set_material(material):
	set_material_on_obj("Color1", material)
	set_material_on_obj("Color2", material)
	set_material_on_obj("Color3", material)

func _on_success():
	set_material(material_stopped)
