class_name BotStartingMarker
extends Marker3D

@export var bot_index: int = -1
@export_enum("hammer", "roomba", "mini") var bot_class = "hammer"
@export var activate_on_start: bool = false
@export var recording_length: float = 10.0
