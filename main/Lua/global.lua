-- Hey, you're awfully nosy aren't you?
-- Just so you know, a lot of what you see here is mixed between original code
-- and code that I've gotten permission to use.
--
-- A word of warning: YOU SHOULD ASSUME __NONE__ OF THE CODE HERE IS REUSABLE.
-- GET PERMISSION TO USE THIS STUFF BEFORE YOU USE IT YOURSELF
--
-- Flame

rawset(_G, "ABSOLUTE_ANGLE", 0)

rawset(_G, "valid", function(v)
	return v and v.valid
end)

-- Lach
-- Freeslots something without making duplicates
local function CheckSlot(item) -- this function deliberately errors when a freeslot does not exist
	if _G[item] == nil -- this will error by itself for states and objects
		error() -- this forces an error for sprites, which do actually return nil for some reason
	end
end

rawset(_G, "SafeFreeslot", function(...)
	for _, item in ipairs({...})
		if pcall(CheckSlot, item)
			print("\131NOTICE:\128 " .. item .. " was not allocated, as it already exists.")
		else
			freeslot(item)
		end
	end
end)
-- End Lach

-- Copied from source
rawset(_G, "drainAmmo", function(p, power)
	if not valid(p) then return end
	p.powers[power] = $ - 1

	if (p.rings < 1)
		p.ammoremovalweapon = p.currentweapon
		p.ammoremovaltimer = ammoremovaltics -- 2*TICRATE
		
		if (p.powers[power] > 0)
			p.powers[power] = $ - 1
			p.ammoremoval = 2
		else
			p.ammoremoval = 1
		end
	else
		p.rings = $ - 1
	end
end)

-- Copied from source
rawset(_G, "setWeaponDelay", function(p, delay)
	if not valid(p) then return end
	p.weapondelay = delay
	if p.skin == 2 then -- knuckles
		p.weapondelay = $ * 2
		p.weapondelay = $ / 3
	end
end)

-- Copied from source
rawset(_G, "doFireRing", function(p, cmd)
	local mo
	if not valid(p) then return end
	
	if not (cmd.buttons & (BT_ATTACK|BT_FIRENORMAL)) then
		p.pflags = $ & ~PF_ATTACKDOWN
		return
	end
	
	if (p.pflags & PF_ATTACKDOWN) or p.climbing or (G_TagGametype() and not (p.pflags & PF_TAGIT)) then return end
	if not G_RingSlingerGametype() or p.weapondelay > 1 then return end
	
	p.pflags = $ | PF_ATTACKDOWN
	
	-- Ring
	if (p.rings <= 0) then return end
	setWeaponDelay(p, TICRATE/4)
	mo = P_SpawnPlayerMissile(p.mo, MT_REDRING, 0)
	if valid (mo) then P_ColorTeamMissile(mo, p) end
	p.rings = $ - 1
end)

/*-- Tatsuru
local function FixedPow(a, b)
	local res = FRACUNIT

	for i = 1, b do
		res = FixedMul(res, a)
	end

	return res
end
-- End Tatsuru

rawset(_G, "atan", function(x)
	return asin(FixedDiv(x, FixedSqrt(FRACUNIT + FixedPow(x, 2))))
end*/

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
		local super = thing.player and (thing.player.powers[pw_super] > 0)
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