extends Node

var item_type_defualt_data : Dictionary = {
	"Tool":{"upgrades":[]}
}

var armor_buffs : Dictionary = {
	"air_tight":{"requires":[46,47,48,49]},
	"cold_resistance":{"requires":[207,208,209,210]},
	"heat_resistance":{"requires":[211,212,213,214]}
}

var autoSaveTimes : Array = [0,300,900,2700,3600,7200]

var emptyItem : Dictionary = {"id":0,"amount":0,"data":{}}