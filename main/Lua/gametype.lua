-- Hey, you're awfully nosy aren't you?
-- Just so you know, a lot of what you see here is mixed between original code,
-- and code that I've gotten permission to use.
--
-- You should assume that the code I borrowed is not reusable.
-- I've commented the names of individuals from whom,
-- I received permission to use their code.
-- GET PERMISSION TO USE THIS STUFF BEFORE YOU USE IT YOURSELF
-- 
-- Flame

local Lib = FLCRLib

freeslot("TOL_SKIRMISH")

-- To the user, this is a "Skirmish" gametype.
-- Internally, we are Custom Robo.
G_AddGametype({
	name = "Skirmish", -- Thank you Claire for the awesome name!
	identifier = "ROBO", -- GT_ROBO
	typeoflevel = TOL_SKIRMISH, -- For Mappers TOL is simply: SKIRMISH
	rules = GTR_SPECTATORS|GTR_HURTMESSAGES|GTR_DEATHMATCHSTARTS|GTR_TIMELIMIT,
	intermissiontype = int_match,
	rankingtype = GT_MATCH,
	defaulttimelimit = 0,
	headercolor = 148,
	description = "Use various weapon combinations at your disposal and come out on top in this mix-n-match frenzy!"
})

-- Check to see if we are in a Custom Robo Gametype
rawset(_G, "G_IsFLCRGametype", function()
	return (gametype == GT_ROBO)
end)

-- Check to see if we are in a Vanilla Gametype
rawset(_G, "G_IsVanillaGametype", function()
	return ((gametype >= GT_COOP) and (gametype <= GT_CTF))
end)

-- Check to see if the map is a Custom Robo Type of Level
rawset(_G, "G_IsFLCRTOL", function(mapnum)
	return (mapheaderinfo[mapmum].typeoflevel & TOL_SKIRMISH)
end)

addHook("MapChange", function(mapnum)
	if G_IsFLCRGametype() then return end -- Don't process anything if already Custom Robo map
	for p in players.iterate
		Lib.removePlayerFromSlot(#p+1)
	end
end)

-- Hey! Want to use these functions in your own scripts?
-- Here's an example of what you can do in your scripts
--
-- local s, v = pcall(G_IsFLCRGametype) -- Check to make sure function exists
-- if s then -- If pcall function status is a success... (Does this function exist?)
--  print(v) -- Print the result (value) of the function! (Our function returns true/false)
-- end
--
-- print function runs only ***if Sonic Skirmish function is present***
-- false if not a Sonic Skirmish gamemode
-- true if it is a Sonic Skirmish gamemode