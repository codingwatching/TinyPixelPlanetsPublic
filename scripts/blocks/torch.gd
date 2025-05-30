extends BaseBlock

const SHADE_TEX = preload("res://textures/blocks/shade.png")
const FALL_BLOCKS : Array = [0,117]

var intensity : int = 10
var change : int = -1

@onready var visible_on_screen_notifier_2d: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var mainCol: CollisionShape2D = $CollisionShape2D
@onready var texture: AnimatedSprite2D = $Texture

func _ready():
	z_index = layer
	if layer < 1:
		modulate = Color(0.68,0.68,0.68)
		mainCol.disabled = true
		z_index -= 1
	
	pos = position / world.BLOCK_SIZE
	world.connect("update_blocks", Callable(self, "on_update"))
	world.connect("world_loaded", Callable(self, "world_loaded"))
	match id:
		321:
			texture.play("torch")
		325:
			texture.play("lantern")
		326:
			texture.play("ice_lantern")

func world_loaded():
	on_update()

func on_update():
	if layer < 1:
		if GlobalData.blockData[world.get_block_id(pos,1)]["transparent"] and ([0,10,77].has(world.get_block_id(pos,1)) or id != world.get_block_id(pos,1)):
			show()
		else:
			hide()
		if world.worldLoaded and visible_on_screen_notifier_2d.is_on_screen():
			for x in range(-1,2):
				for y in range(-1,2):
					if abs(x) != abs(y):
						if ![0,6,7,9,30].has(world.get_block_id(pos + Vector2(x,y),1)) and !$shade.has_node(str(x) + str(y)):
							var shade = Sprite2D.new()
							shade.texture = SHADE_TEX
							shade.name = str(x) + str(y)
							shade.rotation = deg_to_rad({Vector2(0,1):0,Vector2(-1,0):90,Vector2(0,-1):180,Vector2(1,0):270}[Vector2(x,y)])
							$shade.add_child(shade)
						elif world.get_block_id(pos + Vector2(x,y),1) == 0 and $shade.has_node(str(x) + str(y)):
							$shade.get_node(str(x) + str(y)).queue_free()
	if world.worldLoaded and visible_on_screen_notifier_2d.is_on_screen():
		match id:
			321:
				var supports : Array = []
				for checkPos : Vector2 in [Vector2(-1,0),Vector2(1,0),Vector2(0,1),Vector2(0,0)]:
					if (checkPos == Vector2(0,0) and layer == 1 and GlobalData.get_item_data(world.get_block_id(pos,0))["can_collide"]) or GlobalData.get_item_data(world.get_block_id(pos + checkPos,layer))["can_collide"]:
						supports.append(checkPos)
				if supports.is_empty():
					world.build_event("Break", pos, layer)
				elif supports.has(Vector2(0,0)) or supports.has(Vector2(0,1)):
					$Texture.play("torch")
					$Texture.flip_h = false
				else:
					$Texture.play("torch_side")
					$Texture.flip_h = !supports.has(Vector2(-1,0))

func get_sides(blockId : int) -> Dictionary:
	return {"left":world.get_block_id(pos - Vector2(1,0),layer) == blockId,"right":world.get_block_id(pos + Vector2(1,0),layer) == blockId,"top":world.get_block_id(pos - Vector2(0,1),layer) == blockId,"bottom":world.get_block_id(pos + Vector2(0,1),layer) == blockId,"rightTop":world.get_block_id(pos + Vector2(1,-1),layer) == blockId,"leftTop":world.get_block_id(pos - Vector2(1,1),layer) == blockId,"bottomRight":world.get_block_id(pos + Vector2(1,1),layer) == blockId,"bottomLeft":world.get_block_id(pos + Vector2(-1,1),layer) == blockId}

func get_sides_vector2(blockIds : Array,whiteListMode : bool = false) -> Dictionary:
	var sides = {}
	for x in range(-1,2):
		for y in range(-1,2):
			if !(x==0 and y==0):
				if whiteListMode:
					sides[Vector2(x,y)] = !GlobalData.blockData[world.get_block_id(pos + Vector2(x,y),layer)]["transparent"] or blockIds.has(world.get_block_id(pos + Vector2(x,y),layer))
				else:
					sides[Vector2(x,y)] = blockIds.has(world.get_block_id(pos + Vector2(x,y),layer))
	return sides

func _on_VisibilityNotifier2D_screen_entered():
	on_update()

func _on_VisibilityNotifier2D_screen_exited():
	pass

func _on_tick_timeout() -> void:
	intensity = randi_range(6,8)
	world.set_block_light(pos,layer,id,GlobalData.get_item_data(id)["light_color"],intensity)
	$Tick.start(randf_range(0.5,2.0))
