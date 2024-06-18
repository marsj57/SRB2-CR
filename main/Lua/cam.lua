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

freeslot("MT_FLCRCAM")

mobjinfo[MT_FLCRCAM] = {
	doomednum = -1,
	spawnstate = S_INVISIBLE,
	spawnhealth = 1000,
	radius = 16*FRACUNIT,
	height = 32*FRACUNIT,
	flags = MF_NOGRAVITY|MF_NOCLIPTHING|MF_NOBLOCKMAP|MF_NOCLIPHEIGHT|MF_NOCLIP
}

local function CRHudToggle()
	if G_IsFLCRGametype() then
		hud.disable("rings")
		hud.disable("lives")
		hud.disable("score")
		hudinfo[HUD_RINGS].y = 26 --hudinfo[HUD_TIME].y
		hudinfo[HUD_RINGSNUM].y = 26 -- --hudinfo[HUD_TIME].y
		hudinfo[HUD_TIME].y = 10 --hudinfo[HUD_SCORE].y
		hudinfo[HUD_MINUTES].y = 10
		hudinfo[HUD_TIMECOLON].y = 10
		hudinfo[HUD_SECONDS].y = 10
		hudinfo[HUD_TIMETICCOLON].y = 10
		hudinfo[HUD_TICS].y = 10
		hud.disable("weaponrings")
		hud.disable("nightslink")
		hud.disable("nightsdrill")
		hud.disable("nightsrings")
		hud.disable("nightsscore")
		hud.disable("nightstime")
		hud.disable("nightsrecords")
		hud.disable("rankings")
		hud.disable("textspectator")
	elseif G_IsVanillaGametype()
		hud.enable("rings")
		hud.enable("lives")
		hud.enable("score")
		hudinfo[HUD_RINGS].y = 42
		hudinfo[HUD_RINGSNUM].y = 42
		hudinfo[HUD_TIME].y = 26
		hudinfo[HUD_MINUTES].y = 26
		hudinfo[HUD_TIMECOLON].y = 26
		hudinfo[HUD_SECONDS].y = 26
		hudinfo[HUD_TIMETICCOLON].y = 26
		hudinfo[HUD_TICS].y = 26
		hud.enable("weaponrings")
		hud.enable("nightslink")
		hud.enable("nightsdrill")
		hud.enable("nightsrings")
		hud.enable("nightsscore")
		hud.enable("nightstime")
		hud.enable("nightsrecords")
		hud.enable("rankings")
		hud.enable("textspectator")
	end
end

-- Lactozilla
local MINZ = (FRACUNIT*4)
local FEETADJUST = -(10<<FRACBITS)
rawset(_G, "R_ProjectSprite", function(v, thing, cam)
	if (not v) then return end
	if (not (thing and thing.valid)) then return end
	if (not cam) then return end

	local viewpoint = cam
	local viewz = viewpoint.z
	local aimingangle = cam.aiming
	if (not cam.chase) then
		viewpoint = displayplayer.mo
		viewz = displayplayer.viewz
		aimingangle = displayplayer.aiming
		if (not viewpoint.valid) then return end
	end

	-- R_ExecuteSetViewSize
	local s, fovcv = pcall(CV_FindVar, "fov")
	local fov = s and fovcv.value/2 or FixedAngle(45*FRACUNIT)
	local fovtan = tan(fov)
	if (splitscreen) then -- Splitscreen FOV should be adjusted to maintain expected vertical view
		fovtan = 17*fovtan/10
	end

	local center = {
		x = v.width() / 2,
		y = v.height() / 2
	}

	-- aiming
	if (v.renderer() == "software") then
		local function AIMINGTODY(a)
			return FixedDiv((tan(a)*160)>>FRACBITS, fovtan)
		end
		local angle = aimingangle
		local invmul = 1
		if (angle < 0) then
			angle = abs(angle)
			invmul = -1
		end
		center.y = $ + (AIMINGTODY(angle) * invmul * (v.width() / 320))
	end

	local centerxfrac = center.x<<FRACBITS
	local centeryfrac = center.y<<FRACBITS
	local projection = FixedDiv(centerxfrac, fovtan)
	local projectiony = projection

	local viewcos = cos(viewpoint.angle)
	local viewsin = sin(viewpoint.angle)

	-- transform the origin point
	local this_scale = thing.scale
	local tr_x = thing.x - viewpoint.x
	local tr_y = thing.y - viewpoint.y

	local gxt = FixedMul(tr_x, viewcos)
	local gyt = -FixedMul(tr_y, viewsin)

	local tz = gxt - gyt

	-- thing is behind view plane?
	if (tz < FixedMul(MINZ, this_scale)) then
		return
	end

	if thing.player then
		local skin = skins[thing.skin]
		if (thing.skin and (skin.flags & SF_HIRES)) then
			this_scale = FixedMul(this_scale, skin.highresscale)
		end
	end

	gxt = -FixedMul(tr_x, viewsin)
	gyt = FixedMul(tr_y, viewcos)
	local tx = -(gyt + gxt)

	-- too far off the side?
	if (abs(tx) > tz<<2) then
		return
	end

	-- aspect ratio stuff :
	local xscale = FixedDiv(projection, tz)
	local yscale = FixedDiv(projectiony, tz)

	local ang = R_PointToAngle(thing.x, thing.y)
	if thing.player then
		ang = $ - thing.player.drawangle
	else
		ang = $ - thing.angle
	end

	local patch = nil
	local flipped = false
	local frameangle = ((ang+ANGLE_202h)>>29)
	if thing.player or thing.sprite2 then
		local super = thing.player and (thing.player.powers[pw_super] > 0) or false
		patch, flipped = v.getSprite2Patch(thing.skin, thing.sprite2, super, thing.frame, frameangle+1)
	else
		patch, flipped = v.getSpritePatch(thing.sprite, thing.frame, frameangle+1)
	end

	if (patch == nil) then
		return
	end

	local vflip = (thing.eflags & MFE_VERTICALFLIP) or (thing.frame & FF_VERTICALFLIP)

	-- calculate edges of the shape
	local offset, offset2
	if (flipped) then
		offset = (patch.leftoffset<<FRACBITS) - (patch.width<<FRACBITS)
	else
		offset = -(patch.leftoffset<<FRACBITS)
	end
	offset = FixedMul($, this_scale)
	offset2 = FixedMul((patch.width<<FRACBITS), this_scale)

	tx = $ + offset
	local x1 = (centerxfrac + FixedMul (tx,xscale)) >>FRACBITS

	-- off the right side?
	if (x1 > v.width()) then
		return
	end

	tx = $ + offset2
	local x2 = (centerxfrac + FixedMul (tx,xscale)) >>FRACBITS

	-- off the left side
	if (x2 < 0) then
		return
	end

	local topoffset = (patch.topoffset<<FRACBITS) + FEETADJUST
	local gzt, gz

	if (vflip) then
		gz = thing.z + thing.height - FixedMul(topoffset, this_scale)
		gzt = gz + FixedMul((patch.height<<FRACBITS), this_scale)
	else
		gzt = thing.z + FixedMul(topoffset, this_scale)
		gz = gzt - FixedMul((patch.height<<FRACBITS), this_scale)
	end

	-- Lactozilla: projected after R_ProjectSprite
	local texturemid = FixedDiv(gzt - viewz, this_scale)
	local spryscale = FixedMul(yscale, this_scale)
	local sprtopscreen = centeryfrac - FixedMul(texturemid, spryscale) -- R_DrawVisSprite
	local sprbotscreen = sprtopscreen + FixedMul(patch.height<<FRACBITS, spryscale) -- R_DrawMaskedColumn

	--v.drawString(0, stats_y, "x1: "+ x1)
	--v.drawString(0, stats_y+10, "x2: "+ x2)
	--v.drawString(0, stats_y+20, "sprtopscreen: "+ FixedInt(sprtopscreen))
	--v.drawString(0, stats_y+30, "sprbotscreen: "+ FixedInt(sprbotscreen))

	-- draw bounding box
	--v.drawFill(x1, FixedInt(sprtopscreen), (x2-x1), FixedInt(sprbotscreen-sprtopscreen), 36|V_NOSCALESTART)

	-- draw the sprite
	local x = (x1<<FRACBITS) + FixedMul((flipped and (patch.width-patch.leftoffset) or patch.leftoffset)<<FRACBITS, spryscale)
	local y = sprtopscreen + FixedMul((patch.topoffset<<FRACBITS), spryscale)
	local flags = (V_NOSCALESTART|V_NOSCALEPATCH|V_50TRANS)
	if flipped then
		flags = $ | V_FLIP
	end
	local color = v.getColormap(TC_BLINK, thing.color or SKINCOLOR_GREY)
	v.drawScaled(x, y, spryscale, patch, flags, color)
end)
-- End Lactozilla

local vwidth = 160
local vheight = 100
addHook("HUD", function(v)
	vwidth,vheight = v.width(), v.height()
end)
rawset(_G, "R_ScreenTransform", function(x, y, z)
	local ang, aim
	if camera.chase then -- obtain the differences
		z = $ - camera.z
		ang = camera.angle
		aim = camera.aiming
	elseif valid(consoleplayer.mo) then
		if valid(consoleplayer.awayviewmobj) then
			local avm = consoleplayer.awayviewmobj -- Simplify
			z = $ - avm.z
			ang = avm.angle
			aim = consoleplayer.awayviewaiming
		else
			z = $ - consoleplayer.viewz
			ang = consoleplayer.mo.angle
			aim = consoleplayer.aiming
		end
	else -- Camera not chasing, consoleplayer mo not valid?
		return false -- Don't process anything.
	end
	local h = R_PointToDist(x, y)
	local da = ang - R_PointToAngle(x, y)
	local sizex = vwidth/2
	local sizey = vheight/2
	local s, fov = pcall(CV_FindVar, "fov")
	local fov = FixedAngle(s and fov.value or 90*FRACUNIT)

	return sizex<<FRACBITS + tan(da)*sizex,
	sizey<<FRACBITS + (tan(aim) - FixedDiv(z, 1 + FixedMul(cos(da), h)))*sizex,
	FixedDiv((sizex<<FRACBITS), h+1),
	(abs(da) > fov/2) or (abs(aim - R_PointToAngle2(0, 0, h, z)) > ((fov/3)+(ANG10/3)) )
end)

addHook("MapLoad", function(mapnum)
	FLCR.CameraBattleAngle = 0
end)

addHook("PreThinkFrame", do
	if not G_IsFLCRGametype() then return end
	for p in players.iterate
		if not valid(p.mo) 
		or p.spectator 
		or (p.playerstate == PST_DEAD) then
			continue 
		end
		
		-- Set Analog if not already
		if not (p.pflags & PF_ANALOGMODE) then p.pflags = $ | PF_ANALOGMODE end
		
		-- Awayview time will always be 3 seconds unless player no longer exists
		p.awayviewtics = 3*TICRATE
		p.awayviewmobj.tics = p.awayviewtics
		
		p.cmd.angleturn = FLCR.CameraBattleAngle>>FRACBITS
	end
end)

addHook("PlayerSpawn", function(p)
	if not G_IsFLCRGametype() then return false end
	if not valid(p) then return false end
	if not valid(p.mo) then return false end
	local mo = p.mo
	
	-- Camera mobj. Not using camera_t.
	-- Pay attention to this if statement.
	-- If no p.awayviewmobj is present, the player's mobj is used instead! Shocking!
	-- This causes a bunch of weird things to happen!
	if not p.awayviewmobj then
		local o = P_SpawnMobj(mo.x, mo.y, mo.z, MT_FLCRCAM)
		o.state = S_THOK
		o.angle = mo.angle
		o.flags2 = $ | MF2_DONTDRAW
		o.tics = -1
		o.target = mo
		o.health = -1
		p.awayviewmobj = o
		p.awayviewtics = o.tics
	end
	
	p.pflags = $ | PF_ANALOGMODE
	--CV_Set(CV_FindVar("chasecam"), 1)
	camera.chase = true
end, MT_PLAYER)

Lib.drawLine = function(startpoint, endpoint, color, numpoints, duration)
	-- Sanity.
	local aIsTable = (type(startpoint) == "table")
	local bIsTable = (type(endpoint) == "table")
	if not aIsTable then
		error("bad argument #1 to 'Lib.drawLine' (table expected, got " .. type(startpoint) .. ")")
	elseif not bIsTable then
		error("bad argument #2 to 'Lib.drawLine' (table expected, got " .. type(endpoint) .. ")")
	end

	if not numpoints then numpoints = 2 end
	for i = 1, numpoints do
		local x = ease.linear(i*FRACUNIT/numpoints, startpoint.x, endpoint.x)
		local y = ease.linear(i*FRACUNIT/numpoints, startpoint.y, endpoint.y)
		local z = ease.linear(i*FRACUNIT/numpoints, startpoint.z, endpoint.z)
		
		local th = P_SpawnMobj(x,y,z,MT_THOK)
		th.flags = $|MF_NOBLOCKMAP|MF_SCENERY
		th.color = color or SKINCOLOR_WHITE
		th.tics = duration or 1
		th.scale = FRACUNIT/2
		th.blendmode = AST_ADD
	end
end

Lib.drawBounds = function(b, c, np, dur)
	local bIsTable = (type(b) == "table") -- b is table
	if not bIsTable then -- Sanity check
		error("bad argument #1 to 'Lib.drawBounds' (table expected, got " .. type(b) .. ")")
	end

	// bottom
	local p1 = {x = b.min.x, y = b.min.y, z = b.min.z}
	local p2 = {x = b.max.x, y = b.min.y, z = b.min.z}
	local p3 = {x = b.max.x, y = b.min.y, z = b.max.z}
	local p4 = {x = b.min.x, y = b.min.y, z = b.max.z}

	Lib.drawLine(p1, p2, c, np, dur)
	Lib.drawLine(p2, p3, c, np, dur)
	Lib.drawLine(p3, p4, c, np, dur)
	Lib.drawLine(p4, p1, c, np, dur)

	// top
	local p5 = {x = b.min.x, y = b.max.y, z = b.min.z}
	local p6 = {x = b.max.x, y = b.max.y, z = b.min.z}
	local p7 = {x = b.max.x, y = b.max.y, z = b.max.z}
	local p8 = {x = b.min.x, y = b.max.y, z = b.max.z}

	Lib.drawLine(p5, p6, c, np, dur)
	Lib.drawLine(p6, p7, c, np, dur)
	Lib.drawLine(p7, p8, c, np, dur)
	Lib.drawLine(p8, p5, c, np, dur)

	// sides
	Lib.drawLine(p1, p5, c, np, dur)
	Lib.drawLine(p2, p6, c, np, dur)
	Lib.drawLine(p3, p7, c, np, dur)
	Lib.drawLine(p4, p8, c, np, dur)
end

addHook("PostThinkFrame", do
	if not G_IsFLCRGametype() then return end
	FLCR.CameraBattleAngle = $+ANG1/6
	local totalPlayers = {} -- Self explainitory
	for p in players.iterate
		if not valid(p.mo) or p.spectator then continue end
		table.insert(totalPlayers, p.mo) -- Insert every valid player into the above table
	end

	if not #totalPlayers then
		return
	elseif FLCRDebug
	and (#totalPlayers == 1) then
		local t = P_SpawnMobj(0,0,0, MT_THOK)
		t.tics = 1
		t.color = P_RandomRange(1,#skincolors-1)
		--t.flags = MF2_DONTDRAW
		table.insert(totalPlayers, t)
	end

	local sh, pcheight = pcall(CV_FindVar, "fov")
	local sd, pcdist = pcall(CV_FindVar, "fov")
	local sf, pcfov = pcall(CV_FindVar, "fov")
	local cv = {
		height = sh and pcheight.value or 192*FRACUNIT,
		dist = sd and pcdist.value or 80*FRACUNIT,
		fov = sf and pcfov.value or 90*FRACUNIT
	}

	-- Get our center x, y, and z coordinates
	-- Average ONLY the minimum and maximum values. Not the whole totalPlayers table.
	local minx,maxx = INT32_MAX,INT32_MIN
	local miny,maxy = INT32_MAX,INT32_MIN
	local minz,maxz = INT32_MAX,INT32_MIN
	for _,v in ipairs(totalPlayers)
		minx,maxx = min($1,v.x),max($2,v.x)
		miny,maxy = min($1,v.y),max($2,v.y)
		minz = min($1,v.z + FixedMul(v.scale, (v.height/2 * P_MobjFlip(v))))
		maxz = max($1,v.z + FixedMul(v.scale, (v.height/2 * P_MobjFlip(v))))
	end

	-- Average the center
	local center = {
		x = (maxx+minx)/2,
		y = (maxy+miny)/2,
		z = (maxz+minz)/2
	}

	-- Get the closest player to the camera
	-- Thank you for helping me with this mental block, Lach!
	local l1, l2, l3 = 0,0,0
	if (#totalPlayers > 1)
		local maxcamdist = INT32_MAX
		for _,v in ipairs(totalPlayers)	
			local f = FixedAngle(cv.fov/2) -- Local FOV value in ANGLE value. Halved.
			local g = FLCR.CameraBattleAngle - R_PointToAngle2(v.x, v.y, center.x, center.y) -- Our Delta angle
			if (abs(g) > ANGLE_90) then continue end -- Ignore anything further with a greater Delta (Eg. further away)

			local camdist = R_PointToDist2(v.x, v.y, camera.x, camera.y) -- Player to camera distance
			if camdist > maxcamdist then continue end -- Last one is closer
			maxcamdist = camdist
			
			local dist = R_PointToDist2(v.x, v.y, center.x, center.y) -- Player to center distance
			local width = FixedMul(sin(g), dist) -- Delta angle sin value
			
			-- Our final l1, inner triangle towards our center
			-- Our final l2, outer triangle towards our camera
			l1, l2 = abs(FixedMul(cos(g), dist)), abs(FixedMul(tan(ANGLE_90 - f), width))
			-- Our final l3, add some z
			local z1, z2 = v.z, center.z
			l3 = R_PointToDist2(0, z1, (l1+l2), z2)
		end
	end

	-- Set these coordinates...
	local new = {
		x = center.x - FixedMul(cos(FLCR.CameraBattleAngle), l1+l2+l3) - FixedMul(cos(FLCR.CameraBattleAngle), cv.dist),
		y = center.y - FixedMul(sin(FLCR.CameraBattleAngle), l1+l2+l3) - FixedMul(sin(FLCR.CameraBattleAngle), cv.dist),
		z = center.z + l3 + cv.height
	}

	local factor = 10
	for p in players.iterate -- Since everybody has their own awayviewmobj...
		if not valid(p.awayviewmobj) then continue end
		local cam = p.awayviewmobj -- Not using the exposed camera_t because the exposed camera_t likes to angle itself to the consoleplayer.

		-- Ease towards destination
		P_MoveOrigin(cam, cam.x + (new.x - cam.x)/factor, 
					cam.y + (new.y - cam.y)/factor,
					cam.z + (new.z - cam.z)/factor)
		
		-- Face the center
		cam.angle = R_PointToAngle2(cam.x, cam.y, center.x, center.y)
		
		-- Aiming math towards the center
		local dist = R_PointToDist2(cam.x, cam.y, center.x, center.y)
		local hdist = R_PointToDist2(0, center.z, dist, cam.z) --(center.z - cam.z)
		-- Aim towards the center
		p.awayviewaiming = R_PointToAngle2(0, 0, dist, -hdist)/2 --+ p.aiming/10-- ANG2
	end

	-- Debug visual
	if FLCRDebug 
	and #totalPlayers > 1 then
		local b = {
			min = {
				x = minx,
				y = miny,
				z = minz
			},
			max = {
				x = maxx,
				y = maxy,
				z = maxz
			}
		}
		Lib.drawBounds(b, SKINCOLOR_WHITE, 32, 1)

		/*local extents = centermaxdist/2
		local be = {
			min = {
				x = minx - extents,
				y = miny - extents,
				z = minz - extents,
			},
			max = {
				x = maxx + extents,
				y = maxy + extents,
				z = maxz + extents,
			}
		}
		Lib.drawBounds(be, SKINCOLOR_RED, 32, 1)*/
	end
end)

-- Enable or disable the Vanilla HUD
addHook("HUD", CRHudToggle, "game")

-- For displaying all players behind walls
addHook("HUD", function(v,p,c)
	if not G_IsFLCRGametype() then return end
	if not valid(p) then return end
	if not valid(p.awayviewmobj) or p.spectator then return end
	local avm = p.awayviewmobj
	P_TeleportCameraMove(c, avm.x, avm.y, avm.z)
	c.angle = avm.angle
	c.aiming = p.awayviewaiming
	--if not valid(p.mo) then return end
	--if not valid(c) then return end
	for pl in players.iterate
		local mo = pl.mo
		if not valid(mo) then continue end
		if (FixedHypot(FixedHypot(avm.x - mo.x, avm.y - mo.y), 
									avm.z - mo.z) > 8*RING_DIST) then
			continue -- Out of range
		end
		if (mo.health <= 0)
		or (pl.playerstate == PST_DEAD) then continue end -- Dead
		if (mo.flags2 & MF2_DONTDRAW) then continue end -- Invisible
		if P_CheckSight(avm, mo) then continue end -- Awayviewmobj LOST signt of player

		R_ProjectSprite(v, mo, c)
	end
end, "game")

-- Player Number, Health Bar, Downed meter
-- Custom robo specific stuff
addHook("HUD", function(v,p,c)
	if not G_IsFLCRGametype() then return end
	if not valid(p) then return end
	if not valid(p.awayviewmobj) or p.spectator then return end

	if not (cv_crhudview.value) then -- HUD is set to "OFF"
		return -- Don't process anything else.
	elseif (string.lower(cv_crhudview.string) == "hud") -- HUD is set to "HUD"
		local patch = v.cachePatch("CRHUDHPG")
		local ref = { hudinfo[HUD_RINGS], hudinfo[HUD_RINGSNUM] }
		v.draw(ref[1].x, ref[1].y, patch, ref[1].f)
		v.drawNum(ref[2].x, ref[2].y, p.crplayerdata.health, ref[2].f)
		return -- Don't process anything else
	end

	local avm = p.awayviewmobj
	local range = 8*RING_DIST
	searchBlockmap("objects", function(refmo, found)
		if not found.player then return nil end
		if (found.player.playerstate == PST_DEAD) then return nil end
		if not found.player.crplayerdata then return nil end
		local CRPD = FLCR.PlayerData[found.player.crplayerdata.id]
		
		local camdistheight = FixedHypot(FixedHypot(c.x - found.x, c.y - found.y), c.z - found.z)/5
		local x,y,scale,oob = R_ScreenTransform(found.x, found.y, found.z + found.height/2 + camdistheight)
		if oob then return nil end -- Breakout. Don't process anything else.
		local flags = V_NOSCALESTART
		-- Visual debug for values
		/*if FLCRDebug then
			if (CRPD.player == consoleplayer) then
				local str1 = x>>FRACBITS ..", ".. x
				local str2 = y>>FRACBITS ..", ".. y
				local str3 = scale>>FRACBITS ..", ".. (scale)
				v.drawString(v.width()/2, 0, str1, flags, "center")
				v.drawString(v.width()/2, 8*v.dupy(), str2, flags, "center")
				v.drawString(v.width()/2, 16*v.dupy(), str3, flags, "center")
			end
		end*/
		
		--local color = v.getColormap(found.skin, found.color or SKINCOLOR_GREY)
		
		local dxint, dxfix = v.dupx() -- x scale
		local dyint, dyfix = v.dupy() -- y scale
		local xoffset = 50
		if (string.lower(cv_crhudview.string) == "minimal") then
			x = $ - (xoffset*dxfix)/2 -- Offset the x
			local npre = string.sub(CRPD.player.name, 1, 1) or "P" -- Get first character of player name
			-- Player Number
			v.drawString(x, y, npre .. CRPD.id, flags, "fixed")
			-- Health Number
			v.drawNum(x>>FRACBITS + xoffset*dxint, y>>FRACBITS - 3*dyint, CRPD.health, flags)
			-- Health Bar
			v.drawFill(x>>FRACBITS, y>>FRACBITS + 10*dyint, (xoffset*dxint), 2*dyint, 31|flags)
			v.drawFill(x>>FRACBITS, y>>FRACBITS + 10*dyint, (CRPD.health*(xoffset*dxint)/1000), 2*dyint, 15|flags)
			v.drawFill(x>>FRACBITS, y>>FRACBITS + 10*dyint, (CRPD.health*(xoffset*dxint)/1000), 1*dyint, 1|flags)
			-- Experimental "colored" Health bar
			/*local color = {
						skincolors[found.color].ramp[1],
						skincolors[found.color].ramp[7],
						skincolors[found.color].ramp[15]
						}
			v.drawFill(x>>FRACBITS, y>>FRACBITS + 10*dyint, (xoffset*dxint), 2*dyint, color[3]|flags)
			v.drawFill(x>>FRACBITS, y>>FRACBITS + 10*dyint, (CRPD.health*(xoffset*dxint)/1000), 2*dyint, color[2]|flags)
			v.drawFill(x>>FRACBITS, y>>FRACBITS + 10*dyint, (CRPD.health*(xoffset*dxint)/1000), 1*dyint, color[1]|flags)*/
			-- 'Downed meter' bits
			if (CRPD.curknockdown < 100) then
				local dmbitp = v.cachePatch("CRHUDDM")
				local pipCount = ease.linear(min(100, CRPD.curknockdown+1)*FRACUNIT/100,4*FRACUNIT,1*FRACUNIT)>>FRACBITS
				for i = 1, pipCount do
					--local inc = ((i-1) * 3*(dmbitp.width+2))
					v.draw(x>>FRACBITS + (xoffset - (dmbitp.width+2)*i)*dxint,
							y>>FRACBITS - 10*dyint,
							dmbitp,
							flags,
							v.getColormap(TC_DEFAULT, SKINCOLOR_WHITE))
				end
			end
			-- "Status" text to show what state the player is in
			if (CRPD.statetics > 2*TICRATE) then
				local fade = min(10, (CRPD.statetics-(2*TICRATE))/2)
				if (fade > 9) then return nil end -- Don't process anything else if visible for more than a second
				flags = $ | (fade*V_10TRANS) -- Some fancy fadeout
			end
			local statusstr, statusnum = Lib.getCRState(CRPD.player)
			flags = $ | strcol[statusnum]
			--local stateText = { "ACTION", "NORMAL", "HIT", "DOWN", "REBIRTH" }
			--statusstr = stateText[v.RandomKey(4)+1]
			--local statuswidth = v.stringWidth(statusstr, flags, "small")

			-- (x>>FRACBITS + (xoffset*dxint)/3)
			v.drawString(x>>FRACBITS + (xoffset*dxint)/3, -- TODO: FIX ALLIGNMENT?
						y>>FRACBITS + 13*dyint,
						statusstr,
						flags, "small-center")
		end
	end,
	avm, -- refmo
	avm.x-range,avm.x+range,
	avm.y-range,avm.y+range)
end, "game")

/*for i = 1, 100
	print(i ..", ".. ease.linear((1+i)*FRACUNIT/100,4*FRACUNIT,1*FRACUNIT)>>FRACBITS)
end*/

/*local range = 1024*FRACUNIT
searchBlockmap("objects", function(refmo, found)
end,
mo, -- refmo
mo.x-range,mo.x+range,
mo.y-range,mo.y+range)*/

addHook("NetVars", function(n)
	FLCR.CameraBattleAngle = n($)
end)