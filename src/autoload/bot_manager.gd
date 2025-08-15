extends Node

var bot_scenes = {
	"hammer": preload("res://objects/player_character_bot_hammer.tscn"),
	"roomba": preload("res://objects/player_character_roomba.tscn"),
	"mini": preload("res://objects/player_character_mini.tscn"),
}

var root: Node3D
var bot_definitions = []

func activate_bot(index: int, value: bool):
	bot_definitions[index]["active"] = value
	(bot_definitions[index]["bot"] as ObjectPlayerCharacter).make_active()

func setup_bots():
	root = Lib.get_first_node_in_group("player_object_containers")
	for marker in get_tree().get_nodes_in_group("bot_starting_markers"):
		bot_definitions.append({
			"marker": marker,
			"bot": null,
			"recording": [],
			"previous_recording": [],
			"active": false,
		})
	
	var index = 0
	for a in bot_definitions:
		var marker: BotStartingMarker = a["marker"]
		
		var obj: PlayerCharacterSubclass = (bot_scenes[marker.bot_class] as PackedScene).instantiate()
		obj.global_position = marker.global_position
		obj.player_index = marker.bot_index
		
		var bot: ObjectPlayerCharacter = obj.find_child("PlayerCharacterBase")
		a["bot"] = bot
		
		root.add_child(obj)
		
		if marker.activate_on_start:
			activate_bot(index, true)
		
		index += 1

func restart_bot(index: int):
	return
