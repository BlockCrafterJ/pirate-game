extends Node2D

var http = HTTPClient.new() # Create the Client.
var id := -1
var pirate_name: String = ""
var old_cross_tile_grid = []
var money := 0
var bank := 0
var shield := false
var mirror := false
@onready var tile_map_cross: TileMapLayer = $TileMapCross
@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var name_label: Label = $Control/VBoxContainer/Name

# Called when the node enters the scene tree for the first time.
func http_connect():
	var err = 0
	http = HTTPClient.new()
	
	err = http.connect_to_host(Global.host, Global.port) # Connect to host/port.
	assert(err == OK) # Make sure connection is OK.

	print("Connecting...")
	# Wait until resolved and connected.
	while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:# or not http.get_status() == HTTPClient.STATUS_CONNECTED:
		http.poll()
		await get_tree().process_frame
	
	if http.get_status() != HTTPClient.STATUS_CONNECTED: # Check if the connection was made successfully.
		return 1

func http_request(command = "Null"):
	var err = 0
	# Some headers
	var out_headers = [
		"User-Agent: Pirulo/1.0 (Godot)",
		"Accept: */*",
		"Pirate-type: Player",
		"ID: %s" % str(id),
		"Game-ID: %s" % str(Global.game_ID),
		"Command-type-pirate: %s" % command,
		"Name: %s" % pirate_name
	]
	err = http.request(HTTPClient.METHOD_GET, "/helloworld", out_headers) # Request a page from the site (this one was chunked..)
	print("Requesting...")
	while http.get_status() == HTTPClient.STATUS_REQUESTING:
		# Keep polling for as long as the request is being processed.
		http.poll()
		await get_tree().process_frame

	#assert(http.get_status() == HTTPClient.STATUS_BODY or http.get_status() == HTTPClient.STATUS_CONNECTED) # Make sure request finished well.

	#print("response? ", http.has_response()) # Site might not have a response.

	if http.has_response():
		# If there is a response...

		var headers = http.get_response_headers_as_dictionary() # Get response headers.
		#print("code: ", http.get_response_code()) # Show response code.
		#print("**headers:\\n", headers) # Show headers.

		# Getting the HTTP Body

		if http.is_response_chunked():
			pass
			# Does it use chunks?
			#print("Response is Chunked!")
		else:
			pass
			# Or just plain Content-Length
			#var bl = http.get_response_body_length()
			#print("Response Length: ", bl)

		# This method works for both anyway
		var rb = PackedByteArray() # Array that will hold the data.

		while http.get_status() == HTTPClient.STATUS_BODY:
			# While there is body left to be read
			http.poll()
			# Get a chunk.
			if http.get_status() == HTTPClient.STATUS_BODY:
				var chunk = http.read_response_body_chunk()
				if chunk.size() == 0:
					await get_tree().process_frame
				else:
					rb = rb + chunk # Append to read buffer.
		# Done!

		#print("bytes got: ", rb.size())
		var text = rb.get_string_from_ascii()
		#print("Text: ", text)
		
		if headers.get("Command-type-pirate") == "New-ID":
			id = int(text)
		elif headers.get("Command-type-pirate") == "Set-cross-grid":
			old_cross_tile_grid = tile_map_cross.tile_grid
			tile_map_cross.tile_grid = JSON.parse_string(text)
		
		print(text)

func _ready() -> void:
	pirate_name = Global.pirate_adjectives.pick_random() + " " + Global.pirate_nouns.pick_random()
	name_label.text = pirate_name
	connect_loop()

func connect_loop():
	while true:
		if http.get_status() == HTTPClient.STATUS_CONNECTED:
			await http_request()
		else:
			await http_connect()
		await get_tree().create_timer(0.3).timeout

func _process(delta: float) -> void:
	var different_squares = []
	if tile_map_cross.tile_grid != old_cross_tile_grid:
		for x in range(len(tile_map_cross.tile_grid)):
			for y in range(len(tile_map_cross.tile_grid)):
				if tile_map_cross.tile_grid[x][y] != old_cross_tile_grid[x][y]:
					different_squares.append([x,y])
	if len(different_squares) > 0:
		for square in different_squares:
			var tile_type : int = tile_map_layer[square[0]][square[1]]
			if tile_type == Global.M_200:
				money += 200
			elif tile_type == Global.M_1000:
				money += 1000
			elif tile_type == Global.M_3000:
				money += 3000
			elif tile_type == Global.M_5000:
				money += 5000
			elif tile_type == Global.BANK:
				bank = money
				money = 0
			elif tile_type == Global.DOUBLE:
				money *= 2
			elif tile_type == Global.BOMB:
				money = 0
			elif tile_type == Global.MIRROR:
				mirror = true
			elif tile_type == Global.SHIELD:
				shield = true
