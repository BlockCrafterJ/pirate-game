extends Node2D

var http = HTTPClient.new() # Create the Client.
var game_id := -1
@onready var label_code: Label = $LabelCode
@onready var label_code_picker: Label = $Picker/ColorRect/LabelCode
@onready var tile_map_host: TileMapLayer = $TileMapHost
const PLAYER_NAME_RECT_LOBBY = preload("res://scenes/player_name_rect_lobby.tscn")
@onready var h_flow_container: HFlowContainer = $Picker/ColorRect/ScrollContainer/HFlowContainer
@onready var v_box_container: VBoxContainer = $"Choose Next Square List/Polygon2D/Polygon2D/Control/ScrollContainer/VBoxContainer"
var player_name_list = []
var player_id_list = []
var player_id_list_old = []
var choose_next_square_list = []
var choose_next_square_list_old = []
var started = false
@onready var lobby: Control = $Picker
var message := ""
@onready var status: Label = $Status


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
		"Started: %s" % str(started),
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
			label_code_picker.text = "Code: %s" % text
		elif headers.get("command-type-pirate") == "Set-cross-grid":
			tile_map_host.tile_grid = JSON.parse_string(text)
		if headers.get("player-name-list") != null:
			player_name_list = JSON.parse_string(headers.get("player-name-list"))
			player_id_list_old = player_id_list
			player_id_list = JSON.parse_string(headers.get("player-id-list"))
		if headers.get("choose-next-square-list") != null:
			choose_next_square_list_old = choose_next_square_list
			choose_next_square_list = JSON.parse_string(headers.get("choose-next-square-list"))
		if headers.get("game-message") != null:
			message = headers.get("game-message")
		else:
			message = ""
		
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
	if player_id_list != player_id_list_old:
		player_id_list_old = player_id_list
		for child in h_flow_container.get_children():
			h_flow_container.remove_child(child)
			child.free()
		for i in range(len(player_id_list)):
			var name_rect = PLAYER_NAME_RECT_LOBBY.instantiate()
			h_flow_container.add_child(name_rect)
			name_rect.set_text_name(player_name_list[i], str(int(player_id_list[i])))
	if choose_next_square_list != choose_next_square_list_old:
		choose_next_square_list_old = choose_next_square_list
		for child in v_box_container.get_children():
			v_box_container.remove_child(child)
			child.free()
		for i in range(len(choose_next_square_list)):
			var name_rect = PLAYER_NAME_RECT_LOBBY.instantiate()
			name_rect.anchor_left = 0.0
			name_rect.anchor_right = 1.0
			v_box_container.add_child(name_rect)
			name_rect.set_text_name(player_name_list[player_id_list.find(choose_next_square_list[i])], str(int(choose_next_square_list[i])))
		status.text = message
	#await get_tree().create_timer(5).timeout

#func place_random_temp():
#	while true:
#		tile_map_host.place_tile_at_random(1)
#		await get_tree().create_timer(1).timeout


func _on_start_button_pressed() -> void:
	started = true
	lobby.hide()
