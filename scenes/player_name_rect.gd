extends ColorRect

@onready var label: Label = $Label
var id := 0
var label_text := "BROKEN ;("

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label.text = label_text

func set_text_name(player_name, ID) -> void:
	id = int(ID)
	label_text = player_name + " (" + ID + ")"


func _on_button_pressed() -> void:
	$"/root/Game".player_id_to_action = id
