-- Flame

if not FLCR then
	for _, filename in ipairs({
		"global.lua",
		"info.lua",
		"utilityFuncs.lua",
		"gametype.lua",
		"typeStruct.lua", -- Also calls "partsIndex.lua"
		--"partsIndex.lua",
		"gameplayFunctions.lua",
		"damageFunctions.lua",
		"miscThinkers.lua",
		"cam.lua",
	}) do
		dofile(filename)
	end
else
	print("Another instance of Sonic Skirmish already loaded! Duplicate script loading aborted!")
end