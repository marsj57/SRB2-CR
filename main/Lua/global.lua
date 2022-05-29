-- Hey, you're awfully nosy aren't you?
-- Just so you know, a lot of what you see here is mixed between original code
-- and code that I've gotten permission to use.
--
-- A word of warning: YOU SHOULD ASSUME __NONE__ OF THE CODE HERE IS REUSABLE.
-- GET PERMISSION TO USE THIS STUFF BEFORE YOU USE IT YOURSELF
--
-- Flame

rawset(_G, "FLCR", {}) -- Flame's Custom Robo
FLCR.Weapons = {} -- Weapons table
FLCR.CameraBattleAngle = 0

rawset(_G, "valid", function(v)
	return v and v.valid
end)

rawset(_G, "createFlags", function(tname, t)
    for i = 1,#t do
		rawset(_G, t[i], 2^(i-1))
		table.insert(tname, {string = t[i], value = 2^(i-1)} )
    end
end)

rawset(_G, "createEnum", function(tname, t, from)
    if from == nil then from = 0 end
    for i = 1,#t do
		rawset(_G, t[i], from+(i-1))
		table.insert(tname, {string = t[i], value = from+(i-1)} )
    end
end)

-- Lach
-- Freeslots something without making duplicates
local function CheckSlot(item) -- this function deliberately errors when a freeslot does not exist
	if _G[item] == nil -- this will error by itself for states and objects
		error() -- this forces an error for sprites, which do actually return nil for some reason
	end
end

rawset(_G, "SafeFreeslot", function(...)
	for _, item in ipairs({...})
		if pcall(CheckSlot, item)
			print("\131NOTICE:\128 " .. item .. " was not allocated, as it already exists.")
		else
			freeslot(item)
		end
	end
end)
-- End Lach

-- Copied from source
rawset(_G, "drainAmmo", function(p, power)
	if not valid(p) then return end
	p.powers[power] = $ - 1

	if (p.rings < 1)
		p.ammoremovalweapon = p.currentweapon
		p.ammoremovaltimer = ammoremovaltics -- 2*TICRATE
		
		if (p.powers[power] > 0)
			p.powers[power] = $ - 1
			p.ammoremoval = 2
		else
			p.ammoremoval = 1
		end
	else
		p.rings = $ - 1
	end
end)

-- Copied from source
rawset(_G, "setWeaponDelay", function(p, delay)
	if not valid(p) then return end
	p.weapondelay = delay
	if p.skin == 2 then -- knuckles
		p.weapondelay = $ * 2
		p.weapondelay = $ / 3
	end
end)

-- Copied from source
rawset(_G, "doFireRing", function(p, cmd)
	local mo
	if not valid(p) then return end
	
	if not (cmd.buttons & (BT_ATTACK|BT_FIRENORMAL)) then
		p.pflags = $ & ~PF_ATTACKDOWN
		return
	end
	
	if (p.pflags & PF_ATTACKDOWN) or p.climbing or (G_TagGametype() and not (p.pflags & PF_TAGIT)) then return end
	if not G_RingSlingerGametype() or p.weapondelay > 1 then return end
	
	p.pflags = $ | PF_ATTACKDOWN
	
	-- Ring
	if (p.rings <= 0) then return end
	setWeaponDelay(p, TICRATE/4)
	mo = P_SpawnPlayerMissile(p.mo, MT_REDRING, 0)
	if valid (mo) then P_ColorTeamMissile(mo, p) end
	p.rings = $ - 1
end)

/*-- Tatsuru
local function FixedPow(a, b)
	local res = FRACUNIT

	for i = 1, b do
		res = FixedMul(res, a)
	end

	return res
end
-- End Tatsuru

rawset(_G, "atan", function(x)
	return asin(FixedDiv(x, FixedSqrt(FRACUNIT + FixedPow(x, 2))))
end*/