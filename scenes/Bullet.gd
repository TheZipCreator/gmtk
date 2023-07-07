extends Area2D

signal hit(bullet, pos: Vector2, obj: Node2D);

var velocity: Vector2 = Vector2(0, 0);

func collided(body):
	hit.emit(self, position, body);

func _process(delta):
	position += velocity*delta;
