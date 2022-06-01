-- Flame
for _, filename in ipairs({
	"global.lua",
	"info.lua",
	"typeStruct.lua",
	"partsIndex.lua",
	"miscThinkers.lua",
	"cam.lua",
}) do
	dofile(filename)
end