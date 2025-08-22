class_name ObjectGoalButton
extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var state = false
var pressed_by_bot = null


func set_state(value: bool):
	if GameState.state == GameState.STATE_FINISHED:
		return
	
	state = value
	
	if state:
		animation_player.play("pressed")
	else:
		animation_player.play("default")

func _ready() -> void:
	Signals.intro_started.connect(_on_intro_started)
	Signals.bot_was_reset.connect(_on_bot_was_reset)

func on_entered(obj: Node3D):
	if pressed_by_bot:
		return
	
	var bot = Lib.get_parent_of_type(obj, "CharacterBody3D")
	pressed_by_bot = bot
	
	set_state(true)
	Signals.check_win_lose_conditions.emit()

func _on_area_3d_body_entered(body: Node3D) -> void:
	on_entered(body)

func _on_area_3d_area_entered(area: Area3D) -> void:
	on_entered(area)

func _on_intro_started():
	animation_player.play("intro")

func _on_bot_was_reset(bot: ObjectPlayerCharacter):
	if pressed_by_bot == bot:
		pressed_by_bot = null
		set_state(false)
