extends CharacterBody2D

const MAX_HEALTH: int = 1000;
var health: int = MAX_HEALTH;

const speed: float = 12000;
const gravity: float = 20;
const jump_height: float = 600;

var can_shoot = true;

var jump_count = 0;

var sucked_ghosts: Array = []; # ghosts currently being sucked

var died: = false;

@onready var sprite = $CollisionShape2D/Sprite2D;
@onready var gun = $CollisionShape2D/Gun;

const anim_frames = [
	# idle
	[0, 1],
	# walking
	[3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
];
var anim_frame: = 0;
var anim_state: = 0;

signal shoot();
signal sucking(object: Node2D);
signal die();

func set_anim_state(state):
	if state != anim_state:
		anim_state = state;
		anim_frame = 0;

func _ready():
	$VortexParent.hide();

func _physics_process(delta):
	velocity.y += gravity;
	if not died:
		var walking = false;
		if is_on_floor():
			jump_count = 0;
		if Input.is_action_pressed("left"):
			velocity.x -= speed*delta;
			walking = true;
		elif Input.is_action_pressed("right"):
			velocity.x += speed*delta;
			walking = true;
		if Input.is_action_just_pressed("jump") and jump_count < 2:
			velocity.y = -jump_height;
			jump_count += 1;
		if Input.is_action_pressed("suck"):
			$VortexParent.show();
		else:
			$VortexParent.hide();
		if walking:
			set_anim_state(1);
		else:
			set_anim_state(0);
	move_and_slide();
	velocity.x *= 0.1;

func _process(delta):
	if Input.is_action_pressed("shoot") and can_shoot:
		shoot.emit();
		can_shoot = false;
		$BulletTimer.start();
	$VortexParent.rotation = Vector2(0, 1).angle_to(get_local_mouse_position());
	if $VortexParent.is_visible():
		for ghost in sucked_ghosts:
			sucking.emit(ghost);
	sprite.flip_h = get_local_mouse_position().x < 0
	sprite.frame = anim_frames[anim_state][anim_frame];
	gun.rotation = Vector2(1, 0).angle_to(get_local_mouse_position());
	if damage_anim:
		var amt = 1-$DamageAnimationTimer.time_left;
		modulate = Color(1, amt, amt, 1);
		if amt == 0:
			modulate = Color(1, 255, 255, 255);
			damage_anim = false;

func _on_bullet_timer_timeout():
	can_shoot = true;

func _on_vortex_area_entered(area):
	_on_vortex_body_entered(area);

func _on_vortex_body_entered(body):
	if sucked_ghosts.find(body) == -1:
		sucked_ghosts.push_back(body);

func _on_vortex_area_exited(area):
	_on_vortex_body_exited(area);

func _on_vortex_body_exited(body):
	var idx = sucked_ghosts.find(body);
	if idx != -1:
		sucked_ghosts.remove_at(idx);

var damage_anim = false;

func damage(amt: int):
	health -= amt;
	if amt > 0:
		$DamageAnimationTimer.start();
		damage_anim = true;
		if health < 0:
			died = true;
			die.emit();
	else:
		if health > MAX_HEALTH:
			health = MAX_HEALTH;

func _on_animation_timer_timeout():
	anim_frame += 1;
	anim_frame %= anim_frames[anim_state].size();

# repulses from the position by a given amount
func repulse(pos: Vector2, amt: float):
	velocity += (position-pos).normalized()*amt;
