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

	if (w.spawnfunc ~= nil) then
		w.spawnfunc(p, w)
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

-- Get the status of whatever state you're in.
Lib.getCRState = function(p)
	if not valid(p) then return false end
	if not p.crplayerdata then return false end
	local CRPD = FLCR.PlayerData[p.crplayerdata.id]
	
	-- Returns both text and correspnding number
	if CRPD.state
	and (CRPD.state >= CRPS_NORMAL)
	and (CRPD.state <= CRPS_REBIRTH)
		local stateText = { "NORMAL", "HIT", "DOWNED", "REBIRTH" }
		return stateText[CRPD.state], CRPD.state
	else
		return "INVALID", CRPD.state
	end
end

Lib.look4ClosestMo = function(mo, dist, mtype)
	if not valid(mo) then return end
	
	if not dist then dist = 1024*FRACUNIT end
	
	local closestmo
	local closestdist = dist
	searchBlockmap("objects", function(refmo, found)
		if (found == refmo) then return nil end
		if mtype and (found.type ~= mtype) then return nil end
		if (found.health <= 0) then return nil end
		--if found.player and found.player.spectator then return nil end
		
		local idist = FixedHypot(FixedHypot(found.x - refmo.x, found.y - refmo.y), 2*(found.z - refmo.z))
		if (idist > dist) then return nil end -- Ignore objects outside of 'dist' range.
		
		if (idist < closestdist) then
			closestmo = found
			closestdist = idist
		end
	end,
	mo,
	mo.x-dist,mo.x+dist,
	mo.y-dist,mo.y+dist)
	
	return closestmo
end
