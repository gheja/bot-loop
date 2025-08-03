extends Node

var music_tween: Tween

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
