extends Node3D

@onready var material_running = preload("res://materials/goal_running.tres")
@onready var material_completed = preload("res://materials/goal_completed.tres")
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var area_3d: Area3D = $Area3D

func _ready() -> void:
	Signals.level_completed.connect(_on_level_completed)
	set_material(material_running)

func set_material_on_obj(name, material):
	var obj = get_node_or_null(name)
	
	if obj:
		(obj as GeometryInstance3D).material = material

func set_material(material):
	set_material_on_obj("CenterCylinder", material)

func _on_level_completed():
	animation_player.play("completed")
	set_material(material_completed)

func _on_area_3d_area_entered(area: Area3D) -> void:
	if GameState.state != GameState.STATE_FINISHED:
		return
	
	Signals.goal_block_reached.emit()
