-- Flame
for _, filename in ipairs({
	"global.lua",
	"info.lua",
	"initialize.lua",
	"thinker.lua",
	"cam.lua",
}) do
	dofile(filename)
end