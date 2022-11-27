-- Hey, you're awfully nosy aren't you?
-- Just so you know, a lot of what you see here is mixed between original code
-- and code that I've gotten permission to use.
--
-- A word of warning: YOU SHOULD ASSUME __NONE__ OF THE CODE HERE IS REUSABLE.
-- GET PERMISSION TO USE THIS STUFF BEFORE YOU USE IT YOURSELF
--
-- Flame

local Lib = FLCRLib

FLCR.gameplayStuff = function(player)
	if not valid(player) then return end
	if not player.crplayerdata then return end
	local CRPD = FLCR.PlayerData[player.crplayerdata.id]
	if not valid(CRPD.player) then return end
	local p = CRPD.player
	local loadout = CRPD.loadout

	local cmd = p.cmd
	p.weaponshuffleheld = $ or false

	if p.weaponshuffleheld
	and not ((cmd.buttons & BT_WEAPONNEXT) 
	or (cmd.buttons & BT_WEAPONPREV)) then 
		p.weaponshuffleheld = false 
	end

	if CRPD.firetype and (CRPD.firetics > 0) then
		Lib.weaponFire(p, loadout[CRPD.firetype])
	end

	-- Weapon shuffling
	if (cmd.buttons & BT_WEAPONNEXT) and not p.weaponshuffleheld then
		CRPD.loadoutsel = (CRPD.loadoutsel >= #loadout) and 1 or $ + 1
		p.weaponshuffleheld = true
	elseif (cmd.buttons & BT_WEAPONPREV) and not p.weaponshuffleheld then
		CRPD.loadoutsel = (CRPD.loadoutsel <= 1) and #loadout or $ - 1
		p.weaponshuffleheld = true
	end
end

addHook("TeamSwitch", function(p, _, fromspectators)
	if not valid(p) then return end
	--if true return end
	if fromspectators then
		Lib.assignPlayerToSlot(p, #p+1)
		return true
	else
		Lib.removePlayerFromSlot(#p+1)
		return true
	end
end)

addHook("PlayerSpawn", function(p)
	if not valid(p) then return false end
	if not valid(p.mo) then return false end
	local mo = p.mo
	
	-- Teamswitch called before PlayerSpawn, that's why we can do this!
	if not p.crplayerdata then return end
	local CRPD = FLCR.PlayerData[p.crplayerdata.id]
	CRPD.health = 1000
	CRPD.state = CRPS_NORMAL
end)

addHook("PreThinkFrame", do 
	for player in players.iterate
		if not valid(player) then return end
		if not player.crplayerdata then return end
		--if (leveltime%TICRATE == 0) then print(player.crplayerdata.id) end
		local CRPD = FLCR.PlayerData[player.crplayerdata.id]
		if not valid(CRPD.player) then return end
		local p = CRPD.player
		
		p.weapondelay = 1 -- Do not fire weapon rings ever
		p.crselection = 1
		
		-- Firing tics
		if (CRPD.firetics <= 0) then
			CRPD.firetype = CRPT_INVALID
			CRPD.firetics = 0
			CRPD.firemaxrounds = 0
		else
			CRPD.firetics = $ - 1
		end
		
		-- State Change
		if (CRPD.state > CRPS_NORMAL)
		and (CRPD.statetics > 0) then
			CRPD.statetics = $ - 1
		else -- Timer ran our or abruptly returned to CRPS_NORMAL state
			CRPD.state = CRPS_NORMAL -- Actually return to the normal state
			CRPD.statetics = 0 -- Reset the timer
		end
	end
end)

addHook("PlayerThink", function(player)
	if not valid(player) then return end
	if not player.crplayerdata then return end
	local CRPD = FLCR.PlayerData[player.crplayerdata.id]
	if not valid(CRPD.player) then return end
	local p = CRPD.player
	local loadout = CRPD.loadout
	local cmd = p.cmd
	local wmask = (cmd.buttons & BT_WEAPONMASK) % 4 -- 0 and 1-3
	p.wmaskheld = $ or {false, false, false} -- Use 3 weapon mask buttons

	for i = 1, #p.wmaskheld do -- Weapon Mask
		if (i == wmask) then continue end
		p.wmaskheld[i] = false
	end

	FLCR.gameplayStuff(p)

	-- Weapon firing
	-- Spectator is already checked earlier so check these!
	if (p.playerstate == PST_DEAD) 
	or P_PlayerInPain(p) 
	or CRPD.firetics then
		return
	end
	-- Checks passed, let's fire your weapon!
	if (cmd.buttons & BT_ATTACK) and not (p.pflags & PF_ATTACKDOWN) then
		Lib.weaponFire(p, loadout[CRPD.loadoutsel]) -- Use the current weapon you have selected
		p.pflags = $ | PF_ATTACKDOWN
	elseif wmask and (wmask >= 1)
	and not p.wmaskheld[wmask] then
		Lib.weaponFire(p, loadout[wmask]) -- Use a dedicated button input w/ BT_WEAPONMASK!
		p.wmaskheld[wmask] = true
	end
end)

addHook("NetVars", function(net)
	FLCR.PlayerData = net($)
end)

-- Debug stuff
/*hud.add(function(v,p,c)
	if p.spectator then return end
	for i = 1, #players
		local PD = FLCR.PlayerData[i]
		local name = PD.player and PD.player.name or "nil"
		local flags
		if (PD.player == p)
			flags = V_YELLOWMAP
		end
		v.drawString(0,(8*(i-1)),name, flags)
	end
end,"game")*/