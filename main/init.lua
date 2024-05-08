-- Flame

if not FLCR then
	for _, filename in ipairs({
		--"Library/vec3.lua",
		--"Library/encap.lua",
		"global.lua",
		"info.lua",
		"utilityFuncs.lua",
		"gametype.lua",
		"typeStruct.lua", -- Also calls "partsIndex.lua"
		--"partsIndex.lua",
		"console.lua",
		"gameplayFunctions.lua",
		"damageFunctions.lua",
		"miscThinkers.lua",
		"cam.lua",
		"menu.lua",
	}) do
		dofile(filename)
	end
else
	print("Another instance of Sonic Skirmish already loaded! Duplicate script loading aborted!")
end