extends Sprite2D

var health: float = 0;

const AMT = 200;
var index = 0;

var f = 0;

func init(index):
	self.index = index;

func _process(delta):
	var h = 4-clamp(ceil((health-index*AMT)/50), 0, 4);
	frame = h*7+f;

func _on_animation_timer_timeout():
	f += 1;
	f %= 7;
