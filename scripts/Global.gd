extends Node

const CURRENTVER = "TU 2 Beta 2"
const STABLE = false

var save_path = "user://" #place of the file
var currentSave : String
var new = true
var gameStart = true
var currentPlanet : int
var playerData
var starterPlanetId : int

var playerBase = {"skin":Color("F8DEC3"),"hair_style":"Short","hair_color":Color("debe99"),"sex":"Guy"}

signal loaded_data

func save_exists(saveId : String) -> bool:
	var dir = DirAccess.open(save_path)
	if dir.dir_exists(save_path + saveId):
		return true
	return false

func open_save(saveId : String) -> void:
	currentSave = saveId
	gameStart = true
	new = true
	var dir = DirAccess.open(save_path)
	if dir.dir_exists(saveId):
		if FileAccess.file_exists(save_path + saveId + "/playerData.dat"):
			var savegame = FileAccess.open(save_path + saveId + "/playerData.dat",FileAccess.READ)
			playerData = savegame.get_var()
			currentPlanet = playerData["current_planet"]
			StarSystem.systemDat = load_system(playerData["current_system"])
			StarSystem.visitedPlanets = StarSystem.systemDat["visited"]
			StarSystem.new_system(playerData["current_system"],true)
			new = false
		else:
			remove_recursive(save_path + saveId)
			dir.make_dir(saveId)
			var save = DirAccess.open(save_path + saveId) #may need to be just saveId
			save.make_dir("systems")
			save.make_dir("planets")
	else:
		dir.make_dir(saveId)
		var save = DirAccess.open(save_path + saveId)
		save.make_dir("systems")
		save.make_dir("planets")
	currentSave = saveId

func new_planet() -> void:
	var _er = get_tree().change_scene_to_file("res://scenes/Main.tscn")
	await get_tree().process_frame
	new = true
	if FileAccess.file_exists(save_path + currentSave + "/planets/" + str(StarSystem.currentSeed) + "_" + str(currentPlanet) + ".dat"):
		new = false
		print("has file")
	emit_signal("loaded_data")

func save(saveData : Dictionary) -> void:
	playerData = saveData["player"]
	playerData["skin"] = playerBase["skin"];playerData["hair_color"] = playerBase["hair_color"];playerData["hair_style"] = playerBase["hair_style"]
	playerData["sex"] = playerBase["sex"]
	playerData["starter_planet"] = starterPlanetId
	var playerSave = FileAccess.open(save_path + currentSave + "/playerData.dat",FileAccess.WRITE)
	playerSave.store_var(saveData["player"])
	var planetsSave = FileAccess.open(save_path + currentSave + "/planets/" + str(StarSystem.currentSeed) + "_" + str(currentPlanet) + ".dat",FileAccess.WRITE)
	planetsSave.store_var(saveData["planet"])
	var systemSave = FileAccess.open(save_path + currentSave + "/systems/" + str(StarSystem.currentSeed) + ".dat",FileAccess.WRITE)
	systemSave.store_var(saveData["system"])
	print("Saved game!")

func load_player() -> Dictionary:
	var data : Dictionary
	data = load_data(save_path + currentSave + "/playerData.dat")
	return data

func load_system(systemId : int) -> Dictionary:
	var data : Dictionary
	data = load_data(save_path + currentSave + "/systems/" + str(systemId) + ".dat")
	return data

func load_planet(systemId : int, planetId : int) -> Dictionary:
	var data : Dictionary
	data = load_data(save_path + currentSave + "/planets/" + str(systemId) + "_" + str(planetId) + ".dat")
	return data

func load_data(path : String) -> Dictionary:
	var lData : Dictionary
	if FileAccess.file_exists(path):
		var savegame = FileAccess.open(path,FileAccess.READ)
		lData = savegame.get_var()
	else:
		lData = {}
	return lData

func delete(dir : String) -> void:
	var directory = DirAccess.open(save_path)
	if directory.dir_exists(dir):
		remove_recursive(save_path + dir)

func remove_recursive(path): #Credit to davidepesce.com for this function. It deletes all the files in the main file, which allows it to delete the main one safely
	var directory = DirAccess.open(path)
	# List directory content
	directory.list_dir_begin() # TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547
	var file_name = directory.get_next()
	while file_name != "":
		if directory.current_is_dir():
			remove_recursive(path + "/" + file_name)
		else:
			directory.remove(file_name)
		file_name = directory.get_next()
	
	# Remove current path
	directory.remove(path)
