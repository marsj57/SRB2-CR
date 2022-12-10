-- Hey, you're awfully nosy aren't you?
-- Just so you know, a lot of what you see here is mixed between original code
-- and code that I've gotten permission to use.
--
-- A word of warning: YOU SHOULD ASSUME __NONE__ OF THE CODE HERE IS REUSABLE.
-- GET PERMISSION TO USE THIS STUFF BEFORE YOU USE IT YOURSELF
--
-- Flame

local Lib = FLCRLib

local IsInvulnerable = function(p)
	return p.powers[pw_flashing]
		or p.powers[pw_invulnerability]
		or p.powers[pw_super]
		or p.exiting
		or p.quittime
		--or P_PlayerInPain(p) -- Not checking for this because we can be 'combo'ed in the air
end

addHook("ShouldDamage", function(target, inflictor, source, damage, damagetype)
	if not valid(target) then return nil end
	local player = target.player
	if not valid(player) then return nil end

	-- Vanilla invulnerability check
	if IsInvulnerable(player) then return false end
	
	if not player.crplayerdata then return nil end -- Check for Custom Robo Player data. Process normal behavior otherwise
	local CRPD = FLCR.PlayerData[player.crplayerdata.id]
	if not valid(CRPD.player) then return nil end
	local p = CRPD.player -- Simplify
	
	if CRPD.state 
	and (CRPD.state ~= CRPD_REBIRTH) then
		return true -- Can be hit
	else
		return false -- Invulnerable
	end
end, MT_PLAYER)

addHook("MobjDamage", function(target, inflictor, source, damage, damagetype)
	if not valid(target) then return nil end
	local player = target.player
	if not valid(player) then return nil end
	if not player.crplayerdata then return nil end -- Check for Custom Robo Player data. Process normal behavior otherwise
	local CRPD = FLCR.PlayerData[player.crplayerdata.id]
	if not valid(CRPD.player) then return nil end
	local p = CRPD.player -- Simplify
	
	if valid(inflictor) then
		damage = inflictor.damage or 5
		local knockdown = inflictor.knockdown or 10
		
		Lib.doDamage(p, damage, knockdown, true)
		if (CRPD.state ~= CRPS_DOWN)
			CRPD.state = CRPS_HIT
			CRPD.statetics = 0
		end

		target.z = $ + 1
		target.state = S_PLAY_PAIN
		P_PlayerRingBurst(p, damage/8)
		S_StartSound(target, sfx_s3kb9) -- [Ring Loss]

		local xthrust, ythrust, zthrust = Lib.getThrust(target, inflictor)
		local factor = 9
		target.momx = $ - xthrust/factor
		target.momy = $ - ythrust/factor
		target.z = $ + 1
		--zthrust = ($ > 0) and min($, 40*FRACUNIT) or max($, -40*FRACUNIT)
		zthrust = min(abs($), 20*FRACUNIT)
		P_SetObjectMomZ(target, zthrust, true)
		return true
	elseif not valid(inflictor)
	and ((damagetype == DMG_FIRE) or (damagetype == DMG_ELECTRIC)) then
		damage = 50
		local knockdown = 100 -- Immediately get knocked down
		Lib.doDamage(p, damage, knockdown)
		CRPD.state = CRPS_DOWN
		CRPD.statetics = TICRATE
		
		target.z = $ + 1
		target.state = S_PLAY_PAIN
		target.momx = $>>1
		target.momy = $>>1
		P_SetObjectMomZ(target, 40*FRACUNIT, false)
		return true
	end
end, MT_PLAYER)

/*addHook("MobjMoveCollide", function(tmthing, thing)
	if not (valid(tmthing) and valid(thing)) then return nil end
	if (tmthing.z > (thing.z + thing.height)) -- No Z collision? Let's fix that!
	or ((tmthing.z + tmthing.height) < thing.z) then
		return -- Out of range
	end
	
	local xyangle, zangle = Lib.getXYZangle(tmthing, thing)
	print("poggers")
end, MT_PLAYER) -- Our tmthing*/