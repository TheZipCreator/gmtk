extends CharacterBody2D

const speed: float = 12000;
const gravity: float = 20;
const jump_height: float = 500;

var can_shoot = true;

var sucked_ghosts: Array = []; # ghosts currently being sucked

signal shoot();
signal sucking(object: Node2D);

func _ready():
	$VortexParent.hide();

func _physics_process(delta):
	velocity.y += gravity;
	if Input.is_action_pressed("left"):
		velocity.x -= speed*delta;
	elif Input.is_action_pressed("right"):
		velocity.x += speed*delta;
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y -= jump_height;
	if Input.is_action_pressed("suck"):
		$VortexParent.show();
	else:
		$VortexParent.hide();
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
