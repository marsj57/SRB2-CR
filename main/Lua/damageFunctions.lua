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
		or P_PlayerInPain(p)
end

addHook("ShouldDamage", function(target, inflictor, source, damage, damagetype)
	if not valid(target) then return nil end
	local player = target.player
	if not valid(player) then return nil end
	if not player.crplayerdata then return nil end -- Check for Custom Robo Player data. Process normal behavior otherwise
	local CRPD = FLCR.PlayerData[player.crplayerdata.id]
	if not valid(CRPD.player) then return nil end
	local p = CRPD.player -- Simplify
	
	-- Vanilla invulnerability check
	if IsInvulnerable(p) return false end
	
	if CRPD.state 
	and (CRPD.state ~= CRPD_REBIRTH) then
		return true -- Can be hit
	else
		return false -- Invulnerable
	end
end, MT_PLAYER)

/*addHook("MobjDamage", function(target, inflictor, source, damage, damagetype)
	if not valid(target) then return nil end
	local player = target.player
	if not valid(player) then return nil end
	if not player.crplayerdata then return nil end -- Check for Custom Robo Player data. Process normal behavior otherwise
	local CRPD = FLCR.PlayerData[player.crplayerdata.id]
	if not valid(CRPD.player) then return nil end
	local p = CRPD.player -- Simplify
	-- Code
end, MT_PLAYER)*/

addHook("MobjMoveCollide", function(tmthing, thing)
	if not (valid(tmthing) and valid(thing)) then return end
	
	if (tmthing.z > (thing.z + thing.height)) -- No Z collision? Let's fix that!
	or ((tmthing.z + tmthing.height) < thing.z) then
		return -- Out of range
	end
	
	local hangle, zangle = Lib.get3Dangle(tmthing, thing)
end, MT_PLAYER) -- Our tmthing