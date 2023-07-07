extends Node2D

# @onready var noise = FastNoiseLite.new();

const Wall: = preload("res://scenes/Wall.tscn")
const Edge: = preload("res://scenes/Edge.tscn");

const map_width: int = 32;
const map_height: int = 256;
const tile_size: float = 32;

@onready var cam = $Camera;
@onready var player = $Player;

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize();
	generate_map();
	$Player.position = Vector2((map_width*tile_size)/2, -tile_size*5);
	# create edges
	var left_edge = Edge.instantiate();
	var width = left_edge.get_node("CollisionShape2D").scale.x*8;
	left_edge.position.x = -width;
	$Edges.add_child(left_edge);
	var right_edge = Edge.instantiate();
	right_edge.position.x = map_width*tile_size+width;
	$Edges.add_child(right_edge);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	cam.position = player.position;

const noise_scale: float = 20;

func create_tile(tile, x, y):
	var t = tile.instantiate();
	t.position.x = x*tile_size+tile_size/2;
	t.position.y = y*tile_size+tile_size/2;
	$Map.add_child(t);

const min_gap_len = 5;
const max_gap_len = 10;

func generate_map():
	# generate platforms
	var spacing = 0; # spacing between y-layers
	for y in range(map_height):
		if spacing != 0:
			spacing -= 1;
			continue;
		# generate platform with gaps
		var tiles = []
		for i in range(map_width):
			tiles.push_back(1);
		for i in range(2):
			var width = randi()%(max_gap_len-min_gap_len)+min_gap_len;
			var pos = randi()%(map_width-width);
			for j in range(width):
				tiles[j+pos] = 0;
		for x in tiles.size():
			match tiles[x]:
				1:
					create_tile(Wall, x, y);
		spacing = randi()%5+2;
