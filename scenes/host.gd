extends Node2D

var http = HTTPClient.new() # Create the Client.
var game_id := -1
@onready var label_code: Label = $LabelCode
@onready var tile_map_host: TileMapLayer = $TileMapHost

# Called when the node enters the scene tree for the first time.
func http_connect():
	var err = 0
	http = HTTPClient.new()
	
	err = http.connect_to_host(Global.host, Global.port, Global.tls_options) # Connect to host/port.
	assert(err == OK) # Make sure connection is OK.

	#print("Connecting...")
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
		"Content-Type: text/html",
		"Accept: */*",
		"Pirate-Type: Host",
		"ID: %s" % str(game_id),
		"Command-Type-Pirate: %s" % command,
		#"Cross-grid: %s" % JSON.stringify(tile_map_host.tile_grid)
	]
	#var out_body = {"cross-grid": JSON.stringify(tile_map_host.tile_grid)}
	#out_body = http.query_string_from_dict(out_body)
	#err = http.request(HTTPClient.METHOD_GET, "/host-send?" + out_body, out_headers) # Request a page from the site (this one was chunked...)
	err = http.request(HTTPClient.METHOD_GET, "/server", out_headers)
	#print("Requesting...")
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
		
		if headers.get("command-type-pirate") == "New-ID":
			game_id = int(text)
			label_code.text = "Code: %s" % text
		elif headers.get("command-type-pirate") == "Set-cross-grid":
			tile_map_host.tile_grid = JSON.parse_string(text)
		
		#print(text)

func _ready() -> void:
	Global.become_host()
	get_window().content_scale_size = Vector2(800,600)
	connect_loop()

func connect_loop():
	while true:
		if http.get_status() == HTTPClient.STATUS_CONNECTED:
			await http_request()
		else:
			await http_connect()
		await get_tree().create_timer(0.3).timeout

func _process(_delta: float) -> void:
	pass
	#await get_tree().create_timer(5).timeout

#func place_random_temp():
#	while true:
#		tile_map_host.place_tile_at_random(1)
#		await get_tree().create_timer(1).timeout
