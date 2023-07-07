extends CharacterBody2D

const speed: float = 200;
const gravity: float = 20;
const jump_height: float = 500;

func _physics_process(delta):
	velocity.y += gravity;
	if Input.is_action_pressed("left"):
		velocity.x -= speed;
	elif Input.is_action_pressed("right"):
		velocity.x += speed;
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y -= jump_height;
	move_and_slide();
	velocity.x *= 0.1;
