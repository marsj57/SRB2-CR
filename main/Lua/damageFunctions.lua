-- Hey, you're awfully nosy aren't you?
-- Just so you know, a lot of what you see here is mixed between original code
-- and code that I've gotten permission to use.
--
-- A word of warning: YOU SHOULD ASSUME __NONE__ OF THE CODE HERE IS REUSABLE.
-- GET PERMISSION TO USE THIS STUFF BEFORE YOU USE IT YOURSELF
--
-- Flame

addHook("ShouldDamage", function(target, inflictor, source, damagetype)
	if not valid(target) then return nil end
	local player = target.player
	if not valid(player) then return nil end
	if not player.crplayerdata then return nil end -- Check for Custom Robo Player data. Process normal behavior otherwise
	local CRPD = FLCR.PlayerData[player.crplayerdata.id]
	if not valid(CRPD.player) then return nil end
	local p = CRPD.player -- Simplify
	
	if CRPD.state 
	and (CRPD.state >= CRPS_NORMAL)
	and (CRPD.state <= CRPS_HIT) then
		return true -- Can be hit
	else
		return false -- Invulnerable
	end
end, MT_PLAYER)