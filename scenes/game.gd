extends Node2D

signal started

var http = HTTPClient.new() # Create the Client.
var id := -1
var pirate_name: String = ""
var old_cross_tile_grid = []
var money := 0
var money_change := 0
var money_mult := 1
var zero_money := false
var bank := 0
var shield := false:
	set(value):
		if value:
			item_animation_player.play("gain_shield")
			shield = value
		else:
			item_animation_player.play("RESET")
			shield = value
var mirror := false:
	set(value):
		if value:
			item_animation_player.play("gain_mirror")
			mirror = value
		else:
			item_animation_player.play("RESET")
			mirror = value
var player_action = -1
var player_action_queue = -1
var player_previous_action = -1
var cns_action = 0
var player_name_list = []
var player_ID_list = []
var player_name_rects = []
var player_id_to_action := -1
var square_to_action: Vector2i = Vector2i(-1,-1)
var skip_next = 0
var turn_time: float = 0
var game_started: bool = false
@onready var tile_map_cross: TileMapLayer = $TileMapCross
@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var name_label: Label = $Control/VBoxContainerTop/Name
@onready var cash_label: Label = $Control/VBoxContainerBottom/CashLabel
@onready var bank_label: Label = $Control/VBoxContainerBottom/BankLabel
@onready var item_animation_player: AnimationPlayer = $Control/VBoxContainerBottom/GridContainer/AnimationPlayer
@onready var picker: Control = $Picker
@onready var picker_v_box_container: VBoxContainer = $Picker/ColorRect/ScrollContainer/VBoxContainer
@onready var picker_name: Label = $Picker/ColorRect/Name
@onready var choose_next_square: Control = $ChooseNextSquare
@onready var picker_timer: Label = $Picker/ColorRect/Timer
@onready var cns_timer: Label = $ChooseNextSquare/ColorRect/Timer
@onready var turn_timer: Timer = $TurnTimer
const PLAYER_NAME_RECT = preload("res://scenes/player_name_rect.tscn")

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
		#await get_tree().process_frame
	
	if http.get_status() != HTTPClient.STATUS_CONNECTED: # Check if the connection was made successfully.
		return 1

func http_request(command = "Null"):
	var err = 0
	var money_before = money
	# Some headers
	var out_headers = [
		"User-Agent: Pirulo/1.0 (Godot)",
		"Accept: */*",
		"Pirate-type: Player",
		"ID: %s" % str(id),
		"Game-ID: %s" % str(Global.game_ID),
		"Command-type-pirate: %s" % command,
		"Name: %s" % pirate_name,
		"Cash: %s" % str(money),
		"Bank: %s" % str(bank),
		"Player-action: %s" % str(player_action),
		"Player-action-queue: %s" % str(player_action_queue),
		"Player-id-to-action: %s" % str(player_id_to_action),
		"Square-to-action: %s" %  JSON.from_native(square_to_action),
		"Shield: %s" % str(shield),
		"Mirror: %s" % str(mirror)
	]
	if player_id_to_action != -1:
		player_id_to_action = -1
		player_action = -1
	if square_to_action != Vector2i(-1,-1):
		square_to_action = Vector2i(-1,-1)
		player_action = -1
	player_action_queue = -1
	err = http.request(HTTPClient.METHOD_GET, "/server", out_headers) # Request a page from the site (this one was chunked..)
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
			id = int(text)
		elif headers.get("command-type-pirate") == "Set-cross-grid":
			old_cross_tile_grid = tile_map_cross.tile_grid
			tile_map_cross.tile_grid = JSON.parse_string(text)
			
		if headers.get("cash") != null:
			money = int(headers.get("cash"))
			if zero_money:
				money = 0
				zero_money = false
			money += money_change
			money_change = 0
			money *= money_mult
			money_mult = 1
		if headers.get("player-name-list") != null:
			player_name_list = JSON.parse_string(headers.get("player-name-list"))
			player_ID_list = JSON.parse_string(headers.get("player-id-list"))
		if headers.get("skip-next") != null:
			#print(skip_next)
			skip_next += int(headers.get("skip-next"))
			#print(skip_next)
		#if headers.get("Mirror") != null and headers.get("Shield") != null:
		#	shield = bool(headers.get("Shield").lower())
		if headers.get("started") == "True":
			if not game_started:
				started.emit()
			game_started = true
		else:
			game_started = false
		
		if headers.get("turn-time") != null:
			turn_time = float(headers.get("turn-time"))
		
		if headers.get("cns-action") != null:
			cns_action = int(headers.get("cns-action"))
		
		#print(text)

func _ready() -> void:
	randomize()
	pirate_name = Global.pirate_adjectives.pick_random() + " " + Global.pirate_nouns.pick_random()
	connect_loop()

func connect_loop():
	while true:
		if http.get_status() == HTTPClient.STATUS_CONNECTED:
			await http_request()
		else:
			await http_connect()
		await get_tree().create_timer(0.3).timeout

func _process(delta: float) -> void:
	name_label.text = pirate_name + " (" + str(id) + ")"
	cash_label.text = "Cash: %s" % str(money)
	bank_label.text = "Bank: %s" % str(bank)
	tile_map_cross.different_squares = []
	if len(old_cross_tile_grid) > 0:
		if tile_map_cross.tile_grid != old_cross_tile_grid:
			for x in range(len(tile_map_cross.tile_grid)):
				for y in range(len(tile_map_cross.tile_grid)):
					if tile_map_cross.tile_grid[x][y] != old_cross_tile_grid[x][y]:
						tile_map_cross.different_squares.append([x,y])
	old_cross_tile_grid = tile_map_cross.tile_grid
	
	if cns_action == 1:
		player_action = Global.CHOOSE_NEXT_SQUARE
	
	if len(tile_map_cross.different_squares) > 0:
		if skip_next == 0:
			for square in tile_map_cross.different_squares:
				var tile_type: int = tile_map_layer.tile_grid[square[0]][square[1]]
				player_action = -1
				player_id_to_action = -1
				if tile_type == Global.M_200:
					money_change += 200
				elif tile_type == Global.M_1000:
					money_change += 1000
				elif tile_type == Global.M_3000:
					money_change += 3000
				elif tile_type == Global.M_5000:
					money_change += 5000
				elif tile_type == Global.BANK:
					bank = money
					zero_money = true
				elif tile_type == Global.DOUBLE:
					money_mult *= 2
				elif tile_type == Global.BOMB:
					zero_money = true
				elif tile_type == Global.MIRROR:
					mirror = true
				elif tile_type == Global.SHIELD:
					shield = true
				elif tile_type == Global.ROB:
					player_action = Global.ROB
				elif tile_type == Global.KILL:
					player_action = Global.KILL
				elif tile_type == Global.WIPE_OUT:
					player_action = Global.WIPE_OUT
				elif tile_type == Global.SWAP:
					player_action = Global.SWAP
				elif tile_type == Global.CHOOSE_NEXT_SQUARE:
					player_action_queue = Global.CHOOSE_NEXT_SQUARE
				elif tile_type == Global.PRESENT:
					player_action = Global.PRESENT
				turn_timer.start(turn_time)
		else:
			skip_next -= 1
	if player_action == Global.CHOOSE_NEXT_SQUARE:
		choose_next_square.show()
	else:
		choose_next_square.hide()
	
	picker_timer.text = str(int(turn_timer.time_left)+1)
	cns_timer.text = str(int(turn_timer.time_left)+1)
	
	#print("Checkpoint1")
	if player_action != -1 and player_id_to_action == -1 and player_action != Global.CHOOSE_NEXT_SQUARE:
		#print("Checkpoint2")
		match player_action:
			Global.ROB:
				picker_name.text = "Rob someone"
			Global.KILL:
				picker_name.text = "Kill someone"
			Global.WIPE_OUT:
				picker_name.text = "Skip someone's turn"
			Global.SWAP:
				picker_name.text = "Swap money with someone"
			Global.PRESENT:
				picker_name.text = "Give someone a present (1000)"
		if player_name_list != [] and player_previous_action != player_action: 
			player_previous_action = player_action
			picker.set_process(true)
			picker.show()
			for i in range(len(player_name_list)):
				var name_rect = PLAYER_NAME_RECT.instantiate()
				name_rect.set_text_name(player_name_list[i], str(int(player_ID_list[i])))
				player_name_rects.append(name_rect)
				#print(player_name_list[i])
			randomize()
			print(player_name_rects)
			player_name_rects.shuffle()
			print(player_name_rects)
			for name_rect in player_name_rects:
				picker_v_box_container.add_child(name_rect)
	else:
		for rect in player_name_rects:
			rect.queue_free()
			player_name_rects.erase(rect)
		player_previous_action = player_action
		picker.set_process(false)
		picker.hide()
	
