-- Hey, you're awfully nosy aren't you?
-- Just so you know, a lot of what you see here is mixed between original code
-- and code that I've gotten permission to use.
--
-- A word of warning: YOU SHOULD ASSUME __NONE__ OF THE CODE HERE IS REUSABLE.
-- GET PERMISSION TO USE THIS STUFF BEFORE YOU USE IT YOURSELF
--
-- Flame

local Lib = FLCRLib

addHook("MobjThinker",function(mo)
	if not valid(mo) then return false end
	mo.fuse = min($,TICRATE)
	return false
end, MT_FLINGRING)

Lib.getSectorBounds = function(sec)
	if not valid(sec) then return end -- Sanity check
	local numlines = #sec.lines
	local vtx = {} -- Vertex collection table.
	for i = 0, numlines - 1 do
		table.insert(vtx, { x = sec.lines[i].v1.x, y = sec.lines[i].v1.y }) -- Put these values in a table.
		--print("Vertex #"..(i+1).." indexed! (X: ".. vtx[i+1].x/FRACUNIT ..", Y: ".. vtx[i+1].y/FRACUNIT ..")")
	end
	
	local boundary = {}
	-- Get our leftmost and rightmost x
	/*for k,v in spairs(vtx, function(t,a,b) return t[b].x > t[a].x end) do
		if k == 1 then -- Leftmost
			boundary.left = v.x/FRACUNIT
		elseif k == #vtx then -- Rightmost
			boundary.right = v.x/FRACUNIT
		end
	end*/
	table.sort(vtx, function(a,b) do b.x > a.x end)
	boundary.left = vtx[1]
	boundary.right = vtx[#vtx]
	
	-- Get our topmost and bottommost y
	/*for k,v in spairs(vtx, function(t,a,b) return t[b].y > t[a].y end) do
		if k == 1 then -- Topmost
			boundary.top = v.y/FRACUNIT
		elseif k == #vtx then -- Bottommost
			boundary.bottom = v.y/FRACUNIT
		end
	end*/
	table.sort(vtx, function(a,b) do b.y > a.y end)
	boundary.top = vtx[1]
	boundary.bottom = vtx[#vtx]
	
	return boundary.top,
			boundary.bottom,
			boundary.left, 
			boundary.right
end

addHook("ThinkFrame", do
	if (leveltime%5) then return end -- Don't trigger every tic
	for sector in sectors.iterate
		if not valid(sector) then continue end
		local sec = sector
		-- If sector special is a elemental damaging floor, spawn some FX!
		local IsSectorElectric = (GetSecSpecial(sec.special, 1) == 4) and true or false
		local IsSectorFire = (GetSecSpecial(sec.special, 1) == 3) and true or false
		if IsSectorElectric then
			local top, bottom, left, right = Lib.getSectorBounds(sec)
			
			-- Spawn the FX!
			local xrand, yrand
			xrand = P_RandomRange(left, right)<<FRACBITS
			yrand = P_RandomRange(top, bottom)<<FRACBITS
			if (R_PointInSubsector(xrand, yrand).sector ~= sec) then continue end
			
			local fx = P_SpawnMobj(xrand, yrand, sec.floorheight + 1, MT_DUMMYFX)
			if P_RandomChance(FRACUNIT/16) then
				fx.state = S_FX_ELECUP1
			else
				fx.state = S_FX_ELECUP2
			end
		elseif IsSectorFire then
			local top, bottom, left, right = Lib.getSectorBounds(sec)
			-- Spawn the FX!
			local xrand, yrand
			xrand = P_RandomRange(left, right)<<FRACBITS
			yrand = P_RandomRange(top, bottom)<<FRACBITS
			if (R_PointInSubsector(xrand, yrand).sector ~= sec) then continue end
			
			local fx = P_SpawnMobj(xrand, yrand, sec.floorheight + 1, MT_DUMMYFX)
			fx.state = S_FX_FIREUP1		
		end
	end
end)

addHook("PlayerSpawn", function(p)
	if not G_IsFLCRGametype() then return false end
	if not valid(p) then return false end
	if not valid(p.mo) then return false end
	local mo = p.mo
	
	/*if not mo.outline then
		local o = P_SpawnMobj(mo.x, mo.y, mo.z, MT_DUMMY)
		o.state = S_THOK
		o.angle = mo.angle
		o.refmo = mo
		o.skin = mo.skin
		o.tics = -1 -- Special S_THOK state thing. Don't make this disappear.
		o.health = -1
		mo.outline = o
	end*/
	
	if not mo.followarrow then
		mo.followarrow = {}
		for i = 0, 1 do
			local o = P_SpawnMobj(mo.x, mo.y, mo.z, MT_DUMMY)
			o.state = S_NTHK
			o.frame = $ + i
			o.skin = mo.skin
			o.health = -1
			table.insert(mo.followarrow, o)
		end
	end
end)

addHook("ThinkFrame", do
	-- Target finder, and thinker.
	for player in players.iterate
		if not valid(player) then continue end
		if not player.crplayerdata then continue end
		local CRPD = FLCR.PlayerData[player.crplayerdata.id]
		if not valid(CRPD.player) then continue end
		local p = CRPD.player
		
		if not valid(p.mo) or p.spectator 
		or (p.playerstate == PST_DEAD) then continue end
		local mo = p.mo
		if not mo.target then
			mo.target = Lib.Look4ClosestPlayer(mo, FixedMul(2048*FRACUNIT, mo.scale))
		else
			local target = mo.target
			local sight = P_CheckSight(mo, target)
			local dist = FixedHypot(mo.x - target.x, mo.y - target.y)
			local zdiff = ((target.z+(target.height/2)) - (mo.z+(mo.height/2)))
			
			if not sight or (dist > FixedMul(2048*FRACUNIT, mo.scale))
			or (valid(target.player) and target.player.playerstate == PST_DEAD)
			or (valid(target.player) and target.player.spectator) then 
				mo.target = nil
				p.aiming = 0
			else
				if not p.climbing
				--and not (p.pflags & PF_SPINNING)
				and not (p.pflags & PF_STARTDASH)
				and not (p.pflags & PF_GLIDING) then
					mo.angle = R_PointToAngle2(mo.x, mo.y, target.x, target.y)
					if (CRPD.state == CRPS_NORMAL) then p.drawangle = mo.angle end
					p.aiming = R_PointToAngle2(0, 0, dist, zdiff)
				end
			end
		end
		
		-- Arrow thinker
		for i = 1, #mo.followarrow do
			if not valid(mo.followarrow[i]) then continue end
			local o = mo.followarrow[i]
			o.tics = 3
			o.color = mo.color
			local bga = R_PointToAngle(mo.x, mo.y) -- Background angle
			if (i == #mo.followarrow) then
				P_MoveOrigin(o, mo.x + FixedMul(cos(mo.angle), 30*o.scale),
								mo.y + FixedMul(sin(mo.angle), 30*o.scale),
								mo.z)
			else
				P_MoveOrigin(o, mo.x + FixedMul(cos(bga), FRACUNIT),
								mo.y + FixedMul(sin(bga), FRACUNIT),
								mo.z)
			end
			if o.floorspriteslope then
				local slope = o.floorspriteslope
				o.angle = mo.angle
				slope.o = {x = o.x, y = o.y, z = o.z}
				slope.xydirection = o.angle
				if (i == #mo.followarrow) then
					slope.zangle = p.aiming
				end
			end

			if valid(mo.target) then
				o.flags2 = $ & ~MF2_DONTDRAW
			else
				o.flags2 = $ | MF2_DONTDRAW
			end
		end
	end

	/*-- Outline thinker. Referenced by p.mo.outline.
	for p in players.iterate
		if not valid(p.mo) or p.spectator then continue end
		local mo = p.mo
		if not valid(mo.outline) then continue end
		local o = mo.outline
		local target = o.refmo
		o.angle = target.player and target.player.drawangle or target.angle
		o.skin = target.skin
		o.sprite2 = target.sprite2
		o.state = target.state
		o.frame = target.frame
		o.fuse = 3
		if (mo.flags2 & MF2_DONTDRAW) then
			o.flags2 = $ | MF2_DONTDRAW
		else
			o.flags2 = $ & ~MF2_DONTDRAW
		end
		
		local r = skincolors[target.color].ramp[7] -- ramp is 0 indexed
		if skincolors[SKINCOLOR_P1_OUTLINE + #p].ramp[7] ~= r then -- Avoid setting repeatedly
			skincolors[SKINCOLOR_P1_OUTLINE + #p].ramp = {r,r,r,r,r,r,r,r,r,r,r,r,r,r,r,r}
		end
		o.color = SKINCOLOR_P1_OUTLINE + #p --#p is 0 indexed
		
		o.colorized = true
		o.scale = 115*target.scale/100
		--o.spritexscale = 105*FRACUNIT/100
		o.blendmode = AST_ADD
		local bga = R_PointToAngle(target.x, target.y) -- Background angle
		-- Place this object "behind" the player
		P_MoveOrigin(o, target.x + FixedMul(cos(bga), FRACUNIT), 
							target.y + FixedMul(sin(bga), FRACUNIT), 
							target.z - FixedMul(o.scale, 4*FRACUNIT))
	end*/
end)

/*-- Thinker for the outline mobj when the host (refmobj) dies
addHook("MobjThinker", function(mo)
	if (not valid(mo.refmo) and mo.skin)
	or (valid(mo.refmo) and valid(mo.refmo.player) and (mo.refmo.player.playerstate == PST_DEAD)) then
		P_RemoveMobj(mo) -- You should remove yourself, NOW!
	end
end, MT_DUMMY)*/

-- From Rollout Knockout
rawset(_G, "deathThink1", function(p)
	if not valid(p) then return end
	local mo = p.mo or p.realmo
	if not valid(mo) then return end

	--if valid(mo.outline) then P_RemoveMobj(mo.outline) end
	if mo.followarrow then
		for i = 1, #mo.followarrow do
			if not valid(mo.followarrow[i]) then continue end
			P_RemoveMobj(mo.followarrow[i])
		end
	end

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
		p.deadtimer = 3*TICRATE
		local xpld = P_SpawnMobj(mo.x, mo.y, mo.z, MT_DUMMY) -- Spawn an object.
		xpld.state = S_RXPL1
		xpld.scale = 2*FRACUNIT
		S_StartSound(xpld, sfx_pplode) -- Play a sound.
		--if cv_rkquake.value then -- If the specified consvar is enabled...
			P_StartQuake(40*FRACUNIT, 5) -- Shake the screen.
		--end
		
		-- Flash the screen
		/*for px in players.iterate do
			if (px == p) then continue end -- Us? Skip.
			if px.spectator then continue end -- Spectator? Skip
			if not px.mo then continue end -- Mo doesn't exist? Skip
			-- mo sometimes doesn't exist here. TODO: Figure out which mo
			local idist = FixedHypot(FixedHypot(px.mo.x - p.mo.x, px.mo.y - p.mo.y), px.mo.z - p.mo.z)
			if (idist < 512*FRACUNIT) then 
				P_FlashPal(px, 1, 3)
			end
		end
		P_FlashPal(p, 1, 3)*/
	end
end)

addHook("PlayerThink", function(p)
	if not G_IsFLCRGametype() then return end
	if not valid(p) then return end
	if (p.playerstate == PST_DEAD) then deathThink1(p) return end
end)

addHook("MobjDeath", function(mo)
	if not G_IsFLCRGametype() then return false end
	if valid(mo) and valid(mo.player) then
		local p = mo.player
		mo.flags = $ & ~(MF_SOLID|MF_SHOOTABLE)
		mo.flags = $ | (MF_NOBLOCKMAP|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY)
		
		mo.fuse = TICRATE -- NEEDS to be set to have the player visible on death.
		mo.state = S_PLAY_PAIN
		p.playerstate = PST_DEAD
		mo.momx = $/4
		mo.momy = $/4
		P_SetObjectMomZ(mo, 20*FRACUNIT, false)
		--p.cmd.angleturn = 0
		return true
	end
end, MT_PLAYER)