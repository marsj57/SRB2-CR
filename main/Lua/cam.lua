-- Hey, you're awfully nosy aren't you?
-- Just so you know, a lot of what you see here is mixed between original code
-- and code that I've gotten permission to use.
--
-- A word of warning: YOU SHOULD ASSUME __NONE__ OF THE CODE HERE IS REUSABLE.
-- GET PERMISSION TO USE THIS STUFF BEFORE YOU USE IT YOURSELF
--
-- Flame

-- The goal of this file is to be a standalone file.

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
		/*hudinfo[HUD_RINGS].y = 26 --hudinfo[HUD_TIME].y
		hudinfo[HUD_TIME].y = 10 --hudinfo[HUD_SCORE].y
		hudinfo[HUD_MINUTES].y = 10
		hudinfo[HUD_TIMECOLON].y = 10
		hudinfo[HUD_SECONDS].y = 10
		hudinfo[HUD_TIMETICCOLON].y = 10
		hudinfo[HUD_TICS].y = 10*/
		hud.disable("weaponrings")
		hud.disable("nightslink")
		hud.disable("nightsdrill")
		hud.disable("nightsrings")
		hud.disable("nightsscore")
		hud.disable("nightstime")
		hud.disable("nightsrecords")
		hud.disable("rankings")
		hud.disable("textspectator")
	else
		hud.enable("rings")
		hud.enable("lives")
		hud.enable("score")
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

rawset(_G, "R_ScreenTransform", function(x, y, z, v, p, cam)
	local ang, aim
	if cam.chase then -- obtain the differences
		z = $ - cam.z
		ang = cam.angle
		aim = cam.aiming
	else
		z = $ - p.viewz
		ang = p.mo.angle
		aim = p.aiming
	end
	local h = R_PointToDist(x, y)
	local da = ang - R_PointToAngle(x, y)
	local sizex = (v.width()/2)
	local sizey = (v.height()/2)

	return sizex<<FRACBITS + tan(da)*sizex,
	sizey<<FRACBITS + (tan(aim) - FixedDiv(z, 1 + FixedMul(cos(da), h)))*sizex,
	FixedDiv((sizex<<FRACBITS), h+1),
	(abs(da) > ANG60) or (abs(aim - R_PointToAngle2(0, 0, h, z)) > ANGLE_45)
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

/*addHook("PlayerThink", function(p)
	if G_IsFLCRGametype()
	and (p.playerstate == PST_DEAD)
	and valid(p.awayviewmobj) and not p.awayviewtics then
		P_RemoveMobj(p.awayviewmobj)
	end
end)*/

addHook("PostThinkFrame", do
	if not G_IsFLCRGametype() then return end
	FLCR.CameraBattleAngle = $+ANG1/6
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
	local minz,maxz = 0,0
	for k,v in spairs(totalPlayers, function(t,a,b) return t[b].z > t[a].z end)
		if valid(v) then
			center.x = $+(v.x/#totalPlayers) -- Our center x
			center.y = $+(v.y/#totalPlayers) -- Our center y
			
			-- Instead of grabbing the "Average" Lets grab the player
			-- With the highest z coord, and lowest z coord, and average that
			if k == 1 then maxz = v.z + FixedMul(v.scale, (v.height/2 * P_MobjFlip(v))) end
			if k == #totalPlayers then minz = v.z + FixedMul(v.scale, (v.height/2 * P_MobjFlip(v))) end
			center.z = (maxz+minz)/2
			--center.z = $+(v.z/#totalPlayers)+(FixedMul(v.scale, (mobjinfo[v.type].height * P_MobjFlip(v)))/#totalPlayers) -- Our center z
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

	-- And move!
	local factor = 10
	local zoomMax = 3*RING_DIST
	local zoomPercent = (furthest.d[2] >= zoomMax) and FRACUNIT or FixedDiv(furthest.d[2] + furthest.z[2]*3, zoomMax)
	local zoom = ease.linear(zoomPercent, 10, 100)<<FRACBITS
	for p in players.iterate -- Since everybody has their own awayviewmobj...
		if not valid(p.awayviewmobj) then continue end
		local cam = p.awayviewmobj -- Not using the exposed camera_t because the exposed camera_t likes to angle itself to the consoleplayer.

		-- Ease towards destination
		P_MoveOrigin(cam,
					cam.x + (new.x - cam.x)/factor - FixedMul(cos(FLCR.CameraBattleAngle), zoom),
					cam.y + (new.y - cam.y)/factor - FixedMul(sin(FLCR.CameraBattleAngle), zoom),
					cam.z + (new.z - cam.z)/factor + zoom)
		
		-- Face the center
		cam.angle = R_PointToAngle2(cam.x, cam.y, center.x, center.y)
		
		-- Aiming math towards the center
		local dist = R_PointToDist2(cam.x, cam.y, center.x, center.y)
		local hdist = (cam.z - center.z) --R_PointToDist2(0, cam.z, dist, center.z) --(cam.z - center.z)
		-- Aim towards the center
		p.awayviewaiming = R_PointToAngle2(0, 0, dist, -hdist) --+ p.aiming/10-- ANG2
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
	for p in players.iterate
		local mo = p.mo
		if not valid(mo) then continue end
		if (FixedHypot(FixedHypot(avm.x - mo.x, avm.y - mo.y), 
									avm.z - mo.z) > 8*RING_DIST) then
			continue -- Out of range
		end
		if (mo.health <= 0)
		or (p.playerstate == PST_DEAD) then continue end
		if (mo.flags2 & MF2_DONTDRAW) then continue end
		if P_CheckSight(avm, mo) then continue end

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
		
		local camdistheight = FixedHypot(FixedHypot(c.x - p.mo.x, c.y - p.mo.y), c.z - p.mo.z)/5
		local x,y,scale = R_ScreenTransform(found.x, found.y, found.z + found.height/2 + camdistheight, v, p, c)
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
			-- Player Number
			v.drawString(x, y, "P" .. CRPD.id, flags, "fixed")
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