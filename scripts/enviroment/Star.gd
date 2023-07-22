extends AnimatedSprite2D

var blink = false

func _ready():
	var ani = ["white","blue","red"][randi()%3]
	frame = randi()%2
	if randi()%3==1:
		play(animation)
		blink = true
	else:
		blink = false

func _on_VisibilityNotifier2D_screen_entered():
	show()

func _on_VisibilityNotifier2D_screen_exited():
	hide()
