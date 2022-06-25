-- Hey, you're awfully nosy aren't you?
-- Just so you know, a lot of what you see here is mixed between original code
-- and code that I've gotten permission to use.
--
-- A word of warning: YOU SHOULD ASSUME __NONE__ OF THE CODE HERE IS REUSABLE.
-- GET PERMISSION TO USE THIS STUFF BEFORE YOU USE IT YOURSELF
--
-- Flame

rawset(_G, "FLCRLib", {})
local Lib = FLCRLib

Lib.weaponFire = function(p, id)
	local w = FLCR.Weapons[id]

	if (w.func ~= nil) then
		w.func(p, w)
	else
		CONS_Printf(p, "NOT IMPLEMENTED YET!")
	end
end

-- Tatsuru
Lib.removePlayerFromSlot = function(slot)
	local CRPD = FLCR.PlayerData
	
	assert(slot >= 1 and slot <= 32, "Invalid slot "..slot.." provided.")
	
	local p = CRPD[slot].player
	
	if valid(p) then
		print("Player "..p.name.." has been removed from slot "..slot..".")
		p.crplayerdata = nil
	end
	
	CRPD[slot].player = nil
end

-- Tatsuru
Lib.assignPlayerToSlot = function(p, slot)
	local CRPD = FLCR.PlayerData
	
	--assert((p and p.valid), "Invalid player userdata provided.")
	assert(slot >= 1 and slot <= 32, "Invalid slot "..slot.." provided.")
	
	if CRPD[slot].player then
		Lib.removePlayerFromSlot(slot)
	end
	
	if valid(p) then
		CRPD[slot].player = p
		p.crplayerdata = CRPD[slot]
	end

	print("Player "..p.name.." has been assigned to slot "..slot..".")
end

Lib.look4ClosestMo = function(mo, dist, mtype)
	if not valid(mo) then return end
	
	local closestmo
	local closestdist = dist
	for m in mobjs.iterate() do
		if (m == mo) then continue end -- Skip us
		if mtype and (m.type ~= mtype) then continue end -- If we have an mtype, search for it!
		if (m.health <= 0) then continue end -- Dead
		if (m.flags & MF_NOBLOCKMAP) or (m.flags & MF_SCENERY) then continue end -- Not Part of the blockmap. Ignore
		if m.player and m.player.spectator then continue end
		
		local idist = FixedHypot(FixedHypot(m.x - mo.x, m.y - mo.y), 2*(m.z - mo.z))
		if (idist > dist) then continue end -- Ignore objects outside of 'dist' range.
		
		if (idist < closestdist) then -- There's a mobj that's closer?
			closestmo = m -- Then we're the real closest mobj!
			closestdist = idist -- And this is our distance!
		end
	end
	
	return closestmo
end
