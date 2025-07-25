extends Node

var game_ID = 0
var host = "pirate-game.veritatem.space" 
#var host = "localhost"
var port = 443
#var port = 8080
var tls_options = TLSOptions.client()
#var tls_options = null
enum {ROB, KILL, PRESENT, WIPE_OUT, SWAP, CHOOSE_NEXT_SQUARE, 
SHIELD, MIRROR, BOMB, DOUBLE, BANK, M_5000, M_3000, M_1000, M_200}

var pirate_adjectives = [
	"Salty",
	"Brave",
	"Golden",
	"Cheeky",
	"Fearless",
	"Merry",
	"Witty",
	"Stormy",
	"Jolly",
	"Clever",
	"Sneaky",
	"Loyal",
	"Cunning",
	"Rusty",
	"Bold",
	"Rowdy",
	"Perky",
	"Nimble",
	"Curious",
	"Gritty",
	"Daring",
	"Honest",
	"Whistling",
	"Howling",
	"Tidy",
	"Shiny",
	"Friendly",
	"Lucky",
	"Reckless",
	"Crafty",
	"Spunky",
	"Gentle",
	"Thundering",
	"Fearsome",
	"Soggy",
	"Snappy"
]
var pirate_nouns = [
	"Sailor",
	"Buccaneer",
	"Galleon",
	"Corsair",
	"First Mate",
	"Mariner",
	"Wrecker",
	"Swashbuckler",
	"Jibber",
	"Captain",
	"Scallywag",
	"Lookout",
	"Cutlass",
	"Rigger",
	"Bootstrapper",
	"Tracker",
	"Rover",
	"Parrot",
	"Navigator",
	"Barnacle",
	"Deckhand",
	"Crows Nest",
	"Anchor",
	"Helmsperson",
	"Map Reader",
	"Coin Collector",
	"Treasure Hunter",
	"Sea Dog",
	"Spyglass",
	"Compass",
	"Powder Monkey",
	"Hull Scrubber",
	"Cannon Mate",
	"Rope Coiler",
	"Tidal Chaser",
	"Flag Raiser",
	"Dock Runner",
	"Wave Watcher"
]

func become_host():
	if host == "pirate-game.veritatem.space":
		host = "pirate-game-host.veritatem.space"
