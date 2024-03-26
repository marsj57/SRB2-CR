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
	if not G_IsFLCRGametype() then return nil end
	if not valid(p) then return nil end
	if fromspectators then
		Lib.assignPlayerToSlot(p, #p+1)
		if not p.crmenu then return true end
		if not p.crmenu.gunselect 
		or not p.crmenu.bombselect 
		or not p.crmenu.podselect then 
			return false -- Not initialized. Something has gone wrong
		end
		-- We do string.format because some weapons with spaces in them
		-- will pass as 2 args instead of one. And surround them in "quotes".
		COM_BufInsertText(p, string.format('skirmish_equip gun "%s"', p.crmenu.gunselect[1]))
		COM_BufInsertText(p, string.format('skirmish_equip bomb "%s"', p.crmenu.bombselect[1]))
		COM_BufInsertText(p, string.format('skirmish_equip pod "%s"', p.crmenu.podselect[1]))
		return true
	else
		Lib.removePlayerFromSlot(#p+1)
		return true
	end
end)

addHook("PlayerSpawn", function(p)
	if not G_IsFLCRGametype() then return false end
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
	p.normalspeed = 2*skins[mo.skin].normalspeed/3
	p.runspeed = 2*skins[mo.skin].runspeed/3
	p.maxdash = 2*skins[mo.skin].maxdash/3
	p.actionspd = 2*skins[mo.skin].actionspd/3
	p.powers[pw_shield] = 0

	-- Menu specific stuff
	p.powers[pw_nocontrol] = 1 -- Hack to prevent player from jumping on spawn (See Menu code)

	local fx = P_SpawnMobjFromMobj(mo, 0,0,mo.height/2, MT_DUMMY)
	fx.color = mo.color
	fx.colorized = true
	fx.state = S_FX_WIND
	fx.frame = $ & ~FF_PAPERSPRITE
end)

addHook("PreThinkFrame", do 
	for player in players.iterate
		if not valid(player) then continue end
		if not player.crplayerdata then continue end
		local CRPD = FLCR.PlayerData[player.crplayerdata.id]
		if not valid(CRPD.player) then continue end
		local p = CRPD.player

		p.weapondelay = 1 -- Do not fire weapon rings. EVER!
		
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
		
		-- Ability thinkers
		local ability = FLCR.PlayerAbilities[mo.skin]
		if ability
		and ability.func then
			ability.func(p)
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

-- Player Abilities
-- TODO: SEPARATE THIS INTO LEG PARTS EVENTUALLY
FLCR.PlayerAbilities = {}

Lib.doPlayerAbilities = function(player)
	if not valid(player) then return false end
	if not player.crplayerdata then return false end
	local CRPD = FLCR.PlayerData[player.crplayerdata.id]
	if not valid(CRPD.player) then return false end
	local p = CRPD.player -- Simplify player
	if not valid(p.mo) then return false end
	local mo = p.mo -- Simplify mobj
	local ability = FLCR.PlayerAbilities[mo.skin] -- Simplify
	
	if (p.pflags & PF_JUMPED)
	and not (p.pflags & PF_THOKKED)
	and ability
	and ability.jfunc then
		ability.jfunc(p)
		p.pflags = $ | PF_THOKKED
		return true -- Custom Behavior
	else
		return false -- Normal behavior
	end
end

FLCR.PlayerAbilities["sonic"] = {
	jfunc = function(p)
		local mo = p.mo

		local thokspeed = FixedHypot(mo.momx, mo.momy) > 20*mo.scale and FixedHypot(mo.momx, mo.momy) or 20*mo.scale
		P_InstaThrust(mo, p.mo.angle, thokspeed)
		P_SetObjectMomZ(mo, FRACUNIT*8)

		local t = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_DUMMY)
		t.color = mo.color
		t.colorized = true
		t.state = S_FX_WIND
		t.frame = $ & ~FF_PAPERSPRITE
		S_StartSound(mo, sfx_thok)
	end,
	func = function(p)
		local mo = p.mo

		if (p.pflags & PF_THOKKED) then
			if (P_MobjFlip(mo)*mo.momz > 0) then
				if (leveltime%2) then
					local g = P_SpawnGhostMobj(mo)
					g.tics = 6
					g.colorized = true
				end
			else
				mo.state = S_PLAY_FALL
				p.pflags = $ & ~(PF_JUMPED|PF_THOKKED|PF_SPINNING)
			end
		end
	end,
}

FLCR.PlayerAbilities["tails"] = {
	jfunc = function(p)
		local mo = p.mo

		p.fly1 = 15 -- this is used to speed up the tails
		p.powers[pw_tailsfly] = TICRATE -- Tails flying animation
		p.pflags = $ & ~PF_JUMPED
		mo.momx, mo.momy = $/2, $/2
		mo.state = S_PLAY_FLY
		P_SetObjectMomZ(mo, FRACUNIT*8)
		S_StartSound(mo, sfx_zoom)
	end,
	func = function(p)
		local mo = p.mo
		if (p.pflags & PF_THOKKED) then
			p.pflags = $|PF_CANCARRY

			-- the ability: going up
			if (P_MobjFlip(mo)*mo.momz > 0) then
				-- reduce speed to 95%
				mo.momx, mo.momy = $*95/100, $*95/100

				-- spawn based advanced ghosts
				if (leveltime%2)
				and (P_MobjFlip(mo)*mo.momz > 5*FRACUNIT) then
					local g = P_SpawnGhostMobj(mo)
					g.tics = 4
					g.colorized = true
				end
			else
				if (p.cmd.buttons & BT_JUMP) -- slowfall
					P_SetObjectMomZ(mo, gravity/8, true)
				else -- fall
					mo.state = S_PLAY_FALL
					p.pflags = $ & ~(PF_CANCARRY|PF_JUMPED|PF_THOKKED|PF_SPINNING)
				end
			end
		end
	end,
}

FLCR.PlayerAbilities["metalsonic"] = {
	func = function(p)
		if p.dashmode and (p.dashmode > TICRATE*3)
			p.normalspeed = min($, skins[p.skin].normalspeed)
		end
	end,
}

FLCR.PlayerAbilities["amy"] = {
	jfunc = function(p)
		local mo = p.mo
		
		mo.state = S_PLAY_ROLL
		for i = 1, 8 do
			local fa = i*ANGLE_45
			local h = P_SpawnMobjFromMobj(mo,0,0,0,MT_LHRT)
			h.state = S_LHRTC
			h.angle = fa
			h.target = mo
			h.flags = $ | MF_SCENERY|MF_NOCLIP|MF_NOCLIPTHING|MF_NOCLIPHEIGHT & ~MF_MISSILE
			h.fuse = TICRATE*2 -- Dissapate after 2 seconds
			P_Thrust(h, h.angle, 6*FRACUNIT)
			P_SetObjectMomZ(h, FRACUNIT*6)
		end
		mo.momx, mo.momy = $/2, $/2
		P_SetObjectMomZ(mo, FRACUNIT*12)
	end,
	func = function(p)
		local mo = p.mo
		if (p.pflags & PF_THOKKED) then
			if (P_MobjFlip(mo)*mo.momz > 0) then
				mo.momx, mo.momy = $*95/100, $*95/100
				-- Heart riser!
				-- Follow Advanced style spawning but spawn hearts instead
				if (leveltime%2)
				and (P_MobjFlip(mo)*mo.momz > 5*FRACUNIT) then
					local h = P_SpawnMobjFromMobj(mo,0,0,0,MT_LHRT)
					h.state = S_LHRTC
					h.scale = FRACUNIT
					h.destscale = 1
					h.scalespeed = FRACUNIT/TICRATE
					h.target = mo
					h.fuse = TICRATE*2 -- Dissapate after 2 seconds
					h.flags = $ | MF_SCENERY|MF_NOGRAVITY|MF_NOCLIP|MF_NOCLIPTHING|MF_NOCLIPHEIGHT & ~MF_MISSILE
				end
			else
				mo.state = S_PLAY_FALL
				p.pflags = $ & ~(PF_JUMPED|PF_THOKKED|PF_SPINNING)
			end
		end
	end,
}

SafeFreeslot("sfx_shadsr", "sfx_shadsl")
FLCR.PlayerAbilities["shadow"] = {
	jfunc = function(p)
		local mo = p.mo

		p.pflags = $ & ~PF_JUMPED
		mo.sh_snaptime = 6
		mo.momz, mo.state, mo.flags = 0, S_PLAY_FALL, $|MF_NOGRAVITY

		-- N, NE, E, SE, S, SW, W, NW
		local angles = {}
		for i = 1, 8
			angles[i] = FLCR.CameraBattleAngle-(ANGLE_45*(i-1))
		end

		local angle = 1 -- default to forward with no input
		if (p.cmd.sidemove)
			if (p.cmd.sidemove < 0) -- left
				if (p.cmd.forwardmove) -- diagonal
					angle = (p.cmd.forwardmove) > 0 and 8 or 6
				else
					angle = 7
				end
			else -- right
				if (p.cmd.forwardmove) -- diagonal
					angle = (p.cmd.forwardmove) > 0 and 2 or 4
				else
					angle = 3
				end
			end
		else -- forward/back
			if (p.cmd.forwardmove)
				angle = (p.cmd.forwardmove) > 0 and 1 or 5
			end
		end

		p.drawangle = angles[angle]
		P_InstaThrust(mo, angles[angle], 50*mo.scale)

		mo.state = S_PLAY_FALL

		local s = P_SpawnMobj(mo.x, mo.y, mo.z, MT_DUMMY)
		s.skin = mo.skin
		s.sprite = mo.sprite
		s.angle = p.drawangle
		s.frame = mo.frame & FF_FRAMEMASK | FF_TRANS60
		s.fuse = TICRATE/7
		s.scale = mo.scale
		s.destscale = mo.scale*6
		s.scalespeed = mo.scale/2
		s.sprite2 = mo.sprite2
		s.color = SKINCOLOR_CYAN
		s.colorized = true
		s.tics = -1

		S_StartSound(mo, sfx_csnap)

		mo.state = S_SHADOW_WARP1
	end,
	func = function(p)
		local mo = p.mo

		if (p.pflags & PF_THOKKED) then
			if (mo.sh_snaptime)
				mo.sh_snaptime = $-1
				mo.flags2 = $|MF2_DONTDRAW
				if P_IsObjectOnGround(mo)
					mo.flags, mo.flags2 = $ & ~MF_NOGRAVITY, $ & ~MF2_DONTDRAW
					p.pflags = $ & ~PF_THOKKED
				end
			else
				mo.momx, mo.momy = $/2, $/2
				mo.flags, mo.flags2 = $ & ~MF_NOGRAVITY, $ & ~MF2_DONTDRAW
				p.pflags = $ & ~PF_THOKKED

				/*local s = P_SpawnMobj(mo.x, mo.y, mo.z+FRACUNIT*24, MT_DUMMY)
				s.state = S_CHAOSCONTROL1
				s.destscale = 3*FRACUNIT*/
				mo.state = S_SHADOW_WARP2
			end
		end
	end,
}

addHook("AbilitySpecial", Lib.doPlayerAbilities)