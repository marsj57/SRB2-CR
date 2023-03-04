-- Hey, you're awfully nosy aren't you?
-- Just so you know, a lot of what you see here is mixed between original code
-- and code that I've gotten permission to use.
--
-- A word of warning: YOU SHOULD ASSUME __NONE__ OF THE CODE HERE IS REUSABLE.
-- GET PERMISSION TO USE THIS STUFF BEFORE YOU USE IT YOURSELF
--
-- Flame

local Lib = FLCRLib

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

-- Bullet thinker code
addHook("MobjThinker", function(mo)
	if not valid(mo.target) then return false end
	if not mo.thinkfunc then return false end
	mo.thinkfunc(mo)
	return false
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
	CRPD.curknockdown = 0
	mo.scale = 4*FRACUNIT/3
	p.powers[pw_shield] = 0
end)

addHook("PreThinkFrame", do 
	for player in players.iterate
		if not valid(player) then continue end
		if not player.crplayerdata then continue end
		local CRPD = FLCR.PlayerData[player.crplayerdata.id]
		if not valid(CRPD.player) then continue end
		local p = CRPD.player

		p.weapondelay = 1 -- Do not fire weapon rings ever
		
		-- Firing tics
		if (CRPD.firetics > 0) then
			CRPD.firetics = $ - 1
		else
			CRPD.firetype = CRPT_INVALID
			CRPD.firetics = 0
			CRPD.firemaxrounds = 0
		end
		
		-- State Change
		CRPD.statetics = min(INT32_MAX, $ + 1) -- Counts up instead of down. Informs how long we've been in this state for
		if (CRPD.prevstate ~= CRPD.state) then
			CRPD.prevstate = CRPD.state
			CRPD.statetics = 0
		end
	end
end)

addHook("ThinkFrame", do
	for player in players.iterate
		if not valid(player) then continue end
		if not player.crplayerdata then continue end
		local CRPD = FLCR.PlayerData[player.crplayerdata.id]
		if not valid(CRPD.player) then continue end
		local p = CRPD.player
		local mo = p.mo 
		local loadout = CRPD.loadout
		local cmd = p.cmd
		local wmask = (cmd.buttons & BT_WEAPONMASK) % 4 -- 0 and 1-3
		p.wmaskheld = $ or {false, false, false} -- Use 3 weapon mask buttons

		p.losstime = 40*TICRATE -- Special Ring Loss

		-- Button holding
		for i = 1, #p.wmaskheld do -- Weapon Mask
			if (i == wmask) then continue end
			p.wmaskheld[i] = false
		end

		-- Weapon shuffling
		p.weaponshuffleheld = $ or false
		if p.weaponshuffleheld
		and not ((cmd.buttons & BT_WEAPONNEXT) 
		or (cmd.buttons & BT_WEAPONPREV)) then 
			p.weaponshuffleheld = false 
		end

		if (cmd.buttons & BT_WEAPONNEXT) and not p.weaponshuffleheld then
			CRPD.loadoutsel = (CRPD.loadoutsel >= #loadout) and 1 or $ + 1
			p.weaponshuffleheld = true
		elseif (cmd.buttons & BT_WEAPONPREV) and not p.weaponshuffleheld then
			CRPD.loadoutsel = (CRPD.loadoutsel <= 1) and #loadout or $ - 1
			p.weaponshuffleheld = true
		end

		-- State thinker
		if (p.playerstate == PST_DEAD) then
			continue
		elseif (CRPD.state ~= CRPS_NORMAL) then
			if (CRPD.state == CRPS_HIT)
			and ((mo.eflags & MFE_JUSTHITFLOOR)
			or (CRPD.statetics > TICRATE)) then
				CRPD.state = CRPS_NORMAL
			elseif (CRPD.state == CRPS_DOWN) then
				mo.state = S_PLAY_PAIN
				p.powers[pw_nocontrol] = TICRATE -- No movement, short time
				-- TODO: Keep an eye on this code in particular.
				-- Supposedly a reason for players able to "instantly" recover out of a downed state.
				if (CRPD.statetics > TICRATE)
				and (CRPD.curknockdown >= 200) then
					CRPD.curknockdown = 0
					p.powers[pw_flashing] = 2*TICRATE
					local fx = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_DUMMY)
					fx.state = S_FX_LINEUP
					fx.fuse = TICRATE
					CRPD.state = CRPS_REBIRTH -- Force rebirth state
				elseif (((mo.eflags & MFE_JUSTHITFLOOR)
				or P_IsObjectOnGround(mo))
				and (CRPD.statetics > 3*TICRATE)) then
					CRPD.curknockdown = 0
					p.powers[pw_flashing] = 2*TICRATE
					local fx = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_DUMMY)
					fx.state = S_FX_LINEUP
					fx.fuse = TICRATE
					CRPD.state = CRPS_REBIRTH -- Force rebirth state
				end
			elseif (CRPD.state == CRPS_REBIRTH) then
				mo.state = S_PLAY_STND
				mo.momx = 0
				mo.momy = 0
				mo.momz = 0
				p.drawangle = $ + ANGLE_45*CRPD.statetics -- Fancy little animation
				if (CRPD.statetics > (2*TICRATE/3)) then
					CRPD.state = CRPS_NORMAL
				end
			end
			continue -- Don't process aything else for this player, move to the next player.
		end

		-- Knockdown timer
		if not (CRPD.statetics%TICRATE) 
		and (CRPD.curknockdown > 0) then 
			CRPD.curknockdown = max(0, $ - 10)
		end

		-- Weapon firing.
		-- Continued weapon fire
		if CRPD.firetype and (CRPD.firetics > 0) then
			Lib.weaponFire(p, loadout[CRPD.firetype])
		else
			-- Initial weapon firing
			if (cmd.buttons & BT_ATTACK) and not (p.pflags & PF_ATTACKDOWN) then
				Lib.weaponFire(p, loadout[CRPD.loadoutsel]) -- Use the current weapon you have selected
				p.pflags = $ | PF_ATTACKDOWN
			elseif wmask and (wmask >= 1)
			and not p.wmaskheld[wmask] then
				Lib.weaponFire(p, loadout[wmask]) -- Use a dedicated button input w/ BT_WEAPONMASK!
				p.wmaskheld[wmask] = true
			end
		end
	end
end)

addHook("NetVars", function(net)
	FLCR.PlayerData = net($)
end)