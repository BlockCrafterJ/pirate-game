extends ColorRect

@onready var label: Label = $Label

# Called when the node enters the scene tree for the first time.
func set_text_name(player_name, ID) -> void:
	label.text = player_name + " (" + ID + ")"
