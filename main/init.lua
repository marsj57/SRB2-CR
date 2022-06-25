-- Flame
for _, filename in ipairs({
	"global.lua",
	"info.lua",
	"utilityFuncs.lua",
	"typeStruct.lua", -- Also calls "partsIndex.lua"
	--"partsIndex.lua",
	"gameplayFunctions.lua",
	"miscThinkers.lua",
	"cam.lua",
}) do
	dofile(filename)
end