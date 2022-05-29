-- Flame
for _, filename in ipairs({
	"global.lua",
	"info.lua",
	"typeStruct.lua",
	"partsIndex.lua",
	"thinker.lua",
	"cam.lua",
}) do
	dofile(filename)
end