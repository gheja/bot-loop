class_name DebugInterface
extends CanvasLayer

@onready var debug_label: Label = $MarginContainer/DebugLabel

var delta_times = []
func _physics_process(delta: float) -> void:
	delta_times.append(delta)

func update_debug_label():
	if delta_times.size() == 0:
		return
	
	var total: float = 0
	var average: float = 0
	var arr = delta_times.slice(max(0, delta_times.size() - 30), delta_times.size())
	var s = ""
	
	for t in arr:
		total += t
	
	average = total / arr.size()
	
	for t in arr:
		s += str(t).pad_decimals(4) + "\n"
	
	s += "\n"
	s += "avg: " + str(average).pad_decimals(4) + " (" + (str(1/average).pad_decimals(2)) + " FPS)"
	
	debug_label.text = s

func _on_timer_timeout() -> void:
	update_debug_label()
