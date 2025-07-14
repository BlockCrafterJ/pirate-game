extends TileMapLayer

var tile_grid = []
var available_squares = []
var tile_grid_width : int = 7
var tile_grid_height : int = 7

func place_tile_at_random(tile):
	var _available_selection = randi_range(0, len(available_squares)-1)
	var _current_square = available_squares[_available_selection]
	tile_grid[_current_square[0]][_current_square[1]] = tile
	available_squares.pop_at(_available_selection)

func _ready() -> void:
	for i in tile_grid_width:
		tile_grid.append([])
		for j in tile_grid_height:
			tile_grid[i].append(14)
			available_squares.append(Vector2i(i,j))
	# Special squares + 5000
	for i in range(12):
		place_tile_at_random(i)
	# 3000
	for i in range(2):
		place_tile_at_random(12)
	# 1000
	for i in range(10):
		place_tile_at_random(13)

func _process(_delta: float) -> void:
	for i in range(tile_grid_width):
		for j in range(tile_grid_height):
			set_cell(Vector2i(i,j), 3, Vector2i(tile_grid[i][j], 0))
