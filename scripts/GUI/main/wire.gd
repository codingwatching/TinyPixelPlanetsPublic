extends Control

@onready var color_panel: NinePatchRect = $ColorPanel

var colors : Dictionary = {
	"red":Color("cd3434"),
	"orange":Color("ff8534"),
	"yellow":Color("ffd541"),
	"yellow_green":Color("a2b155"),
	"green":Color("14a02e"),
	"cyan":Color("14a02e"),
	"blue":Color("417ce6"),
	"pink":Color("cd71b2"),
	"purple":Color("793a80"),
	"white":Color.WHITE,
	"light_gray":Color("ccd3d6"),
	"gray":Color("9ca3a7"),
	"black":Color("272829"),
	"brown":Color("8e5252"),
	"tan":Color("fad6b8"),
	"maroon":Color("73172d")
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for color : String in colors:
		var colorBtn : TextureButton = TextureButton.new()
		colorBtn.texture_normal = load("res://textures/GUI/space/buttons/color_btn.png")
		colorBtn.size = Vector2(6,6)
		colorBtn.pressed.connect(color_btn_pressed.bind(color))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func 

func _on_color_btn_toggled(toggled_on: bool) -> void:
	color_panel.visible = toggled_on


func _on_pick_color_btn_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.
