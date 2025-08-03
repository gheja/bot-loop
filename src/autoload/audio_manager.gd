extends Node

@onready var audio_players: Node = $AudioPlayers

var music_tween: Tween

var sound_effects: Array[AudioStreamPlayer]

const SOUNDS = [
	preload("res://assets/sounds/opengameart_-yd_-_cogs_edit_2.ogg")
]

func _ready():
	$MenuMusicPlayer.volume_linear = 0.0
	$MenuMusicPlayer.play()
	
	$MainMusicPlayer.volume_linear = 0.0
	$MainMusicPlayer.play()

func start_menu_music():
	if music_tween:
		music_tween.kill()
	music_tween = self.create_tween().set_parallel(true)
	music_tween.tween_property($MenuMusicPlayer, "volume_linear", 1.0, 1.0)
	music_tween.tween_property($MainMusicPlayer, "volume_linear", 0.0, 1.0)

func start_main_music():
	if music_tween:
		music_tween.kill()
	music_tween = self.create_tween().set_parallel(true)
	music_tween.tween_property($MenuMusicPlayer, "volume_linear", 0.0, 1.0)
	music_tween.tween_property($MainMusicPlayer, "volume_linear", 1.0, 1.0)

func play_sound(index: int):
	var player = AudioStreamPlayer.new()
	player.stream = SOUNDS[index]
	player.bus = "sfx"
	audio_players.add_child(player)
	player.play()

func _on_audio_player_cleanup_timer_timeout() -> void:
	for obj: AudioStreamPlayer in audio_players.get_children():
		if not obj.playing:
			obj.queue_free()
