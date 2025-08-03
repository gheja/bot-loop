extends Node

const STATE_INTRO = 1
const STATE_PLAYER_SELECTION = 2
const STATE_RUNNING = 3
const STATE_FINISHED = 4
const STATE_RESTARTING = 5
const STATE_GAME_COMPLETED = 6

var loops = 0
var current_level_index = 0
var auto_select_player_index = -1
var first_loop = true
var play_intro = true
var state = GameState.STATE_INTRO

var player_recordings = []
var reset_recordings_on_start = true
var controls_locked = false
