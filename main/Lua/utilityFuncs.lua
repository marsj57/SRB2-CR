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

Lib.skinEndurance = {
	["sonic"] = 100,
	["tails"] = 90,
	["knuckles"] = 110,
	["amy"] = 95,
	["fang"] = 100,
	["metalsonic"] = 120
}

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

-- spawnMissile: Spawns a missile. A Variation of P_SPMAngle
-- Flame
--
-- source (mobj_t)		- Source to spawn the object at
-- wep (table)			- Weapon table containing properties, etc
-- angle (angle)		- Angle to spawn the object at
-- zangle (angle)		- Vertical angle to spawn the object at
-- flags2				- Extra flags to add to the missile
Lib.spawnCRMissile = function(source, wep, angle, zangle, flags2)
	if not valid(source) and not valid(source.player) then return end
	assert(wep, "ERROR! No weapon provided in spawnCRMissile!")

	local x,y,z
	x = source.x
	y = source.y
	if (source.eflags & MFE_VERTICALFLIP) then
		z = source.z + 2*source.height/3 - FixedMul(mobjinfo[type].height, source.scale)
	else
		z = source.z + source.height/3
	end

	local th = P_SpawnMobj(x, y, z, wep.mt)
	
	if (source.eflags & MFE_VERTICALFLIP) then
		th.flags2 = $ | MF2_OBJECTFLIP
	end
	
	th.destscale = source.scale
	P_SetScale(th, source.scale)
	
	if flags2 then th.flags2 = $ | flags2 end
	if wep.spawnsound then S_StartSoundAtVolume(source, wep.spawnsound, 192) end
	
	th.target = source
	
	th.angle = angle
	th.momx = FixedMul(wep.speed*(10*FRACUNIT), cos(angle))
	th.momy = FixedMul(wep.speed*(10*FRACUNIT), sin(angle))
	
	if zangle then
		th.momx = FixedMul($, cos(zangle))
		th.momy = FixedMul($, cos(zangle))
	end

	th.momz = FixedMul(wep.speed*(10*FRACUNIT), sin(zangle))

	-- Scale stuff
	th.momx = FixedMul($, th.scale)
	th.momy = FixedMul($, th.scale)
	th.momz = FixedMul($, th.scale)
	
	-- P_CheckMissileSpawn
	-- Moves the missile forward a bit and possibly explodes it right there.
	local tx = (th.x + th.momx/2)
	local ty = (th.y + th.momy/2)
	if not P_TryMove(th, tx, ty, true) then
		P_ExplodeMissile(th)
		return false
	end
	
	return th
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

-- homingAttack: P_HomingAttack re-written in Lua with modifications
-- Flame
--
-- source (mobj_t)		- source mobj
-- enemy (mobj_t)		- target mobj
-- speed (fixed_t)		- Speed to travel at. If not provided, uses the source's mobjinfo speed.
Lib.homingAttack = function(source, enemy, speed)
	local zdist, dist
	local ns = 0
	
	if not enemy or not enemy.valid then return false end
	
	if (enemy.flags & MF_NOCLIPTHING)
	or (enemy.health <= 0)
	or (enemy.flags2 & MF2_FRET) then
		return false
	end
	
	-- Set Angle
	source.angle = R_PointToAngle2(source.x, source.y, enemy.x, enemy.y)
	-- Set Slope
	zdist = (P_MobjFlip(source) == -1) and ((enemy.z + enemy.height) - (source.z + source.height)) or (enemy.z - source.z)
	dist = FixedHypot(FixedHypot(enemy.x - source.x, enemy.y - source.y), zdist)
	dist = max($, 1) -- Prevent Div by Zero error
	
	if (speed == nil) then speed = source.info.speed end
	if (source.threshold == 32000) then
		ns = FixedMul(speed/2, source.scale)
	else
		ns = FixedMul(speed, source.scale)
	end
	
	source.momx = FixedMul(FixedDiv(enemy.x - source.x, dist), ns)
	source.momy = FixedMul(FixedDiv(enemy.y - source.y, dist), ns)
	source.momz = FixedMul(FixedDiv(zdist, dist), ns)
	return true
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

-- Flame
-- Get the status of whatever state you're in.
Lib.getCRState = function(p)
	if not valid(p) then return false end
	if not p.crplayerdata then return false end
	local CRPD = FLCR.PlayerData[p.crplayerdata.id]
	
	-- Returns both text and correspnding number
	if CRPD.state
	and (CRPD.state >= CRPS_ACTION)
	and (CRPD.state <= CRPS_LOSE)
		local stateText = { "ACTION", "NORMAL", "HIT", "DOWN", "REBIRTH", "LOSE" }
		return stateText[CRPD.state], CRPD.state
	else
		return "INVALID", 0
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
		speed = (mo1.scale/2) -- "Shove" knockback
	else
		 -- Momentum-influenced knockback
		local momx = mo1.momx - mo2.momx
		local momy = mo1.momy - mo2.momy
		local momz = mo1.momz - mo2.momz
		speed = R_PointToDist2(0, 0, R_PointToDist2(0, 0, momx, momy), momz)>>2
	end
	local thrust = FixedMul(cos(zangle), speed) --P_ReturnThrustX(mo1, zangle, speed)
	local zthrust = FixedMul(sin(zangle), speed) --P_ReturnThrustY(mo1, zangle, speed)
	local xthrust = FixedMul(cos(xyangle), thrust) --P_ReturnThrustX(mo1, xyangle, thrust)
	local ythrust = FixedMul(sin(xyangle), thrust) --P_ReturnThrustY(mo1, xyangle, thrust)
	return xthrust, ythrust, zthrust
end

-- addEndurance: Adds a skin string to the skinEndurance table.
-- Flame
--
Lib.addEndurance = function(skin, val)
	if not valid(skins[skin]) then return end
	local sn = skins[skin].name
	if Lib.skinEndurance[sn] ~= nil then
		print("\131NOTICE:\128 Skin " .. sn .. " was not allocated, as it already exists.")
		return
	end

	if val then
		val = min(max(1, $), 200) -- Min of 1, max of 200
	else
		val = 100 -- Default
	end
	table.insert(Lib.skinEndurance, sn, val)
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
	local endurance = Lib.skinEndurance[skins[plyr.skin].name] or 100
	if (CRPD.state == CRPS_DOWN) then
		-- While downed, you only take 50% dmg. Knockdown applies, but it speeds up recovery.
		local v = variance and (atk*P_RandomRange(80,120))/(2*endurance) or atk
		CRPD.health = $ - v
		if not dwn then return end
		CRPD.curknockdown = $ + dwn
		if (CRPD.curknockdown >= 200) then -- THAT'S ENOUGH DAMAGE
			CRPD.curknockdown = 200
			-- Special conditions for specific behavior below.
			-- Refer to the state thinker in gameplayFunctions.lua
			CRPD.statetics = TICRATE/2
			plyr.powers[pw_nocontrol] = TICRATE/2
		end
	else
		-- Damage can have either a -20% or 20% multiplier.
		local v = variance and (atk*P_RandomRange(80,120))/endurance or atk
		CRPD.health = $ - v
		CRPD.state = CRPS_HIT
		CRPD.statetics = 0
		if not dwn then
			plyr.powers[pw_nocontrol] = 10
			return 
		else
			plyr.powers[pw_nocontrol] = dwn
		end
		CRPD.curknockdown = $ + dwn
		if (CRPD.curknockdown >= 100) 
		and (CRPD.state ~= CRPS_DOWN) then 
			CRPD.state = CRPS_DOWN
		end
	end
end

-- Look4ClosestPlayer
-- Flame
--
-- mo (mobj_t)			- source mobj
-- dist (fixed_t)		- distance to search (Defaults to 1024*FRACUNITS if not specified)
Lib.Look4ClosestPlayer = function(mo, dist)
	if not valid(mo) then return end -- Sanity check
	if not dist then dist = 1024<<FRACBITS end -- Searching distance
	
	local lastmo, fdist
	local lastdist = 0
	searchBlockmap("objects", function(refmo, found)
		if (found == refmo) then return nil end
		if not (found.player) then return nil end
		if (found.health <= 0) then return nil end
		if not P_CheckSight(refmo, found) then return nil end
		local p = found.player
		if not valid(p) -- Not a valid player	
		or p.spectator then -- Player is a spectator?
			return nil
		end

		-- Team check
		if (gametype == GT_CTF) 
		and (not p.ctfteam
		or (p.ctfteam == refmo.player.ctfteam)) then
			return nil
		elseif (gametype == GT_TEAMMATCH) and (found.color == refmo.color) then
			return nil
		end

		fdist = FixedHypot(FixedHypot(found.x - refmo.x, found.y - refmo.y), (found.z - refmo.z))
		
		-- Last mobj is closer?
		if (lastmo and (fdist > lastdist)) then return nil end

		-- Found a target
		lastmo = found
		lastdist = fdist
	end,
	mo,
	mo.x-dist,mo.x+dist,
	mo.y-dist,mo.y+dist)
	
	return lastmo
end

-- setNextPlayerTarget
-- Flame
--
-- player (player_t)	- source player
Lib.setNextPlayerTarget = function(player)
	if not valid(player) then return false end
	if not valid(player.mo) then return false end
	local mo = player.mo
	local index = #player -- Player index. Will account for your player 'node'. 
	-- Eg. In a netgame, if you are player 1, your node will be 0. If you are player 2, your node will be 1, etc

	-- If no existing target, then we don't have anything to switch to!
	if not valid(mo.target) then return false end

	-- Start at your node and iterate through the maximum player count. Subtract by 1 because we are 0 indexed. 
	-- (Player nodes are from 0 - 31)
	local next
	for i = index, index + (#players-1) do
		local v = i%(#players)
		if FLCRDebug then print(v) end
		local p = players[v]
		if not valid(p) then continue end -- Not a valid player, continue to next.
		if p.spectator then continue end -- Don't bother with spectators.
		if not valid(p.mo) then continue end -- Not a valid player mobj.
		local imo = p.mo
		if (p == player) then continue end -- Skip us
		if (p.playerstate == PST_DEAD) then continue end

		-- Team check
		-- TODO: Team Skirmish?
		if (gametype == GT_CTF)
		and (not p.ctfteam
		or (p.ctfteam == player.ctfteam)) then
			return nil
		elseif (gametype == GT_TEAMMATCH) and (imo.color == mo.color) then
			return nil
		end

		if not P_CheckSight(mo, imo) then continue end

		next = imo
		break -- Break at first entry
	end
	
	mo.target = next
	return next
end

-- doRingBurst: Spills an injured player's rings - Copied from the source
-- 
-- player (player_t)		- player who is losing rings.
-- num_rings (int)			- Number of rings lost. A maximum of 32 rings will be spawned.
Lib.doRingBurst = function(player, num_rings)
	if not valid(player) then return end -- Better safe than sorry
	local p = player -- Simplify
	if not valid(p.mo) then return end
	local mo = p.mo
	
	if (num_rings > 32) then num_rings = 32 end -- Hard cap
	
	local va -- Variable angle
	if (abs(mo.momx) > mo.scale) or (abs(mo.momy) > mo.scale) then
		va = R_PointToAngle2(mo.momx, mo.momy, 0, 0)
	else
		va = mo.angle
	end
	
	local ns
	for i = 0, num_rings-1, 1 do
		local objType = mobjinfo[MT_RING].reactiontime
		local z = mo.z
		if (mo.eflags & MFE_VERTICALFLIP) then z = $ + mo.height - mobjinfo[objType].height end
		
		local ring = P_SpawnMobj(mo.x, mo.y, z, objType)
		
		ring.fuse = 8*TICRATE
		Lib.SetTarget(ring, mo)
		
		-- Funny math
		local fa = ((i*ANGLE_22h) + va - (num_rings-1)*ANGLE_11hh)
		local momxy, momz -- Base horizontal / vertical thrusts
		if (i > 15) then
			momxy = 3*FRACUNIT
			momz = 4*FRACUNIT
		else
			momxy = 2*FRACUNIT
			momz = 3*FRACUNIT
		end
		
		ns = FixedMul(FixedMul(momxy, FRACUNIT + FixedDiv(p.losstime<<FRACBITS, 10*TICRATE<<FRACBITS)), mo.scale)
		ring.momx = FixedMul(cos(fa),ns)
		
		if not (twodlevel or (mo.flags2 & MF2_TWOD)) then
			ring.momy = FixedMul(sin(fa),ns)
		end
		
		ns = FixedMul(momz, FRACUNIT + FixedDiv(p.losstime<<FRACBITS, 10*TICRATE<<FRACBITS))
		P_SetObjectMomZ(ring, ns, false)
		
		if (i&1) then P_SetObjectMomZ(ring, ns, true) end
		ring.momz = $ * P_MobjFlip(mo)
		-- CR Specific
		ring.flags = $ | MF_NOCLIPTHING
	end
	player.losstime = $ + 10*TICRATE
end