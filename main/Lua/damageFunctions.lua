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
	
	if not Lib.validCRPlayerData(player) then return nil end
	local CRPD = FLCR.PlayerData[player.crplayerdata.id]

	if CRPD.state 
	and (CRPD.state == CRPS_REBIRTH) 
	or (CRPD.state == CRPS_ACTION) then
		return false -- Invulnerable
	else
		return true -- Can be hit
	end
end, MT_PLAYER)

addHook("MobjDamage", function(target, inflictor, source, damage, damagetype)
	if not valid(target) then return nil end
	local player = target.player
	if not Lib.validCRPlayerData(player) then return nil end
	local CRPD = FLCR.PlayerData[player.crplayerdata.id]
	local p = CRPD.player -- Simplify

	if valid(inflictor) then
		-- Let's get our most important values.
		local xyangle, zangle = Lib.getXYZangle(inflictor, target)
	
		-- Default damage if damage / knockback isn't specified
		damage = inflictor.damage or 5
		local knockdown = inflictor.knockdown or 10
		
		-- Do the damage, set the state
		Lib.doDamage(p, damage, knockdown, true)
		if (CRPD.health <= 0) then -- Health below 0? Process default behavior
			CRPD.alivetics = 0
			p.rings = 0
			p.powers[pw_shield] = 0
			return nil
		end

		Lib.doRingBurst(p, damage/10) -- Visual effect to shoy "You got hit!" (1/10th of damage received) 
		S_StartSound(target, sfx_s3kb9) -- [Ring Loss]
		
		-- Extra small visual effect to show "You got hit!"
		local fx = P_SpawnMobjFromMobj(target, 0, 0, 0, MT_DUMMYFX)
		fx.angle = R_PointToAngle2(inflictor.x, inflictor.y, target.x, target.y) or inflictor.angle
		fx.state = S_FX_HIT1 + P_RandomRange(0,2)
		fx.scale = 2*FRACUNIT
		-- FX Rollangle stuff. This is purely visual
		local camangle = R_PointToAngle(inflictor.x, inflictor.y)
		fx.rollangle = zangle

		-- Get thrust angle... and thrust!
		-- TODO: CUSTOMIZED KNOCKBACK OPTIONS
		-- Possibly needs a inflictor/source .knockfunc
		target.z = $ + 1
		target.state = S_PLAY_PAIN
		-- Partially from P_SuperDamage
		-- Static, non-variable Z knockback
		if (target.eflags & MFE_UNDERWATER)
			P_SetObjectMomZ(target, FixedDiv(10511*FRACUNIT,2600*FRACUNIT), false)
		else
			P_SetObjectMomZ(target, 5*FRACUNIT, false)
		end
		
		/*-- This may seem backwards, but it's not.
		local fallbackangle = R_PointToAngle2(inflictor.x, inflictor.y, target.x, target.y)
		local fallbackspeed = FixedMul(4*FRACUNIT, inflictor.scale)
		P_InstaThrust(target, fallbackangle, fallbackspeed)*/
		
		local xthrust, ythrust, zthrust = Lib.getThrust(target, inflictor)
		target.momx = $ - xthrust/3
		target.momy = $ - ythrust/3
		--zthrust = ($ > 0) and min($, 40*FRACUNIT) or max($, -40*FRACUNIT)
		--zthrust = min(abs($), factor*FRACUNIT)
		--P_SetObjectMomZ(target, zthrust, false)
		return true -- Override default behavior
	elseif not valid(inflictor) -- Floor damage
	and ((damagetype == DMG_FIRE)
	or (damagetype == DMG_ELECTRIC)) then
		-- Default damage
		damage = 50
		local knockdown = 100 -- Immediately get knocked down
		-- Do the damage, set the state
		Lib.doDamage(p, damage, knockdown, false)
		if (CRPD.health <= 0) then -- Health below 0? Process default behavior
			p.rings = 0
			p.powers[pw_shield] = 0
			return nil
		end
		CRPD.statetics = TICRATE
		CRPD.state = CRPS_DOWN
		p.powers[pw_nocontrol] = knockdown
		
		-- Extra small visual effect to show "You got hit!"
		local fx = P_SpawnMobjFromMobj(target, 0, 0, 1, MT_DUMMYFX)
		if (damagetype == DMG_ELECTRIC) then
			fx.scale = 2*FRACUNIT
			fx.state = S_FX_ELECUP1
		elseif (damagetype == DMG_FIRE) then
			fx.scale = 2*FRACUNIT
			fx.state = S_FX_FIREUP1
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