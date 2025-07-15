extends Node2D

var http = HTTPClient.new()
var game_ID_test = 0
var switch_to_game = false
@onready var code_label: Label = $Control/VBoxContainer/CodeLabel
@onready var line_edit: LineEdit = $Control/VBoxContainer/LineEdit
@onready var button: Button = $Control/VBoxContainer/Button

func http_connect():
	var err = 0
	http = HTTPClient.new()
	
	err = http.connect_to_host(Global.host, Global.port) # Connect to host/port.

	print("Connecting...")
	# Wait until resolved and connected.
	while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:# or not http.get_status() == HTTPClient.STATUS_CONNECTED:
		http.poll()
		await get_tree().process_frame
	
	if http.get_status() != HTTPClient.STATUS_CONNECTED: # Check if the connection was made successfully.
		show_text("Could not connect to server.")
		return 1

func http_request(command = "Null"):
	var err = 0
	# Some headers
	var out_headers = [
		"User-Agent: Pirulo/1.0 (Godot)",
		"Accept: */*",
		"Pirate-type: ID-query",
		"ID: %s" % game_ID_test,
		"Command-type-pirate: %s" % command
	]
	err = http.request(HTTPClient.METHOD_GET, "/helloworld", out_headers) # Request a page from the site (this one was chunked..)
	print("Requesting...")
	while http.get_status() == HTTPClient.STATUS_REQUESTING:
		# Keep polling for as long as the request is being processed.
		http.poll()
		await get_tree().process_frame
		print("h\nh\nh")
	
	if err != 0:
		show_text("Could not send request to server.")
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
		print(2)
		#print("bytes got: ", rb.size())
		var text = rb.get_string_from_ascii()
		#print("Text: ", text)
		
		if headers.get("ID-exists") == "Yes":
			Global.game_ID = game_ID_test
			switch_to_game = true
		else:
			show_text("Game does not exist.")
		
		print(text)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	code_label.text = ""
	if OS.get_cmdline_args().has("--host"):
		get_tree().change_scene_to_file("res://scenes/host.tscn")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func show_text(text) -> void:
	code_label.text = text


func _input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_ENTER):
		_on_button_pressed()


func _on_button_pressed() -> void:
	var only_numbers = true
	game_ID_test = line_edit.text
	button.disabled = true
	for letter in game_ID_test:
		if not (letter.unicode_at(0) >= 48 and letter.unicode_at(0) <= 57):
			only_numbers = false
	
	if only_numbers:
		for i in range(3):
			if http.get_status() == HTTPClient.STATUS_CONNECTED and switch_to_game == false:
				show_text("Requesting...")
				await http_request()
			else:
				show_text("Connecting...")
				await http_connect()
	else:
		show_text("Please only enter numbers")
	if switch_to_game:
		show_text("Loading...")
		get_tree().change_scene_to_file("res://scenes/game.tscn")
	button.disabled = false
