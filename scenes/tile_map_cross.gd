extends TileMapLayer

var tile_grid = []
var tile_grid_width : int = 7
var tile_grid_height : int = 7

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	if len(tile_grid) == tile_grid_width:
		for i in range(tile_grid_width):
			for j in range(tile_grid_height):
				set_cell(Vector2i(i,j), 1, Vector2i(tile_grid[i][j], 0))
