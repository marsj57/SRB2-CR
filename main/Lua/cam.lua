-- Hey, you're awfully nosy aren't you?
-- Just so you know, a lot of what you see here is mixed between original code
-- and code that I've gotten permission to use.
--
-- A word of warning: YOU SHOULD ASSUME __NONE__ OF THE CODE HERE IS REUSABLE.
-- GET PERMISSION TO USE THIS STUFF BEFORE YOU USE IT YOURSELF
--
-- Flame

-- Lactozilla
local MINZ = (FRACUNIT*4)
local FEETADJUST = -(15<<FRACBITS)
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
	local fov = FixedAngle(CV_FindVar("fov").value/2)
	local fovtan = tan(fov)
	if (splitscreen) then -- Splitscreen FOV should be adjusted to maintain expected vertical view
		fovtan = 17*fovtan/10
	end

	local centerx = (v.width() / 2)
	local centery = (v.height() / 2)

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
		centery = $ + (AIMINGTODY(angle) * invmul * (v.width() / 320))
	end

	local centerxfrac = centerx<<FRACBITS
	local centeryfrac = centery<<FRACBITS
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

	if thing.player
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

	--[[v.drawString(0, stats_y, "x1: "+ x1)
	v.drawString(0, stats_y+10, "x2: "+ x2)
	v.drawString(0, stats_y+20, "sprtopscreen: "+ FixedInt(sprtopscreen))
	v.drawString(0, stats_y+30, "sprbotscreen: "+ FixedInt(sprbotscreen))]]

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

addHook("MapLoad", function(mapnum)
	FLCR.CameraBattleAngle = 0
end)

addHook("PlayerSpawn", function(p)
	if not valid(p) then return false end
	if not valid(p.mo) then return false end
	local mo = p.mo
	
	-- Camera mobj. Not using camera_t.
	if not p.awayviewmobj and (gametype == GT_MATCH) then
		local o = P_SpawnMobj(mo.x, mo.y, mo.z, MT_DUMMY)
		o.state = S_THOK
		o.angle = mo.angle
		o.flags2 = $ | MF2_DONTDRAW
		o.tics = -1
		o.target = mo
		o.health = -1
		p.awayviewmobj = o
		p.awayviewtics = 2
	end
	
	p.pflags = $ | PF_ANALOGMODE
	--CV_Set(CV_FindVar("chasecam"), 1)
	camera.chase = true
	p.rings = 50
end, MT_PLAYER)

addHook("ThinkFrame", do
	-- Camera mobj thinker. Referenced by p.awayviewmobj
	for p in players.iterate
		if not valid(p.mo) or p.spectator then continue end
		local mo = p.mo
		if not valid(p.awayviewmobj) then continue end
		p.awayviewtics = 2
	end
end)

addHook("PostThinkFrame", do
	if (gametype ~= GT_MATCH) then return end
	FLCR.CameraBattleAngle = $+ANG1/2
	local totalPlayers = {} -- Self explainitory
	for p in players.iterate
		if not valid(p.mo) or p.spectator then continue end
		table.insert(totalPlayers, p.mo) -- Insert every player's mo into the above table
	end
	
	if not #totalPlayers then return end
	
	local cv = {
				height = CV_FindVar("cam_height").value,
				dist = CV_FindVar("cam_dist").value
				}
	
	-- Get our center x, y, and z coordinates
	local center = {
						x = 0,
						y = 0,
						z = 0
					}
	for _,v in ipairs(totalPlayers)
		if valid(v) then
			center.x = $+(v.x/#totalPlayers) -- Our center x
			center.y = $+(v.y/#totalPlayers) -- Our center y
			center.z = $+(v.z/#totalPlayers)+(FixedMul(v.scale, (mobjinfo[v.type].height * P_MobjFlip(v)))/#totalPlayers) -- Our center z
		end
	end
	
	-- Get the furthest player from the center
	local temp = 0 -- Temp value
	local furthest = {
						--x = {nil, 0},
						--y = {nil, 0},
						z = {nil, 0},
						d = {nil, 0}
					}
	for _,v in ipairs(totalPlayers)
		temp = R_PointToDist2(v.x, v.y, center.x, center.y)
		if (temp > furthest.d[2]) then
			furthest.d = {v, temp}
		end
		/*temp = abs(v.x - center.x)
		if (temp > furthest.x[2]) then
			furthest.x = {v, temp}
		end
		
		temp = abs(v.y - center.y)
		if (temp > furthest.y[2]) then
			furthest.y = {v, temp}
		end*/
		
		temp = abs(v.z + FixedMul(v.scale, (mobjinfo[v.type].height * P_MobjFlip(v))) - center.z)
		if (temp > furthest.z[2]) then
			furthest.z = {v, temp}
		end
	end

	-- Set these coordinates...
	local new = {
				x = center.x - FixedMul(cos(FLCR.CameraBattleAngle), furthest.d[2]) - FixedMul(cos(FLCR.CameraBattleAngle), cv.dist),
				y = center.y - FixedMul(sin(FLCR.CameraBattleAngle), furthest.d[2]) - FixedMul(sin(FLCR.CameraBattleAngle), cv.dist),
				z = center.z + cv.height --+ furthest.d[2]/3
			}

	/*if (#totalPlayers > 1) and (players[0].cmd.buttons & BT_CUSTOM1) then 
		print(string.format("FurthestZ Name: %3s | FurthestZ Dist: %3s", furthest.d[1].player.name or "nil", furthest.d[2]>>FRACBITS))
	end
	
	local debug = { 
				center = P_SpawnMobj(center.x, center.y, center.z, MT_THOK),
				centeroffs = P_SpawnMobj(new.x, new.y, new.z, MT_THOK)
				}
	debug.center.color = SKINCOLOR_RED
	debug.center.tics = 1
	debug.centeroffs.color = SKINCOLOR_BLUE
	debug.centeroffs.destscale = FRACUNIT/16*/

	-- And move!
	local factor = 8
	local zoomMax = 3*RING_DIST
	local zoomPercent = (furthest.d[2] >= zoomMax) and FRACUNIT or FixedDiv(furthest.d[2] + furthest.z[2]*3, zoomMax)
	local zoom = ease.linear(zoomPercent, 10, 100)<<FRACBITS
	for p in players.iterate -- Since everybody has their own awayviewmobj...
		if not valid(p.awayviewmobj) then continue end
		local cam = p.awayviewmobj -- Not using the exposed camera_t because the exposed camera_t likes to angle itself to the consoleplayer.

		-- Ease towards destination
		P_TeleportMove(cam,
						cam.x + (new.x - cam.x)/factor - FixedMul(cos(FLCR.CameraBattleAngle), zoom),
						cam.y + (new.y - cam.y)/factor - FixedMul(sin(FLCR.CameraBattleAngle), zoom),
						cam.z + (new.z - cam.z)/factor + zoom)
		
		-- Face the center
		cam.angle = R_PointToAngle2(cam.x, cam.y, center.x, center.y)
		
		-- Aiming math towards the center
		local dist = R_PointToDist2(cam.x, cam.y, center.x, center.y)
		local hdist = (cam.z - center.z) --R_PointToDist2(0, cam.z, dist, center.z) --(cam.z - center.z)
		-- Aim towards the center
		p.awayviewaiming = R_PointToAngle2(0, 0, dist, -hdist) - ANG2
		
		-- Actual camera teleporting. Not used except to reference in our hud function.
		P_TeleportCameraMove(camera,cam.x,cam.y,cam.z)
		camera.angle = cam.angle
		camera.aiming = p.awayviewaiming
	end
end)

hud.add(function(v,p,c)
	--if not valid(v) then return end
	if not valid(p) then return end
	if not p.awayviewmobj or p.spectator then return end
	--if not valid(p.mo) then return end
	--if not valid(c) then return end
	for m in mobjs.iterate()
		if not valid(m) then continue end
		if (m.health <= 0)
		or (m.player and (m.player.playerstate == PST_DEAD)) then continue end
		if (m.flags2 & MF2_DONTDRAW) -- Base player, or object mobj
		or (m.tracer and m.tracer.player and (m.tracer.flags2 & MF2_DONTDRAW)) then continue end -- Followmobj
		if P_CheckSight(p.awayviewmobj, m) then continue end
		R_ProjectSprite(v, m, c)
	end
end, "game")

addHook("NetVars", function(n)
	FLCR.CameraBattleAngle = n($)
end)