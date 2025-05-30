extends Node

const CURRENTVER = "TU6 (v0.6.1)"
const VER_NUMS = [0,6,1,0]
const ALLOW_VERSIONS = [
	[0,4,1,0],
	[0,4,2,0],
	[0,5,0,1],
	[0,5,0,3],
	[0,5,0,4],
	[0,5,0,5],
	[0,5,0,6],
	[0,5,0,7],
	[0,5,0,0],
	[0,5,1,0],
	[0,5,2,0],
	[0,5,3,0],
	[0,6,0,1],
	[0,6,0,2],
	[0,6,0,3],
	[0,6,0,4],
	[0,6,0,5],
	[0,6,0,6],
	[0,6,0,0],
	[0,6,1,0],
]
#Incompatable versions:
#[0,4,0,8] and [0,4,0,0] (as of TU4.1). Reason: Updated to godot 4
const STABLE = true

var save_path = "user://" #place of the file
var currentSave : String
var newPlanet : bool = true
var gameStart : bool = true
var newSave : bool = true
var currentPlanet : int
var currentSystem : int
var currentSystemId : String
var playerData = {}
var playerName = ""
var blues = 0
var killCount = 0
var scenario : String = "sandbox"
var starterPlanetId : int
var godmode : bool = false
var showTutorials : bool = true
var enemySpawning : bool = true
var entitySpawning : bool = true
var globalGameTime : int = 0
var gameTimeTimer : Timer = Timer.new()
var default_bookmarks = [
	{"name":"Shop center","icon":"star","color":Color(0.39,0.58,0.92),"system_id":"08406415904037","planet_id":0},
	]
var default_settings = {
	"music":10,
	"sfx":10,
	"environment":10,
	"autosave_interval":2,
	"vsync_mode":1,
	"tutorial_autoset_to":true,
	"keybinds":{"build":{"event_type":"mouse","id":1},"build2":{"event_type":"mouse","id":2},"action1":{"event_type":"key","id":74},"action2":{"event_type":"key","id":75},"background_toggle":{"event_type":"key","id":66},"inventory":{"event_type":"key","id":69},"ach":{"event_type":"key","id":90},"fly":{"event_type":"key","id":70}}
}
var bookmarks : Array= []
var settings : Dictionary

var gamerulesBase = {
	"can_leave_planet":true,
	"can_leave_system":true,
	"max_hp":50,
	"starting_hp":50,
	"custom_world_file":"",
	"custom_generation":"",
	"can_respawn":true,
	"difficulty":"normal",
	"start_with_godmode":false,
	"tutorial":true
}
var gamerules = {}

var lightColor : Color = Color.WHITE
var lightIntensity : float = 12

var playerBase = {"skin":Color("F8DEC3"),"hair_style":"Short","hair_color":Color("debe99"),"sex":"male"}

signal loaded_data
signal screenshot
signal saved_settings
signal entered_save
signal left_save
signal audio_changed

func _ready():
	if FileAccess.file_exists(save_path + "settings.dat"):
		var file = FileAccess.open(save_path + "settings.dat",FileAccess.READ)
		settings = file.get_var()
		#Ensures settings are up to date with current version
		for default : String in default_settings:
			if !settings.has(default):
				settings[default] = default_settings[default]
	else:
		settings = default_settings.duplicate(true)
		save_settings()
	ProjectSettings.set_setting("display/window/vsync/vsync_mode",settings["vsync_mode"])
	gameTimeTimer.connect("timeout", Callable(self, "game_time_second"))
	gameTimeTimer.autostart = true
	add_child(gameTimeTimer)

func _process(delta):
	if blues >= 1000 and !GlobalGui.completedAchievements.has("Economist 1"):
		GlobalGui.complete_achievement("Economist 1")
	elif blues >= 5000 and !GlobalGui.completedAchievements.has("Economist 2"):
		GlobalGui.complete_achievement("Economist 2")
	elif blues >= 10000 and !GlobalGui.completedAchievements.has("Economist 3"):
		GlobalGui.complete_achievement("Economist 3")
	if killCount >= 1 and !GlobalGui.completedAchievements.has("Exterminator 1"):
		GlobalGui.complete_achievement("Exterminator 1")
	elif killCount >= 10 and !GlobalGui.completedAchievements.has("Exterminator 2"):
		GlobalGui.complete_achievement("Exterminator 2")
	elif killCount >= 50 and !GlobalGui.completedAchievements.has("Exterminator 3"):
		GlobalGui.complete_achievement("Exterminator 3")
	elif killCount >= 100 and !GlobalGui.completedAchievements.has("Destroyer of worlds"):
		GlobalGui.complete_achievement("Destroyer of worlds")

func save_exists(saveId : String) -> bool:
	if DirAccess.dir_exists_absolute(save_path + saveId) and FileAccess.file_exists(save_path + saveId + "/playerData.dat"):
		return true
	return false

func open_save(saveId : String) -> void:
	currentSave = saveId
	gameStart = true
	newSave = false
	if DirAccess.dir_exists_absolute(save_path + saveId):
		if FileAccess.file_exists(save_path + saveId + "/playerData.dat"):
			if !DirAccess.dir_exists_absolute(save_path + saveId + "/structures"): #For TU4.2 and before
				DirAccess.make_dir_absolute(save_path + saveId + "/structures")
				copy_directory_recursively("res://data/structures",save_path + saveId + "/structures",true)
			newPlanet = false
			var savegame = FileAccess.open(save_path + saveId + "/playerData.dat",FileAccess.READ)
			playerData = savegame.get_var()
			blues = playerData["blues"]
			killCount = 0 if !playerData.has("kill_count") else playerData["kill_count"]
			bookmarks = default_bookmarks.duplicate(true) if !playerData.has("bookmarks") else playerData["bookmarks"]
			currentPlanet = playerData["current_planet"]
			starterPlanetId = playerData["starter_planet"]
			gamerules = playerData["gamerules"]
			for rule in gamerulesBase: #Makes sure the gamerules are up to date
				if !gamerules.has(rule):
					gamerules[rule] = gamerulesBase[rule]
			godmode = playerData["godmode"]
			playerName = "Jerry" if !playerData.has("player_name") else playerData["player_name"]
			scenario = "sandbox" if !playerData.has("scenario") else  playerData["scenario"]
			globalGameTime = 0 if !playerData.has("game_time") else playerData["game_time"]
			StarSystem.landedPlanetTypes = [] if !playerData.has("landed_planet_types") else playerData["landed_planet_types"]
			GlobalGui.completedAchievements = [] if !playerData.has("achievements") else playerData["achievements"]
			GlobalGui.completedTutorials = [] if !playerData.has("tutorials") else playerData["tutorials"]
			StarSystem.systemDat = load_system(playerData["current_system"])
			entered_save.emit()
			StarSystem.load_system()
		else:
			newPlanet = true
			new_save(saveId)
	else:
		new_save(saveId)
	currentSave = saveId

func teleport_to_planet(systemId : String, planet : int) -> void:
	currentPlanet = planet
	playerData["save_type"] = "planet"
	StarSystem.systemDat = load_system(systemId)
	StarSystem.load_system(false,true)

func new_save(saveId : String):
	newSave = true
	playerData.clear()
	#Sets tutorial to the last choice
	if !gamerules.has("tutorial"):
		gamerules["tutorial"] = settings["tutorial_autoset_to"]
	gamerules.merge(gamerulesBase.duplicate(true))
	godmode = gamerules["start_with_godmode"]
	bookmarks = default_bookmarks.duplicate(true)
	match scenario:
		"temple":
			gamerules["can_leave_planet"] = false
			gamerules["custom_world_file"] = "temple"
		"meteor":
			gamerules["can_leave_planet"] = false
			gamerules["custom_generation"] = "meteor"
		"insane":
			gamerules["max_hp"] = 1
			gamerules["starting_hp"] = 1
			gamerules["can_respawn"] = false
	blues = 0
	killCount = 0
	StarSystem.landedPlanetTypes.clear()
	var dir = DirAccess.open(save_path)
	dir.make_dir(saveId)
	dir.open(save_path + saveId)
	dir.make_dir("systems")
	dir.make_dir("planets")
	dir.make_dir("structures")
	copy_directory_recursively("res://data/pre_made_planets",save_path + saveId + "/planets",true)
	copy_directory_recursively("res://data/pre_made_systems",save_path + saveId + "/systems",true)
	copy_directory_recursively("res://data/structures",save_path + saveId + "/structures",true)
	GlobalGui.completedAchievements.clear()
	GlobalGui.completedTutorials.clear()
	globalGameTime = 0
	entered_save.emit()
	var _er = get_tree().change_scene_to_file("res://scenes/Main.tscn")

func new_planet() -> void:
	var _er = get_tree().change_scene_to_file("res://scenes/Main.tscn")
	await get_tree().process_frame
	newPlanet = true
	if FileAccess.file_exists(save_path + currentSave + "/planets/" + str(currentSystemId) + "_" + str(currentPlanet) + ".dat"):
		newPlanet = false
	emit_signal("loaded_data")

func change_volume_settings(category,value) -> void:
	settings[category] = value
	save_settings()
	audio_changed.emit()

func save_settings():
	var file = FileAccess.open(save_path + "settings.dat",FileAccess.WRITE)
	file.store_var(settings)
	print("Saved settings")
	emit_signal("saved_settings")

func save_structure(data : Dictionary) -> void:
	var file = FileAccess.open(save_path + currentSave + "/structures/" + data["file_name"] + ".dat",FileAccess.WRITE)
	file.store_var(data)
	print("saved structure: " + data["file_name"])

func load_structures(group : String) -> Array:
	var data = []
	var dir = DirAccess.open(save_path + currentSave + "/structures")
	dir.list_dir_begin()
	var fileName : String = dir.get_next()
	while (fileName != "" and fileName != "." and fileName != ".."):
		if fileName.begins_with(group):
			var file = FileAccess.open(save_path + currentSave + "/structures/" + fileName,FileAccess.READ)
			data.append(file.get_var())
		fileName = dir.get_next()
	return data

func load_structure(structureName : String) -> Dictionary:
	if FileAccess.file_exists(save_path + currentSave + "/structures/" + structureName):
		var file = FileAccess.open(save_path + currentSave + "/structures/" + structureName,FileAccess.READ)
		return file.get_var()
	return {}

func save(saveType : String, saveData : Dictionary) -> void:
	playerData["save_type"] = saveType
	playerData["achievements"] = GlobalGui.completedAchievements
	playerData["tutorials"] = GlobalGui.completedTutorials
	playerData["kill_count"] = killCount
	playerData["landed_planet_types"] = StarSystem.landedPlanetTypes
	playerData["scenario"] = scenario
	playerData["player_name"] = playerName
	playerData["gamerules"] = gamerules
	playerData["game_time"] = globalGameTime
	playerData["version"] = VER_NUMS
	playerData["bookmarks"] = bookmarks
	match saveType:
		"planet":
			playerData.merge(saveData["player"],true)
			playerData["gamerules"] = gamerules
			playerData["scenario"] = scenario
			playerData["player_name"] = playerName
			print(playerBase)
			playerData.merge(playerBase)
			playerData["starter_planet"] = starterPlanetId
			playerData["godmode"] = godmode
			playerData["blues"] = blues
			playerData["kill_count"] = killCount
			playerData["landed_planet_types"] = StarSystem.landedPlanetTypes
			playerData["game_time"] = globalGameTime
			playerData["version"] = VER_NUMS
			playerData["bookmarks"] = bookmarks
			var savegame = FileAccess.open(save_path + currentSave + "/planets/" + str(currentSystemId) + "_" + str(currentPlanet) + ".dat",FileAccess.WRITE)
			savegame.store_var(saveData["planet"])
			print("saving system")
			var savegame2 = FileAccess.open(save_path + currentSave + "/systems/" + str(currentSystemId) + ".dat",FileAccess.WRITE)
			savegame2.store_var(saveData["system"])
		"system":
			playerData["pos"] = saveData["player"]["pos"]
			var savegame = FileAccess.open(save_path + currentSave + "/systems/" + str(currentSystemId) + ".dat",FileAccess.WRITE)
			savegame.store_var(saveData["system"])
	var savegame = FileAccess.open(save_path + currentSave + "/playerData.dat",FileAccess.WRITE)
	savegame.store_var(playerData)
	print("Saved game!")

func save_system() -> void:
	print("Saving system!")
	var savegame = FileAccess.open(save_path + currentSave + "/systems/" + str(currentSystemId) + ".dat",FileAccess.WRITE)
	savegame.store_var(StarSystem.get_system_data())
	print("Saved system!")

func load_player() -> Dictionary:
	var data : Dictionary
	data = load_data(save_path + currentSave + "/playerData.dat")
	return data

func load_system(systemId : String) -> Dictionary:
	var data : Dictionary
	data = load_data(save_path + currentSave + "/systems/" + systemId + ".dat")
	return data

func load_planet(systemId : String, planetId : int) -> Dictionary:
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

func load_json_data(path : String) -> Dictionary:
	var jData : Dictionary = {}
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path,FileAccess.READ)
		var parse = JSON.parse_string(file.get_as_text())
		if parse is Dictionary:
			jData = parse
	return jData

func delete(dir : String) -> void:
	if DirAccess.dir_exists_absolute(save_path + dir):
		#DirAccess.remove_absolute(save_path + dir)
		remove_recursive(save_path + dir)

func find_bookmark(systemId : String, planetId : int) -> int:
	for bookmark in bookmarks:
		if bookmark["system_id"] == systemId and bookmark["planet_id"] == planetId:
			return bookmarks.find(bookmark)
	return -1

func remove_recursive(path): #Credit to davidepesce.com for this function. It deletes all the files in the main file, which allows it to delete the main one safely
	if DirAccess.dir_exists_absolute(path):
		# List directory content
		var dir : DirAccess = DirAccess.open(path)
		dir.list_dir_begin() # TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				remove_recursive(path + "/" + file_name)
			else:
				DirAccess.remove_absolute(path + "/" + file_name)
			file_name = dir.get_next()
		# Remove current path
		DirAccess.remove_absolute(path)
	else:
		print("Error removing " + path)

func copy_directory_recursively(p_from : String, p_to : String, fromRes : bool) -> void:
	if not DirAccess.dir_exists_absolute(p_to):
		DirAccess.make_dir_absolute(p_to)
	var dir = DirAccess.open(p_from)
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while (file_name != "" and file_name != "." and file_name != ".."):
		if dir.current_is_dir():
			copy_directory_recursively(p_from + "/" + file_name, p_to + "/" + file_name,fromRes)
		else:
			if fromRes:
				print(p_from + "/" + file_name)
				var resDir = DirAccess.open("res://")
				resDir.copy(p_from + "/" + file_name, p_to + "/" + file_name)
			else:
				dir.copy_absolute(p_from + "/" + file_name, p_to + "/" + file_name)
		file_name = dir.get_next()

func game_time_second():
	globalGameTime += 1
