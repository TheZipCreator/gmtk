extends Node2D

const Wall: = preload("res://scenes/Wall.tscn")
const Edge: = preload("res://scenes/Edge.tscn");
const Ghost:  = preload("res://scenes/Ghost.tscn");
const Bullet:  = preload("res://scenes/Bullet.tscn");

# map info
const map_width: int = 32;
const map_height: int = 256;
const tile_size: float = 32;

# camera and player
@onready var cam = $Camera;
@onready var player = $Player;

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

func _process(delta):
	cam.position = player.position;
	# update ghosts
	for ghost in $Ghosts.get_children():
		ghost.target = player.position;

const noise_scale: float = 20;

# creates a tile at (x, y)
func create_tile(tile, x, y):
	var t = tile.instantiate();
	t.position.x = x*tile_size+tile_size/2;
	t.position.y = y*tile_size+tile_size/2;
	$Map.add_child(t);

# gap settings
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


# ghost spawning
func _on_ghost_timer_timeout():
	var ghost = Ghost.instantiate();
	ghost.position = Vector2(
		-tile_size if randi()%2 == 0 else map_width*tile_size+tile_size,
		player.position.y
	);
	ghost.body_entered.connect(func(other: Node2D):
		if other == player:
			ghost.repulse(other.position, 1000);
			if ghost.is_hit:
				ghost.queue_free();
	);
	$Ghosts.add_child(ghost);

func _on_player_shoot():
	var size = get_viewport_rect().size;
	var dir = (get_global_mouse_position()-player.position).normalized();
	var bullet = Bullet.instantiate();
	bullet.velocity = dir*100;
	bullet.position = player.position+dir*tile_size*1.5;
	bullet.hit.connect(_on_bullet_hit);
	$Bullets.add_child(bullet);

func _on_bullet_hit(bullet, pos: Vector2, other: Node2D):
	var parent = other.get_parent();
	if parent == $Ghosts:
		other.hit(pos);
		bullet.queue_free();
	if parent.get_parent() == $Map:
		bullet.queue_free();

func _on_player_sucking(object):
	if object.get_parent() == $Ghosts:
		object.repulse(player.position, -40);
