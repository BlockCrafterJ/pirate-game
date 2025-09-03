extends Label


# Called when the node enters the scene tree for the first time.
func set_text_name(player_name, ID) -> void:
	text = player_name + " (" + ID + ")"
