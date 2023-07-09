extends Node2D

func _on_animation_timer_timeout():
	$Sprite2D.frame = ($Sprite2D.frame+1)%($Sprite2D.hframes)
