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

-- weaponFire: Fires your CR weapon, calling the weapon's spawn function
-- Flame
Lib.weaponFire = function(p, id)
	local w = FLCR.Weapons[id]

	if (w.spawnfunc ~= nil) then
		w.spawnfunc(p, w)
	else
		CONS_Printf(p, "NOT IMPLEMENTED YET!")
	end
end

-- SetTarget: Sets a target and returns the mobj if valid.
-- Returns a nil value if no target. Can be used in if statements to check conditionals.
-- Flame
--
-- mo (mobj_t)		- source mobj
-- target (mobj_t)		- target mobj
Lib.SetTarget = function(mo, target)
	mo.target = target
	return target
end

-- SetTracer: Same as above, but sets a tracer instead
-- Flame
--
-- mo (mobj_t)		- source mobj
-- tracer (mobj_t)		- target mobj
Lib.SetTracer = function(mo, tracer)
	mo.tracer = tracer
	return tracer
end

Lib.FixedLerp = function(val1,val2,amt)
	local p = FixedMul(FRACUNIT-amt,val1) + FixedMul(amt,val2)
	return p
end

-- Tatsuru
-- Removes a player to a slot
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
-- Assigns a player to a slot
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
		return { stateText[CRPD.state], CRPD.state }
	else
		return { "INVALID", 0 }
	end
end

-- Clairebun
-- getXYZangle: Self explainitory
Lib.getXYZangle = function(mo1, mo2)
	local x1, x2 = mo1.x - mo1.momx, mo2.x - mo2.momx
	local y1, y2 = mo1.y - mo1.momy, mo2.y - mo2.momy
	local angle = R_PointToAngle2(x1, y1, x2, y2)
	local dist = R_PointToDist2(x1, y1, x2, y2)
	local z1, z2 = mo1.z + mo1.height/2, mo2.z + mo2.height/2
	local zdist = z2 - z1
	local zangle = R_PointToAngle2(0, 0, dist, zdist)
	return angle, zangle
end

-- Clairebun
Lib.getThrust = function(mo1, mo2, minimal)
	local xyangle, zangle = Lib.getXYZangle(mo1, mo2) -- Get thrust direction based on collision angle
	local speed
	if minimal
		speed = mo1.scale/2 -- "Shove" knockback
	else
		 -- Momentum-influenced knockback
		local momx = mo1.momx - mo2.momx
		local momy = mo1.momy - mo2.momy
		local momz = mo1.momz - mo2.momz
		speed = FixedHypot(FixedHypot(momx, momy), momz)
	end
	local thrust = P_ReturnThrustX(mo1, zangle, speed)
	local zthrust = P_ReturnThrustY(mo1, zangle, speed)
	local xthrust = P_ReturnThrustX(mo1, xyangle, thrust)
	local ythrust = P_ReturnThrustY(mo1, xyangle, thrust)
	return xthrust, ythrust, zthrust
end

-- doDamage: Deals damage do a player if CR data is present
-- Flame
--
-- plyr (player_t)		- player that gets damaged
-- atk (int)			- amount of damage to apply
-- dwn (int)			- amount of 'down' meter to apply
-- variance (boolean)	- does damage have variance or is it a static value?
Lib.doDamage = function(plyr, atk, dwn, variance)
	if not valid(plyr) then return end
	if not plyr.crplayerdata then return end
	local CRPD = FLCR.PlayerData[plyr.crplayerdata.id]
	if (CRPD.state == CRPS_REBIRTH) then return end -- Invulnerable
	if not variance then variance = false end -- Default value
	
	-- Just to spice things up, damage has variance!
	if (CRPD.state == CRPS_DOWN) then
		-- While downed, you only take 50% dmg. Also, knockdown does not apply.
		local v = variance and (atk*P_RandomRange(80,120))/200 or atk
		CRPD.health = $ - v
		if not dwn then return end
		CRPD.curknockdown = $ + dwn
		if (CRPD.curknockdown >= 200) then
			CRPD.curknockdown = 200
		end
	else
		-- Damage can have either a -20% or 20% multiplier
		local v = variance and (atk*P_RandomRange(80,120))/100 or atk
		CRPD.health = $ - v
		if not dwn then return end
		CRPD.curknockdown = $ + dwn
		if (CRPD.curknockdown >= 100) then
			CRPD.state = CRPS_DOWN
		end
	end
end


-- look4ClosestMo: Looks for the closest mobj around 'mo'
-- Flame
--
-- mo (mobj_t)			- source mobj
-- dist (fixed_t)		- distance to search (Defaults to 1024*FRACUNITS if not specified)
-- dist (MT_* type)		- Look for a specific MT_* object?
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
