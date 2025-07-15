extends ColorRect

var player_name := ""
var ID := ""
@onready var label: Label = $Label

# Called when the node enters the scene tree for the first time.
func _update() -> void:
	label.text = player_name + " (" + ID + ")"
