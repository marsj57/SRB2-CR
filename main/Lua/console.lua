-- Hey, you're awfully nosy aren't you?
-- Just so you know, a lot of what you see here is mixed between original code
-- and code that I've gotten permission to use.
--
-- A word of warning: YOU SHOULD ASSUME __NONE__ OF THE CODE HERE IS REUSABLE.
-- GET PERMISSION TO USE THIS STUFF BEFORE YOU USE IT YOURSELF
--
-- Flame

local Lib = FLCRLib

-- skirmish_equip: Equip a weapon!
--
-- Usage
-- skirmish_equip gun <WEAPON_NAME>
-- skirmish_equip bomb <WEAPON_NAME>
-- skirmish_equip pod <WEAPON_NAME>
COM_AddCommand("skirmish_equip", function(p, ...)
	assert((gamestate == GS_LEVEL) and G_IsFLCRGametype(), "Sorry. This command can only be used in Sonic Skirmish maps!")
	local args = { ... }
	if not #args then return end -- TODO: USAGE

	-- Custom robo playerdata check
	if not p.crplayerdata then return end
	local CRPD = FLCR.PlayerData[p.crplayerdata.id]
	if not valid(CRPD.player) then return end

	-- Get the string entered for usability
	-- Bonus, if the player actually input a 'number', let's look for that too!
	local pt = tonumber(args[1]) or string.lower(tostring(args[1])) -- Part type
	if not ((pt == "gun") or (pt == "bomb") or (pt == "pod")
			or (pt == CRPT_GUN) or (pt == CRPT_BOMB) or (pt == CRPT_POD)) then
		CONS_Printf(p, "Invalid part type! Please select from either gun, bomb, or pod types!")
		return
	end

	-- If a string, convert to rawset value
	if (type(pt) == "string") then
		pt = ((pt == "gun") and CRPT_GUN)
			or ((pt == "bomb") and CRPT_BOMB)
			or ((pt == "pod") and CRPT_POD)
	end

	-- Let's get the rawset name and get it in the Global namespace
	local rsn = "CRWEP_"
	local pname = string.lower(tostring(args[2])) -- weapon name
	if (pt == CRPT_GUN) then -- Gun
		rsn = $ + "GUN_" + string.upper(pname:gsub(" ", ""))
	elseif (pt == CRPT_BOMB) then -- Bomb
		rsn = $ + "BOMB_" + string.upper(pname:gsub(" ", ""))
	elseif (pt == CRPT_POD) then -- Pod
		rsn = $ + "POD_" + string.upper(pname:gsub(" ", ""))
	end

	assert(FLCR.Weapons[_G[rsn]], "Weapon " + rsn + " not a valid part!")
	assert(FLCR.Weapons[_G[rsn]].parttype == pt, "Weapon " + FLCR.Weapons[_G[rsn]].name + " (" + rsn + ") not a valid part type to equip!")

	CRPD.loadout[pt] = _G[rsn] -- Equip the weapon!

	local t = FLCR.Weapons[_G[rsn]] -- Display a handy message
	if (pt == CRPT_GUN) then -- Gun
		CONS_Printf(p, "Equipped GUN Weapon: " + t.name + " (" + rsn + ")")
	elseif (pt == CRPT_BOMB) then -- Bomb
		CONS_Printf(p, "Equipped BOMB Weapon:" + t.name + " (" + rsn + ")")
	elseif (pt == CRPT_POD) then -- Pod
		CONS_Printf(p, "Equipped POD Weapon: " + t.name + " (" + rsn + ")")
	--elseif (pt == CRPT_LEG) then -- Legs?
	--		print("Equipped LEG Part:  " + t.name + " (" + rsn + ")")
	end
end)

