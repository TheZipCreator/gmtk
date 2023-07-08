extends Node2D

const Wall: = preload("res://scenes/Wall.tscn");
const Lava: = preload("res://scenes/Lava.tscn");
const Spikes: = preload("res://scenes/Spikes.tscn");

const Edge: = preload("res://scenes/Edge.tscn");
const Ghost:  = preload("res://scenes/Ghost.tscn");
const Bullet:  = preload("res://scenes/Bullet.tscn");

# map info
const map_width: int = 32;
const map_height: int = 256;
const tile_size: float = 32;

# nodes
@onready var cam = $Camera;
@onready var player = $Player;
@onready var hud = $Camera/CanvasLayer;

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
	hud.get_node("Died").hide();

func _process(delta):
	cam.position = player.position;
	# update ghosts
	for ghost in $Ghosts.get_children():
		ghost.target = player.position;
	# update health
	hud.get_node("Health").text = "Health: "+str(player.health);
	if player.died and Input.is_action_pressed("jump"):
		get_tree().change_scene_to_packed(preload("res://scenes/Game.tscn"));

const noise_scale: float = 20;

# creates a tile at (x, y)
func create_tile(tile, x, y, variant = null):
	var t = tile.instantiate();
	t.position.x = x*tile_size+tile_size/2;
	t.position.y = y*tile_size+tile_size/2;
	if variant != null:
		t.set_variant(variant);
	if tile == Lava or tile == Spikes:
		t.get_node("Area2D").body_entered.connect(func(body):
			if body == player:
				body.damage(100);
				body.velocity.y = -500;
		);
	$Map.add_child(t);

enum Tile { AIR, WALL, LAVA, SPIKES };

func generate_map():
	# map array
	var map = [];
	for x in range(map_width):
		var arr = [];
		arr.resize(map_height);
		arr.fill(Tile.AIR);
		map.push_back(arr);
	var get_tile = func(x, y):
		if x < 0 or x >= map_width:
			return Tile.WALL;
		if y < 0 or y >= map_height:
			return Tile.AIR;
		return map[x][y];
	var set_tile = func(x, y, tile):
		if x < 0 or x >= map_width or y < 0 or y >= map_height:
			return;
		map[x][y] = tile;
	# generate platforms
	var spacing = 0; # spacing between y-layers
	# amounts of walls left or right
	var wall_left = 1;
	var wall_right = 1;
	for y in range(map_height):
		if spacing != 0:
			spacing -= 1;
		else:
			# generate platform with gaps
			var tiles = []
			for i in range(map_width):
				tiles.push_back(0);
			var types = [1, 5, 1, 5, 1, 5, 1, 2, 2, 4, 4, 0]; # types of terrain generated
			# min and max sizes of given types
			const type_sizes = [
				[2, 10],
				[5, 10],
				[1, 4],
				[0, 0],
				[1, 4],
				[2, 10]
			]
			for i in range(types.size()):
				var size = type_sizes[types[i]];
				var width = randi()%(size[1]-size[0])+size[0];
				var pos = randi()%(map_width-width);
				for j in range(width):
					tiles[j+pos] = types[i];
			# make sure lava doesn't neighbor air, and also make square edges
			for i in range(tiles.size()):
				if tiles[i] != 2:
					continue;
				for off in [-1, 1]:
					var io = i+off;
					if io < 0 and io >= tiles.size():
						continue;
					if tiles[io] != 2:
						tiles[io] = 3;
			for x in tiles.size():
				match tiles[x]:
					1:
						set_tile.call(x, y, Tile.WALL);
					2:
						set_tile.call(x, y, Tile.LAVA);
						set_tile.call(x, y+1, Tile.WALL);
					3:
						set_tile.call(x, y, Tile.WALL);
						set_tile.call(x, y+1, Tile.WALL);
					4:
						
						if get_tile.call(x, y-1) == Tile.AIR:
							set_tile.call(x, y, Tile.SPIKES);
						set_tile.call(x, y, Tile.WALL);
					5:
						if get_tile.call(x, y-1) == Tile.AIR:
							set_tile.call(x, y-1, Tile.WALL);
						set_tile.call(x, y, Tile.WALL);
			spacing = randi()%5+4;
		# place left and right walls
		const WALL_CHANGE_CHANCE = 0.5;
		const MAX_WALL_SIZE = 2;
		for x in range(wall_left):
			map[x][y] = Tile.WALL;
		for x in range(wall_right):
			map[map_width-1-x][y] = Tile.WALL;
		if randf() < WALL_CHANGE_CHANCE:
			wall_left += (randi()%3)-1;
			wall_left = clamp(wall_left, 0, MAX_WALL_SIZE);
		if randf() < WALL_CHANGE_CHANCE:
			wall_right += (randi()%3)-1;
			wall_right = clamp(wall_right, 0, MAX_WALL_SIZE);
	for x in range(map_width):
		for y in range(map_height):
			match get_tile.call(x, y):
				Tile.WALL:
					# up down left right
					const variants = [
						5, 1, 2, 7, #
						5, 1, 2, 7, #  down
						6, 3, 4, 17, # up
						6, 3, 4, 17, # up down
					];
					var variant = variants[
						int(get_tile.call(x+1, y) == Tile.WALL) |
						int(get_tile.call(x-1, y) == Tile.WALL) << 1 |
						int(get_tile.call(x, y+1) == Tile.WALL) << 2 |
						int(get_tile.call(x, y-1) == Tile.WALL) << 3
					];
					create_tile(Wall, x, y, variant);
				Tile.LAVA:
					create_tile(Lava, x, y);
				Tile.SPIKES:
					create_tile(Spikes, x, y);


# ghost spawning
func _on_ghost_timer_timeout():
	var ghost = Ghost.instantiate();
	ghost.position = Vector2(
		-tile_size if randi()%2 == 0 else map_width*tile_size+tile_size,
		player.position.y+(randi()%2000)-1000
	);
	ghost.body_entered.connect(func(other: Node2D):
		if other == player:
			ghost.repulse(other.position, 1000);
			if ghost.is_hit:
				ghost.queue_free();
			else:
				player.damage(20);
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

func _on_player_die():
	hud.get_node("Died").show();
	hud.get_node("Health").hide();
