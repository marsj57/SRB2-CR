-- Hey, you're awfully nosy aren't you?
-- Just so you know, a lot of what you see here is mixed between original code
-- and code that I've gotten permission to use.
--
-- A word of warning: YOU SHOULD ASSUME __NONE__ OF THE CODE HERE IS REUSABLE.
-- GET PERMISSION TO USE THIS STUFF BEFORE YOU USE IT YOURSELF
--
-- Flame

-- From Rollout Knockout
rawset(_G, "spawnArrow", function(mo, target)
	-- Need both a source 'mo' and a target 'mo'
	if not valid(mo) then return end
	if not valid(target) then return end
	/*if (type(dist) ~= "number") then
		error("Error: spawnArrow expects a number")
		return
	end*/
	
	local arw = P_SpawnMobj(mo.x, mo.y, mo.z + 3*mobjinfo[mo.type].height, MT_DUMMY)
	arw.state = S_RKAW1
	arw.angle = R_PointToAngle2(mo.x, mo.y, target.x, target.y)
	arw.target = mo
	arw.color = target.color or SKINCOLOR_GREEN -- Opponent's color
	-- Fancy maths. Ensure your papersprite angle points towards your opponent.
	--local ft = FixedAngle((leveltime%45)*(8*FRACUNIT))
	P_TeleportMove(arw, mo.x,-- + FixedMul(cos(arw.angle), 3*mo.radius + FixedMul(sin(ft), 4*FRACUNIT)),
						mo.y,-- + FixedMul(sin(arw.angle), 3*mo.radius + FixedMul(sin(ft), 4*FRACUNIT)),
						mo.z + 3*mobjinfo[mo.type].height)

	-- Some more fancy maths. Grow/shrink according to your target's distance
	local tdist, zdiff = R_PointToDist2(mo.x, mo.y, target.x, target.y), (target.z - mo.z)
	local zaim = R_PointToAngle2(0, 0, tdist, zdiff) -- Use that distance to 'aim' towards your target
	local camangle = R_PointToAngle(mo.x, mo.y)
	
	---- Grow/shrink
	--arw.scale = FixedDiv(FixedMul(FRACUNIT, dist), tdist)/2
	
	-- Rollangle
	if ((camangle - arw.angle) < 0) then zaim = InvAngle($) end
	arw.rollangle = zaim
	return arw
end)

rawset(_G, "look4ClosestMo", function(mo, dist, mtype)
	if not valid(mo) then return end
	
	local closestmo
	local closestdist = dist
	for m in mobjs.iterate() do
		if (m == mo) then continue end -- Skip us
		if mtype and (m.type ~= mtype) then continue end -- If we have an mtype, search for it!
		if (m.health <= 0) then continue end -- Dead
		if (m.flags & MF_NOBLOCKMAP) or (m.flags & MF_SCENERY) then continue end -- Not Part of the blockmap. Ignore
		if m.player and m.player.spectator then continue end
		
		local idist = FixedHypot(FixedHypot(m.x - mo.x, m.y - mo.y), 2*(m.z - mo.z))
		if (idist > dist) then continue end -- Ignore objects outside of 'dist' range.
		
		if (idist < closestdist) then -- There's a mobj that's closer?
			closestmo = m -- Then we're the real closest mobj!
			closestdist = idist -- And this is our distance!
		end
	end
	
	return closestmo
end)

addHook("PreThinkFrame", do
	for p in players.iterate
		if not valid(p.mo) or p.spectator then continue end
		local mo = p.mo
		local cmd = p.cmd
		if not valid(p.awayviewmobj) then continue end
		if not (p.pflags & PF_ANALOGMODE) then p.pflags = $ | PF_ANALOGMODE end
		cmd.angleturn = ABSOLUTE_ANGLE>>16
		--if (p.weapondelay <= 1) then p.weapondelay = 1 end
	end
end)

addHook("ThinkFrame", do
	-- Camera mobj thinker. Referenced by p.awayviewmobj
	for p in players.iterate
		if not valid(p.mo) or p.spectator then continue end
		local mo = p.mo
		if not valid(p.awayviewmobj) then continue end
		p.awayviewtics = 2
	end
	
	-- Target finder, and thinker.
	for p in players.iterate
		if not valid(p.mo) or p.spectator 
		or (p.playerstate == PST_DEAD) then continue end
		local mo = p.mo
		if not mo.target then
			mo.target = look4ClosestMo(mo, 1024*FRACUNIT, MT_PLAYER)
		else
			local target = mo.target
			local sight = P_CheckSight(mo, target)
			local dist = FixedHypot(mo.x - target.x, mo.y - target.y)
			local zdiff = (target.z - mo.z)
			
			if not sight or (dist > 1024*FRACUNIT)
			or (valid(target.player) and target.player.playerstate == PST_DEAD) then 
				mo.target = nil
			else
				spawnArrow(mo, target)
				if not p.climbing
				and not (p.pflags & PF_SPINNING)
				and not (p.pflags & PF_STARTDASH)
				and not (p.pflags & PF_GLIDING) then
					mo.angle = R_PointToAngle2(mo.x, mo.y, target.x, target.y)
					p.drawangle = mo.angle
					p.aiming = R_PointToAngle2(0, 0, dist, zdiff)
				end
			end
		end
	end

	-- Outline thinker. Referenced by p.mo.outline.
	for p in players.iterate
		if not valid(p.mo) or p.spectator then continue end
		local mo = p.mo
		if not valid(mo.outline) then continue end
		local o = mo.outline
		local target = o.target
		o.angle = target.angle
		o.skin = target.skin
		o.sprite2 = target.sprite2
		o.state = target.state
		o.frame = target.frame
		if (mo.flags2 & MF2_DONTDRAW) then
			o.flags2 = $ | MF2_DONTDRAW
		else
			o.flags2 = $ & ~MF2_DONTDRAW
		end
		o.color = target.color
		o.colorized = true
		o.scale = 115*target.scale/100
		--o.spritexscale = 115*target.scale/100
		o.blendmode = AST_ADD
		local bga = R_PointToAngle(target.x, target.y) -- Background angle
		-- Place this object "behind" the player
		P_TeleportMove(o, target.x + FixedMul(cos(bga), FRACUNIT), 
							target.y + FixedMul(sin(bga), FRACUNIT), 
							target.z - FixedMul(o.scale, 4*FRACUNIT))
	end
	
	/*-- Copied from source
	for p in players.iterate
		if p.exiting 
		or p.spectator 
		or (p.playerstate ~= PST_LIVE) then 
			continue
		end
		doFireRing(p, p.cmd)
	end*/
end)

addHook("MobjThinker", function(mo)
	if (not valid(mo.target) and mo.skin)
	or (valid(mo.target) and valid(mo.target.player) and (mo.target.player.playerstate == PST_DEAD)) then
		P_RemoveMobj(mo)
	end
end, MT_DUMMY)

-- From Rollout Knockout
rawset(_G, "deathThink1", function(p)
	if not valid(p) then return end
	if not valid(p.mo) then return end
	
	local mo = p.mo -- Simplify
	if (mo.fuse > 1) 
	and not (leveltime%7) then -- Buildup to explosion.
			local r = mo.radius>>FRACBITS
			local xpld = P_SpawnMobj(mo.x + (P_RandomRange(-r, r)<<FRACBITS),
							mo.y + (P_RandomRange(-r, r)<<FRACBITS),
							mo.z + (P_RandomKey(mo.height>>FRACBITS)<<FRACBITS),
							MT_SONIC3KBOSSEXPLODE)
			S_StartSound(xpld, sfx_s3kb4)
	elseif (mo.fuse == 1) then -- Explode!
		mo.momx = 0
		mo.momy = 0
		mo.momz = 0
		local xpld = P_SpawnMobj(mo.x, mo.y, mo.z, MT_DUMMY) -- Spawn an object.
		xpld.state = S_RXPL1
		xpld.scale = 2*FRACUNIT
		/*local xpld = P_SpawnMobj(mo.x, mo.y, mo.z + mo.height/2, MT_DUMMY) -- Spawn an object.
		xpld.state = S_SXPA*/
		S_StartSound(xpld, sfx_pplode) -- Play a sound.
		--if cv_rkquake.value then -- If the specified consvar is enabled...
			P_StartQuake(40*FRACUNIT, 5) -- Shake the screen.
		--end
		
		-- Flash the screen
		for px in players.iterate do
			if (px == p) then continue end -- Us? Skip.
			if px.spectator then continue end -- Spectator? Skip
			if not px.mo then continue end -- Mo doesn't exist? Skip
			local idist = FixedHypot(FixedHypot(px.mo.x - p.mo.x, px.mo.y - p.mo.y), px.mo.z - p.mo.z)
			if (idist < 512*FRACUNIT) then 
				P_FlashPal(px, 1, 3)
			end
		end
		P_FlashPal(p, 1, 3)
	end
end)

addHook("PlayerThink", function(p)
	if (p.playerstate == PST_DEAD) then deathThink1(p) end
end)

addHook("MobjDeath", function(mo)
	if valid(mo) and valid(mo.player) then
		local p = mo.player
		mo.flags = $ & ~(MF_SOLID|MF_SHOOTABLE)
		mo.flags = $ | (MF_NOBLOCKMAP|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY)

		if not p.bot and not p.spectator and (p.lives ~= INFLIVES) and G_GametypeUsesLives() then
			if not (p.pflags & PF_FINISHED) then p.lives = $ - 1 end
		end
		
		mo.fuse = TICRATE -- NEEDS to be set to have the player visible on death.
		mo.state = S_PLAY_PAIN
		p.playerstate = PST_DEAD
		mo.momx = $/4
		mo.momy = $/4
		P_SetObjectMomZ(mo, 20*FRACUNIT, false)
		return true
	end
end, MT_PLAYER)