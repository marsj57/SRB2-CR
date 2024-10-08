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

addHook("MobjThinker",function(mo)
	if not valid(mo) then return false end
	if G_IsFLCRGametype() then
		if ((leveltime%7) == 0) then P_SpawnMobjFromMobj(mo,0,0,0,MT_SPARK) end
		mo.fuse = min($,TICRATE)
	end
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
	table.sort(vtx, function(a,b) return b.x > a.x end)
	boundary.left = vtx[1].x
	boundary.right = vtx[#vtx].x

	-- Get our topmost and bottommost y
	table.sort(vtx, function(a,b) return b.y > a.y end)
	boundary.top = vtx[1].y
	boundary.bottom = vtx[#vtx].y

	return boundary.top,
			boundary.bottom,
			boundary.left, 
			boundary.right
end

addHook("ThinkFrame", do
	if not (leveltime%5) then return end -- Don't trigger every tic
	for sector in sectors.iterate
		if not valid(sector) then continue end
		local sec = sector
		-- If sector special is a elemental damaging floor, spawn some FX!
		local IsSectorElectric = (GetSecSpecial(sec.special, 1) == 4) and true or false
		local IsSectorFire = (GetSecSpecial(sec.special, 1) == 3) and true or false

		-- First check to see if sector is actually a elemental damaging floor.
		-- This is a sanity check, otherwise this WILL cause frame drops.
		if not (IsSectorElectric and IsSectorFire) then continue end

		local top, bottom, left, right = Lib.getSectorBounds(sec)
		local xrand, yrand
		xrand = P_RandomRange(left>>FRACBITS, right>>FRACBITS)<<FRACBITS
		yrand = P_RandomRange(top>>FRACBITS, bottom>>FRACBITS)<<FRACBITS

		-- Valid sector
		if (R_PointInSubsector(xrand, yrand).sector ~= sec) then continue end

		-- Spawn the FX!
		local fx = P_SpawnMobj(xrand, yrand, sec.floorheight + 1, MT_DUMMYFX)

		-- FX state dependent on sector type
		if IsSectorElectric then
			if P_RandomChance(FRACUNIT/16) then
				fx.state = S_FX_ELECUP1
			else
				fx.state = S_FX_ELECUP2
			end
		elseif IsSectorFire then
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
	if not G_IsFLCRGametype() then return end
	-- Target finder, and thinker.
	for player in players.iterate
		if not Lib.validCRPlayerData(player) then continue end
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
		if mo.followarrow then -- Non-nil table?
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

-- Sector bounds debugger
/*addHook("PreThinkFrame", do
	for p in players.iterate
		local mo = p.mo or p.realmo
		if not valid(mo) then continue end
		if (p.cmd.buttons & BT_CUSTOM1)
			local top, bottom, left, right = Lib.getSectorBounds(mo.subsector.sector)
			
			-- Spawn the FX!
			local xrand, yrand
			xrand = P_RandomRange(left>>FRACBITS, right>>FRACBITS)<<FRACBITS
			yrand = P_RandomRange(top>>FRACBITS, bottom>>FRACBITS)<<FRACBITS
			local fx = P_SpawnMobj(xrand, yrand, mo.floorz, MT_SPARK)
			P_SetObjectMomZ(fx, 5*FRACUNIT, false)
		end
	end
end)*/

/*-- Thinker for the outline mobj when the host (refmobj) dies
addHook("MobjThinker", function(mo)
	if (not valid(mo.refmo) and mo.skin)
	or (valid(mo.refmo) and valid(mo.refmo.player) and (mo.refmo.player.playerstate == PST_DEAD)) then
		P_RemoveMobj(mo) -- You should remove yourself, NOW!
	end
end, MT_DUMMY)*/

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

addHook("MobjThinker", function(mo)
	if not valid(mo) then return false end
	if (mo.color >= SKINCOLOR_CR_FLATRED)
	and (mo.color <= SKINCOLOR_CR_FLATGREEN) 
	and (mo.momx or mo.momy or mo.momz) 
	and (mo.flags2 & MF2_DEBRIS) then
		mo.momx = $ - $/16
		mo.momy = $ - $/16
		mo.momz = $ - $/16
		
		/*if (P_MobjFlip(mo)*mo.momz < 0)
		and ((mo.z+(mo.momz/2) <= mo.floorz)
		or (mo.z+(mo.momz/2) >= mo.ceilingz))
			P_SetObjectMomZ(mo, -mo.momz/2, false)
		end*/

		if mo.prev then
			for i = 1, 5 do -- How many objects to spawn between previous and current x,y,z positions
				local x = ease.linear(i*FRACUNIT/5, mo.prev.x, mo.x)
				local y = ease.linear(i*FRACUNIT/5, mo.prev.y, mo.y)
				local z = ease.linear(i*FRACUNIT/5, mo.prev.z+mo.height/2, mo.z+mo.height/2)

				local subfx = P_SpawnGhostMobj(mo)
				P_SetOrigin(subfx, x, y, z)
				subfx.scale = mo.scale/3
			end
		end
		mo.prev = {
			x = mo.x,
			y = mo.y,
			z = mo.z,
		}
	end
	return false
end, MT_DUMMYFX)

rawset(_G, "deathThink2", function(p)
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
	and (leveltime%4) < 2 then -- Buildup to explosion.
			local r = mo.radius>>FRACBITS
			local fx = P_SpawnGhostMobj(mo)
			--fx.blendmode = AST_ADD
			fx.color = P_RandomRange(SKINCOLOR_CR_FLATRED, SKINCOLOR_CR_FLATGREEN)
			
			-- Vizualization: Pop like a balloon
			if (mo.fuse <= 4) then
				local percent = FRACUNIT/mo.fuse
				mo.scale = ease.linear(percent, 4*FRACUNIT/3, 2*FRACUNIT)
			end
	elseif (mo.fuse == 1) then -- Explode!
		mo.momx = 0
		mo.momy = 0
		mo.momz = 0
		p.deadtimer = 3*TICRATE
		
		local g = P_SpawnGhostMobj(mo)
		g.fuse = TICRATE/7
		g.scale = mo.scale
		g.frame = mo.frame & FF_FRAMEMASK | (FF_FULLBRIGHT|FF_TRANS50)
		g.destscale = mo.scale*6
		g.scalespeed = mo.scale/3
		g.sprite2 = mo.sprite2
		g.color = mo.color
		g.colorized = true
		g.blendmode = AST_ADD
		g.tics = -1

		local wfx = P_SpawnMobjFromMobj(mo, 0,0,mo.height/3, MT_DUMMYFX)
		wfx.color = mo.color
		wfx.colorized = true
		wfx.state = S_FX_WIND
		wfx.frame = $ & ~FF_PAPERSPRITE
		S_StartSound(mo, sfx_s3k81) -- [Burst]
		S_StartSound(mo, sfx_s3k4e) -- [Big explosion]
		--S_StartSound(mo, sfx_s3k61) -- [Drilling]

		for i = 0, 31 do
			--if P_RandomChance(FRACUNIT/4) then continue end
			local fa = i*ANGLE_22h -- How many angles can the explosion debris go in?
			local ns = P_RandomRange(40,100)<<FRACBITS
			
			local fx = P_SpawnMobj(mo.x, mo.y, mo.z, MT_DUMMYFX)
			fx.state = S_THOK
			fx.tics = -1
			fx.frame = fx.frame & FF_FRAMEMASK | (FF_FULLBRIGHT)
			fx.blendmode = AST_ADD
			fx.color = P_RandomRange(SKINCOLOR_CR_FLATRED, SKINCOLOR_CR_FLATGREEN)
			fx.angle = fa
			fx.scale = 2*FRACUNIT

			P_InstaThrust(fx, fx.angle, ns)

			if (i > 15) then
				-- For every other explosion object above 15,
				-- apply alternating momz to the explosion debris.
				if (i&1) then 
					fx.momz = (ns*4)/5
				else
					fx.momz = -((ns*4)/5)
				end
				--fx.flags = $ & ~MF_NOGRAVITY -- Allow these to have gravity
			else
				fx.momz = P_RandomRange(-10, 10)<<FRACBITS
			end
			
			fx.flags = $ & ~(MF_NOCLIP|MF_NOCLIPHEIGHT)
			fx.flags = $ | MF_BOUNCE|MF_NOCLIPTHING|MF_MISSILE|MF_GRENADEBOUNCE
			fx.flags2 = $ | MF2_DEBRIS
			fx.fuse = TICRATE/2+1 -- Die in half a second.

			fx.prev = {
				x = fx.x,
				y = fx.y,
				z = fx.z,
			}
		end
		P_StartQuake(40*FRACUNIT, 5) -- Shake the screen.
	end
end)

addHook("PlayerThink", function(p)
	if not G_IsFLCRGametype() then return end
	if not valid(p) then return end
	if (p.playerstate == PST_DEAD) then deathThink2(p) return end
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
		if p.crplayerdata then
			local CRPD = FLCR.PlayerData[p.crplayerdata.id]
			CRPD.alivetics = 0
			CRPD.state = CRPS_LOSE
			CRPD.statetics = 0
		end
		P_SetObjectMomZ(mo, 20*FRACUNIT, false)
		--S_StartSound(mo, sfx_kc5b)
		S_StartSound(mo, sfx_s3ka0) -- [Launch]
		--p.cmd.angleturn = 0
		return true
	end
end, MT_PLAYER)