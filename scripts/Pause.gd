extends Control

@export var type = "planet"

func _ready() -> void:
	GlobalGui.autosave.connect(_on_Save_pressed)
	if $"..".has_node("Settings"):
		$VBoxContainer/Settings.show()

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		match type:
			"planet":
				if !get_node("../Dead").visible and !get_node("../Inventory").visible:
					toggle_pause()
			_:
				toggle_pause()

func toggle_pause(toggle = true, setValue = false):
	GlobalGui.close_ach()
	if $"..".has_node("Settings"):
		$"../Settings".hide()
	if toggle:
		setValue = !visible
	visible = setValue
	get_tree().paused = setValue

func _on_Quit_pressed():
	get_tree().paused = false
	GlobalGui.close_ach()
	match type:
		"planet":
			Global.save(type,$"../../World".get_world_data())
		"system":
			Global.save(type,$"../..".get_save_data())
		"galaxy":
			Global.save(type,{})
	await get_tree().process_frame
	$Black/AnimationPlayer.play("fadeIn")
	await $Black/AnimationPlayer.animation_finished
	Global.left_save.emit()
	var _er = get_tree().change_scene_to_file("res://scenes/Menu.tscn")

func _on_Save_pressed():
	match type:
		"planet":
			Global.save(type,$"../../World".get_world_data())
		"system":
			Global.save(type,$"../..".get_save_data())
		"galaxy":
			Global.save(type,{})

func _on_Continue_pressed():
	toggle_pause(false)

func _on_Achievements_pressed():
	GlobalGui.pop_up_ach()

func _on_settings_pressed() -> void:
	$"../Settings".display_settings()
