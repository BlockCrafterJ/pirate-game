extends TileMapLayer

var tile_grid = []
var available_squares = []
var tile_grid_width : int = 7
var tile_grid_height : int = 7

func place_tile_at_random(tile):
	if len(available_squares) > 0:
		var _available_selection = randi_range(0, len(available_squares)-1)
		var _current_square = available_squares[_available_selection]
		tile_grid[_current_square[0]][_current_square[1]] = tile
		available_squares.pop_at(_available_selection)
		return 0
	else:
		return 1

func _ready() -> void:
	for i in tile_grid_width:
		tile_grid.append([])
		for j in tile_grid_height:
			tile_grid[i].append(0)
			available_squares.append(Vector2i(i,j))

func _process(_delta: float) -> void:
	for i in range(tile_grid_width):
		for j in range(tile_grid_height):
			set_cell(Vector2i(i,j), 1, Vector2i(tile_grid[i][j], 0))
