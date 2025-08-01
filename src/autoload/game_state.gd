extends Node

const STATE_INTRO = 1
const STATE_RUNNING = 2
const STATE_FINISHED = 3

var loops = 0
var play_intro = true
var state = GameState.STATE_INTRO

var player_recordings = [[], []]
var controls_locked = false
