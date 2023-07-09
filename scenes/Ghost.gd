extends Area2D

const DAMAGE = 40;

const not_hit_img = preload("res://assets/ghost.png");
const hit_img = preload("res://assets/ghost_hit.png");

@onready var sprite = $CollisionShape2D/Sprite2D;

var target: = Vector2(0, 0);
var vel: = Vector2(0, 0);
var is_hit: = false;

var speed: float = 200;

func _ready():
	pass # Replace with function body.


func _process(delta):
	if not is_hit:
		var dir = (target-position).normalized();
		position += dir*speed*delta;
	position += vel*delta;
	vel *= 0.9;

# sets the target
func set_target(vec: Vector2):
	target = vec;

# repulses from the position by a given amount
func repulse(pos: Vector2, amt: float):
	vel += (position-pos).normalized()*amt;

# tells the ghost they were hit with a bullet at <pos>
func hit(pos: Vector2):
	repulse(pos, 100);
	is_hit = true;
	sprite.texture = hit_img;
	$StunTimer.start();

func _on_stun_timer_timeout():
	sprite.texture = not_hit_img;
	is_hit = false;

func _on_area_entered(area):
	body_entered.emit(area);

func init(player, ghosts):
	body_entered.connect(func(other: Node2D):
		if other == player:
			if is_hit:
				queue_free();
				player.damage(-20);
			else:
				repulse(other.position, 1000);
				player.repulse(position, 200);
				player.damage(20);
		elif other.get_parent() == ghosts:
			repulse(other.position, 200);
	);
