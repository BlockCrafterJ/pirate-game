extends TileMapLayer

var tile_grid = []
var available_squares = []
var tile_grid_width: int = 7
var tile_grid_height: int = 7
var hovered_cell: Vector2i
@onready var camera_2d: Camera2D = $"../Camera2D"
@onready var texture_rect: TextureRect = $"../ChooseDown/ColorRect/TextureRect"
@onready var desc_label: Label = $"../ChooseDown/ColorRect/DescLabel"
@onready var game: Node2D = $".."
@onready var choose_down: Control = $"../ChooseDown"

var current_tile: int: # Current tile being placed
	set(value):
		texture_rect.texture.region = Rect2((value) * 48, 0, 48, 48)
		desc_label.text = Global.tile_names[value]
		current_tile = value
var current_tile_no: int:
	set(value):
		if value <= 11:
			current_tile = value
		elif value <= 13:
			current_tile = 12
		elif value <= 24:
			current_tile = 13
		else:
			current_tile = 14
		var new_tile = 15
		for tile_line in tile_grid:
			if 15 in tile_line:
				new_tile = current_tile
		current_tile = Global.CHOOSE_NEXT_SQUARE #new_tile
		current_tile_no = value

func place_tile_at_random(tile):
	var _available_selection = randi_range(0, len(available_squares)-1)
	var _current_square = available_squares[_available_selection]
	tile_grid[_current_square[0]][_current_square[1]] = tile
	available_squares.pop_at(_available_selection)

func _ready() -> void:
	for i in tile_grid_width:
		tile_grid.append([])
		for j in tile_grid_height:
			tile_grid[i].append(15)
			available_squares.append(Vector2i(i,j))
	current_tile = 0
	# Special squares + 5000
	#for i in range(12):
	#	place_tile_at_random(i)
	# 3000
	#for i in range(2):
	#	place_tile_at_random(12)
	# 1000
	#for i in range(10):
	#	place_tile_at_random(13)

func _process(_delta: float) -> void:
	for i in range(tile_grid_width):
		for j in range(tile_grid_height):
			set_cell(Vector2i(i,j), 3, Vector2i(tile_grid[i][j], 0))
	
	hovered_cell = local_to_map(get_viewport().get_mouse_position() - global_position + (camera_2d.position - get_viewport_rect().size / 2))
	
func _input(event: InputEvent) -> void:
	#print(15 in tile_grid, tile_grid)
	#print(event.position + (camera_2d.position - get_viewport_rect().size / 2), get_used_rect())
	if event is InputEventMouseButton and event.pressed == false and Rect2(position, Vector2(tile_grid_width, tile_grid_height) * 48).has_point(event.position + (camera_2d.position - get_viewport_rect().size / 2)):
		if game.game_started == false:
			if tile_grid[hovered_cell[0]][hovered_cell[1]] == 15:
				tile_grid[hovered_cell[0]][hovered_cell[1]] = current_tile
				current_tile_no += 1
				available_squares.erase(hovered_cell)
		# Choose next square
		if game.player_action == Global.CHOOSE_NEXT_SQUARE:
			game.square_to_action = hovered_cell


func finish_cells() -> void:
	# Special squares + 5000
	#for i in range(12):
	#	place_tile_at_random(i)
	# 3000
	#for i in range(2):
	#	place_tile_at_random(12)
	# 1000
	#for i in range(10):
	#	place_tile_at_random(13)
	for i in range(49 - current_tile_no):
		place_tile_at_random(current_tile)
		current_tile_no += 1


func _on_game_started() -> void:
	choose_down.hide()
	finish_cells()
