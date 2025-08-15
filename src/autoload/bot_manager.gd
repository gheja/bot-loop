extends Node

var bot_scenes = {
	"hammer": preload("res://objects/player_character_bot_hammer.tscn"),
	"roomba": preload("res://objects/player_character_roomba.tscn"),
	"mini": preload("res://objects/player_character_mini.tscn"),
}

var root: Node3D
var bot_definitions = []

func setup_bots():
	root = Lib.get_first_node_in_group("player_object_containers")
	for marker in get_tree().get_nodes_in_group("bot_starting_markers"):
		bot_definitions.append({
			"marker": marker,
			"bot": null,
			"recording": [],
			"previous_recording": [],
		})
	
	for a in bot_definitions:
		var obj: PlayerCharacterSubclass = (bot_scenes[a["marker"].bot_class] as PackedScene).instantiate()
		obj.global_position = a["marker"].global_position
		obj.player_index = a["marker"].bot_index
		
		var bot: ObjectPlayerCharacter = obj.find_child("PlayerCharacterBase")
		a["bot"] = bot
		
		root.add_child(obj)

func restart_bot(index: int):
	return
