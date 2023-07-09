extends Area2D

const Ghost = preload("res://scenes/Ghost.tscn");

var velocity: Vector2 = Vector2(0, 0);
var player: Node2D;
var ghosts: Node2D;
var center: Vector2;
var target;

var hits = 0;

signal died();

var times: float; # used for various things

enum State {
	INACTIVE, # before the bossfight has begun
	GHOSTS, # when the boss is creating ghosts
	CHARGE, # when the boss is charging at the player
	PASSIVE, # when the boss is passively staying in the center
}

var anims = [
	[0, 1, 2, 3, 4, 5, 6],
	[7, 7, 7, 8, 9, 10, 11, 12],
	[13, 14, 15, 16]
];

var anim = -1;
var anim_frame = 0;

var state: = State.INACTIVE;

func _ready():
	pass # Replace with function body.

# should be called after instantiation
func init(player, center, ghosts):
	self.player = player;
	self.center = center;
	self.ghosts = ghosts;
	target = center-Vector2(200, 0);
	position = target;
	body_entered.connect(func(other: Node2D):
		if other == player and state != State.INACTIVE:
			player.repulse(position, 1000);
			player.damage(50);
	);


func _process(delta):
	if target != null and target.distance_to(position) > 32:
		velocity += (target-position).normalized()*100;
	position += velocity*delta;
	velocity *= 0.9;
	$Sprite2D.flip_h = player.position.x > position.x;
	var dmg_amt = 1-$DamageTimer.time_left;
	$Sprite2D.modulate = Color(1, dmg_amt, dmg_amt, 1);
	if dmg_amt == 0:
		$Sprite2D.modulate = Color(1, 255, 255, 255);

var charge_pos;

func _on_timer_timeout():
	match state:
		State.GHOSTS:
			if int(times)%10 == 0:
				play_anim(0);
				var ghost = Ghost.instantiate();
				ghost.init(player, ghosts);
				const MAX_VEL = 1000;
				ghost.vel = Vector2((randi()%(MAX_VEL*2))-MAX_VEL, (randi()%(MAX_VEL*2))-MAX_VEL)
				ghost.position = position;
				ghosts.add_child(ghost);
				const MAX_DIST = 300;
				target = player.position+Vector2(randi()%(MAX_DIST*2)-MAX_DIST, (randi()%(MAX_DIST*2))-MAX_DIST);
			if times > 100:
				set_state(State.CHARGE);
		State.CHARGE:
			if int(times)%15 == 10:
				# telegraph
				play_anim(1);
				velocity -= (player.position-position).normalized()*200;
				charge_pos = player.position;
			if int(times)%15 == 14:
				velocity += (charge_pos-position).normalized()*4000;
				target = center;
			if times > 60:
				set_state(State.PASSIVE);
		State.PASSIVE:
			target = center;
			play_anim(2);
			if times > 80:
				set_state(State.GHOSTS);
	times += 1;
	
func set_state(s):
	state = s;
	times = 0;

func hit():
	hits += 1;
	set_state(State.GHOSTS);
	$DamageTimer.start();
	if hits >= 3:
		died.emit();
		queue_free();

func _on_anim_timer_timeout():
	if anim == -1:
		return;
	anim_frame += 1;
	if anim_frame >= anims[anim].size():
		anim = -1;
		$Sprite2D.frame = 0;
		return;
	$Sprite2D.frame = anims[anim][anim_frame];

func play_anim(a):
	if anim == a:
		return;
	anim = a;
	anim_frame = 0;
