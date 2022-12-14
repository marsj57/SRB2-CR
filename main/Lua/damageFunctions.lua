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
		-- Default damage if damage / knockback isn't specified
		damage = inflictor.damage or 5
		local knockdown = inflictor.knockdown or 10
		
		-- Do the damage, set the state
		Lib.doDamage(p, damage, knockdown, true)
		if (CRPD.state ~= CRPS_DOWN)
			CRPD.state = CRPS_HIT
			CRPD.statetics = 0
		end

		P_PlayerRingBurst(p, damage/10) -- Visual effect to shoy "You got hit!" (1/10th of damage received) 
		S_StartSound(target, sfx_s3kb9) -- [Ring Loss]
		
		-- Extra small visual effect to show "You got hit!"
		local fx = P_SpawnMobjFromMobj(target, 0, 0, 0, MT_DUMMYFX)
		fx.angle = inflictor.angle or R_PointToAngle2(inflictor.x, inflictor.y, target.x, target.y)
		--fx.angle = $ - ANGLE_90
		fx.state = S_FX_HIT1 + P_RandomRange(0,2)
		local xyangle, zangle = Lib.getXYZangle(inflictor, target)
		-- FX Rollangle stuff. This is purely visual
		local camangle = R_PointToAngle(inflictor.x, inflictor.y)
		if ((camangle - inflictor.angle) < 0) then 
			zangle = InvAngle($)
		end
		fx.rollangle = zangle

		-- Get thrust angle... and thrust!
		target.z = $ + 1
		target.state = S_PLAY_PAIN
		local xthrust, ythrust, zthrust = Lib.getThrust(target, inflictor)
		local factor = 10
		target.momx = $ - xthrust/factor
		target.momy = $ - ythrust/factor
		--zthrust = ($ > 0) and min($, 40*FRACUNIT) or max($, -40*FRACUNIT)
		zthrust = min(abs($), 20*FRACUNIT)
		P_SetObjectMomZ(target, zthrust, true)
		return true -- Override default behavior
	elseif not valid(inflictor)
	and ((damagetype == DMG_FIRE) or (damagetype == DMG_ELECTRIC)) then
		-- Default damage
		damage = 50
		local knockdown = 100 -- Immediately get knocked down
		-- Do the damage, set the state
		Lib.doDamage(p, damage, knockdown)
		CRPD.state = CRPS_DOWN
		CRPD.statetics = TICRATE
		
		-- Extra small visual effect to show "You got hit!"
		local fx = P_SpawnMobjFromMobj(target, 0, 0, 0, MT_DUMMYFX)
		if (damagetype == DMG_ELECTRIC) then
			fx.scale = 2*FRACUNIT
			fx.state = S_FX_ELECUP
		end
		
		-- Get thrust angle... and thrust!
		target.z = $ + 1
		target.state = S_PLAY_PAIN
		target.momx = $>>1
		target.momy = $>>1
		P_SetObjectMomZ(target, 40*FRACUNIT, false)
		return true -- Override default behavior
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