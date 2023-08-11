--  Load configuration options up front
ScriptHost:LoadScript("scripts/items/class.lua")
ScriptHost:LoadScript("scripts/items/custom_item.lua")
ScriptHost:LoadScript("scripts/items/consumableitem.lua")
ScriptHost:LoadScript("scripts/items/twostageitem.lua")
ScriptHost:LoadScript("scripts/settings.lua")
ScriptHost:LoadScript("scripts/logic.lua")

Tracker:AddItems("items/items.json")
Tracker:AddItems("items/settings.json")
Tracker:AddItems("items/bosses.json")

Tracker:AddMaps("maps/maps.json")

Tracker:AddLocations("locations/brinstar.json")
Tracker:AddLocations("locations/chozodia.json")
Tracker:AddLocations("locations/crateria.json")
Tracker:AddLocations("locations/kraid.json")
Tracker:AddLocations("locations/norfair.json")
Tracker:AddLocations("locations/ridley.json")
Tracker:AddLocations("locations/tourian.json")

OBJ_MISSILE = ConsumableItem("Missile Capacity","missile,missiles",250,100,5,2,"images/items/missile.png")
OBJ_SUPER = ConsumableItem("Super Missile Capacity","supermissile,super,supers",30,15,2,1,"images/items/supermissile.png")
OBJ_POWER = ConsumableItem("Power Bomb Capacity","powerbomb,powerbombs,power,pb",18,9,2,1,"images/items/powerbomb.png")
OBJ_DIFFICULTY = TwoStageItem("Difficulty","DifficultyNormal,Normal","DifficultyHard,Hard","images/settings/DifficultyNormal.png","images/settings/DifficultyHard.png")

Tracker:AddLayouts("layouts/tracker.json")
Tracker:AddLayouts("layouts/broadcast.json")
Tracker:AddLayouts("layouts/capture.json")

if _VERSION == "Lua 5.3" then
    ScriptHost:LoadScript("scripts/autotracking.lua")
else
    print("Auto-tracker is unsupported by your tracker version")
end