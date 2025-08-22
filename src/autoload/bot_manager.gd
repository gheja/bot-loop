extends Node

var bot_scenes = {
	"hammer": preload("res://objects/player_character_bot_hammer.tscn"),
	"roomba": preload("res://objects/player_character_roomba.tscn"),
	"mini": preload("res://objects/player_character_mini.tscn"),
}

var root: Node3D
var bot_definitions = []
var starter_bot = null

func activate_bot_by_index(index: int):
	bot_definitions[index]["active"] = true
	(bot_definitions[index]["bot"] as ObjectPlayerCharacter).make_active()
	(bot_definitions[index]["bot"] as ObjectPlayerCharacter).visible = true

func activate_starter_bot():
	assert(starter_bot)
	activate_bot_by_index(get_bot_index_by_bot_object(starter_bot))

func get_bot_index_by_bot_object(bot: ObjectPlayerCharacter):
	var i = 0
	for a in bot_definitions:
		if a['bot'] == bot:
			return i
		
		i += 1
	
	assert(false, "Could not find the bot by index?!")

func swap_to_bot(current_bot: ObjectPlayerCharacter, new_bot: ObjectPlayerCharacter, destroy_current: bool):
	# TODO: idea: continue the recording from the current position without restarting?
	
	new_bot.reset_bot()
	new_bot.make_active()
	
	if destroy_current:
		# current_bot.queue_free()
		current_bot.visible = false

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
		
		bot.recording_length = marker.recording_length
		
		root.add_child(obj)
		
		bot.reset_bot()
		
		if marker.activate_on_start and starter_bot == null:
			starter_bot = bot
		
		index += 1
	
	activate_starter_bot()

func deactivate_and_restart_bot_by_index(index: int, was_actively_controlled: bool):
	var bot = bot_definitions[index]['bot'] as ObjectPlayerCharacter
	var last_position = bot.global_position
	
	if was_actively_controlled:
		bot_definitions[index]['previous_recording'] = (bot_definitions[index]['recording'] as Array).duplicate(true)
		bot_definitions[index]['recording'] = bot.current_recording.duplicate(true)
	
	bot_definitions[index]["active"] = false
	
	# NOTE: the latest recording is already stored
	# bot_definitions[index]['bot']['current_recording'] = (bot_definitions[index]['recording'] as Array).duplicate(true)
	
	bot.reset_bot()
	bot.start_playback()
	
	if was_actively_controlled:
		starter_bot.global_position = last_position
		activate_starter_bot()
	

func deactivate_and_restart_bot(bot: ObjectPlayerCharacter, was_actively_controlled: bool):
	deactivate_and_restart_bot_by_index(get_bot_index_by_bot_object(bot), was_actively_controlled)
