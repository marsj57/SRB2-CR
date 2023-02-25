-- Hey, you're awfully nosy aren't you?
-- Just so you know, a lot of what you see here is mixed between original code
-- and code that I've gotten permission to use.
--
-- A word of warning: YOU SHOULD ASSUME __NONE__ OF THE CODE HERE IS REUSABLE.
-- GET PERMISSION TO USE THIS STUFF BEFORE YOU USE IT YOURSELF
--
-- Flame

local Lib = FLCRLib

-- Guns
FLCR.AddWeapon({
	name = "Basic",
	desc = "A training gun that fires 3 rounds straight ahead. It's for absolute beginners. The rounds are weaker at greater distances.",
	mt = MT_DUMMYMISSILE,
	spawnsound = sfx_basic,
	parttype = CRPT_GUN,
	spawnfunc = function(p, w)
		if not valid(p) then return end
		if not p.crplayerdata then return end
		local CRPD = FLCR.PlayerData[p.crplayerdata.id]
		if not valid(CRPD.player) then return end
		if not valid(p.mo) then return end
		local mo = p.mo

		local multifireinterval = TICRATE/4 -- Multishot interval
		local maxrounds = 3 -- How many rounds can your weapon fire per-clip?
		if (CRPD.firetics%multifireinterval) -- Modulo by your weapon's firedelay, a non zero number?
		or (CRPD.firemaxrounds >= maxrounds)
			return
		elseif not CRPD.firetics then
			CRPD.firetype = w.parttype
			CRPD.firetics = (multifireinterval * maxrounds)*2 -- 26.5
			p.powers[pw_nocontrol] = CRPD.firetics - 3*(w.reload) -- -12 = 14.5
		end

		-- Let's spawn the bullet!
		local xyangle = mo.target and R_PointToAngle2(mo.x, mo.y, mo.target.x, mo.target.y) or p.drawangle
		local zangle = p.aiming
		local th = Lib.spawnCRMissile(mo, w, xyangle, zangle)
		if valid(th) then
			th.thinkfunc = w.thinkfunc
			th.damage = w.attack * 8 -- 32
			th.knockdown = 24 -- Getting hit with all 3 shots applies 74 knockdown
			th.state = S_RRNG1
			th.color = SKINCOLOR_YELLOW
			th.fuse = 3*TICRATE
		end
		CRPD.firemaxrounds = $ + 1
	end,
	
	thinkfunc = function(mo)
		if not valid(mo) then return end
		if (mo.state == mo.info.deathstate) then return end
		-- Interpolate fx graphics towards prev position
		if mo.prev then
			for i = 1, 5 do
				local x = ease.linear(i*FRACUNIT/5, mo.prev.x, mo.x)
				local y = ease.linear(i*FRACUNIT/5, mo.prev.y, mo.y)
				local z = ease.linear(i*FRACUNIT/5, mo.prev.z, mo.z)
				
				local fx = P_SpawnMobj(x,y,z-(mobjinfo[mo.type].height/3),MT_DUMMYFX)
				fx.state = S_THOK
				fx.scale = mo.scale
				fx.destscale = 1
				fx.scalespeed = FRACUNIT/5
				fx.color = mo.color
				fx.blendmode = AST_ADD
			end
		end
		
		local factor = 64
		mo.momx = $ - $/factor
		mo.momy = $ - $/factor
		mo.momz = $ - $/factor
		if mo.tracer then
			local t = mo.tracer
			local angle = R_PointToAngle2(mo.x, mo.y, t.x, t.y)
			P_Thrust(mo, angle, FRACUNIT/factor)
		end
		
		mo.prev = {
			x = mo.x,
			y = mo.y,
			z = mo.z,
		}
	end,

	attack = 4,
	speed = 5,
	homing = 2,
	reload = 4,
	down = 6,
})

FLCR.AddWeapon({
	name = "3way", 
	desc = "Fires 3 straight rounds in 3 rows. The farther you are from the enemy, the better its homing.",
	spawnsound = sfx_3way,
	parttype = CRPT_GUN,
	spawnfunc = function(p, w)
		if not valid(p) then return end
		if not p.crplayerdata then return end
		local CRPD = FLCR.PlayerData[p.crplayerdata.id]
		if not valid(CRPD.player) then return end
		if not valid(p.mo) then return end
		local mo = p.mo

		local multifireinterval = TICRATE/7 -- Multishot interval
		local maxrounds = 3 -- How many rounds can your weapon fire per-clip?
		if (CRPD.firetics%multifireinterval) -- Modulo by your weapon's firedelay, a non zero number?
		or (CRPD.firemaxrounds >= maxrounds)
			return
		elseif not CRPD.firetics then
			CRPD.firetype = w.parttype
			CRPD.firetics = (multifireinterval * maxrounds)*3
			p.powers[pw_nocontrol] = CRPD.firetics - 2*(w.reload)
		end
		
		-- Let's spawn the bullets!
		for i = -1, 1, 1 do
			local xyangle = mo.target and R_PointToAngle2(mo.x, mo.y, mo.target.x, mo.target.y) or p.drawangle
			local zangle = p.aiming
			local offset = i*(70*FRACUNIT) -- XY offset
			-- Spawn the reference x,y,z object.
			local ref = P_SpawnMobjFromMobj(mo, FixedMul(cos(xyangle), FixedMul(cos(zangle), 4*mo.radius/2)) 
												+ FixedMul(cos(xyangle+ANGLE_90), offset)
												- FixedMul(cos(xyangle), FixedMul(cos(zangle), i*offset/2)),
												FixedMul(sin(xyangle), FixedMul(cos(zangle), 4*mo.radius/2)) 
												+ FixedMul(sin(xyangle+ANGLE_90), offset)
												- FixedMul(sin(xyangle), FixedMul(cos(zangle), i*offset/2)),
												FixedMul(sin(zangle), mo.height)
												- FixedMul(sin(zangle), abs(i)*(mo.height/2)),
												MT_DUMMY)
			-- Spawn the missile from the reference object
			local th = Lib.spawnCRMissile(ref, w, xyangle, zangle, MF_NOCLIPTHING)
			P_RemoveMobj(ref) -- We're done with our reference object here
			S_StartSoundAtVolume(mo, w.spawnsound, 192) -- Because our ref object disappears
			if valid(th) then
				th.target = mo
				th.extravalue1 = i
				th.thinkfunc = w.thinkfunc
				th.damage = w.attack * 8 -- 32
				th.knockdown = 24 -- Getting hit with all 3 shots applies 74 knockdown
				th.state = S_RRNG1
				th.color = SKINCOLOR_YELLOW
				th.fuse = 3*TICRATE
			end
		end
		CRPD.firemaxrounds = $ + 1
	end,
	
	thinkfunc = function(mo)
		if not valid(mo) then return end
		if (mo.state == mo.info.deathstate) then return end
		-- Interpolate fx graphics towards prev position
		if mo.prev then
			for i = 1, 5 do
				local x = ease.linear(i*FRACUNIT/5, mo.prev.x, mo.x)
				local y = ease.linear(i*FRACUNIT/5, mo.prev.y, mo.y)
				local z = ease.linear(i*FRACUNIT/5, mo.prev.z, mo.z)
				
				local fx = P_SpawnMobj(x,y,z-(mobjinfo[mo.type].height/3),MT_DUMMYFX)
				fx.state = S_THOK
				fx.scale = mo.scale
				fx.destscale = 1
				fx.scalespeed = FRACUNIT/5
				fx.color = mo.color
				fx.blendmode = AST_ADD
			end
		end
		mo.prev = {
			x = mo.x,
			y = mo.y,
			z = mo.z,
			scale = mo.scale,
		}
		
		-- Middle bullet has a little bit of homing
		local factor = 50
		mo.momx = $ - $/factor
		mo.momy = $ - $/factor
		mo.momz = $ - $/factor
		if mo.tracer
		and not mo.extravalue1 then
			local t = mo.tracer
			local angle = R_PointToAngle2(mo.x, mo.y, t.x, t.y)
			P_Thrust(mo, angle, FRACUNIT/factor)
		end
	end,
	
	attack = 5,
	speed = 5,
	homing = 4,
	reload = 5,
	down = 6,
})

FLCR.AddWeapon({
	name = "Gatling", 
	desc = "Fires multiple small rounds straight ahead. Stay close to the enemy for better shots.",
	mt = MT_DUMMYMISSILE,
	spawnsound = sfx_gtlng,
	parttype = CRPT_GUN,
	spawnfunc = function(p, w)
		if not valid(p) then return end
		if not p.crplayerdata then return end
		local CRPD = FLCR.PlayerData[p.crplayerdata.id]
		if not valid(CRPD.player) then return end
		if not valid(p.mo) then return end
		local mo = p.mo

		local multifireinterval = TICRATE/9 -- Multishot interval
		local maxrounds = 8 -- How many rounds can your weapon fire per-clip?
		if (CRPD.firetics%multifireinterval) -- Modulo by your weapon's firedelay, a non zero number?
		or (CRPD.firemaxrounds >= maxrounds)
			return
		elseif not CRPD.firetics then
			CRPD.firetype = w.parttype
			CRPD.firetics = (multifireinterval * maxrounds)*2 -- 54
			p.powers[pw_nocontrol] = CRPD.firetics - 6*(w.reload)
		end
		
		-- Let's spawn the bullet!
		local xyangle = mo.target and R_PointToAngle2(mo.x, mo.y, mo.target.x, mo.target.y) or p.drawangle
		local zangle = p.aiming
		local th = Lib.spawnCRMissile(mo, w, xyangle, zangle)
		if valid(th) then
			th.thinkfunc = w.thinkfunc
			th.damage = w.attack * 3 -- 12, getting hit with all 8 shots is 96 damage
			th.knockdown = 9 -- Getting hit with all 8 shots applies 72 knockdown
			th.state = S_RRNG1
			th.color = SKINCOLOR_YELLOW
			th.fuse = 3*TICRATE
		end
		CRPD.firemaxrounds = $ + 1
	end,

	thinkfunc = function(mo)
		if not valid(mo) then return end
		if (mo.state == mo.info.deathstate) then return end		
		-- Interpolate fx graphics towards prev position
		if mo.prev then
			for i = 1, 5 do
				local x = ease.linear(i*FRACUNIT/5, mo.prev.x, mo.x)
				local y = ease.linear(i*FRACUNIT/5, mo.prev.y, mo.y)
				local z = ease.linear(i*FRACUNIT/5, mo.prev.z, mo.z)
				
				local fx = P_SpawnMobj(x,y,z-(mobjinfo[mo.type].height/3),MT_DUMMYFX)
				fx.state = S_THOK
				fx.scale = mo.scale
				fx.destscale = 1
				fx.scalespeed = FRACUNIT/5
				fx.color = mo.color
				fx.blendmode = AST_ADD
			end
		end
		
		local factor = 64
		mo.momx = $ - $/factor
		mo.momy = $ - $/factor
		mo.momz = $ - $/factor
		if mo.tracer then
			local t = mo.tracer
			local angle = R_PointToAngle2(mo.x, mo.y, t.x, t.y)
			P_Thrust(mo, angle, FRACUNIT/factor)
		end
		
		mo.prev = {
			x = mo.x,
			y = mo.y,
			z = mo.z,
			scale = mo.scale,
		}
	end,

	attack = 4,
	speed = 7,
	homing = 2,
	reload = 3,
	down = 6,
})

FLCR.AddWeapon({
	name = "Vertical", 
	desc = "Fires 2 rounds. One ascends diagonally, clearing walls. Use this as you hide behind walls.",
	spawnsound = sfx_vrtcl,
	parttype = CRPT_GUN,
	spawnfunc = function(p, w)
		if not valid(p) then return end
		if not p.crplayerdata then return end
		local CRPD = FLCR.PlayerData[p.crplayerdata.id]
		if not valid(CRPD.player) then return end
		if not valid(p.mo) then return end
		local mo = p.mo
		
		local multifireinterval = TICRATE/4 -- Multishot interval
		local maxrounds = 2 -- How many rounds can your weapon fire per-clip?
		if (CRPD.firetics%multifireinterval) -- Modulo by your weapon's firedelay, a non zero number?
		or (CRPD.firemaxrounds >= maxrounds)
			return
		elseif not CRPD.firetics then
			CRPD.firetype = w.parttype
			CRPD.firetics = (multifireinterval * maxrounds)*2 -- 54
			p.powers[pw_nocontrol] = CRPD.firetics - 6*(w.reload)
		end
		
		CRPD.firemaxrounds = $ + 1
	end,
	
	thinkfunc = function(mo)
		if not valid(mo) then return end
		if (mo.state == mo.info.deathstate) then return end
		-- Interpolate fx graphics towards prev position
		if mo.prev then
			for i = 1, 5 do
				local x = ease.linear(i*FRACUNIT/5, mo.prev.x, mo.x)
				local y = ease.linear(i*FRACUNIT/5, mo.prev.y, mo.y)
				local z = ease.linear(i*FRACUNIT/5, mo.prev.z, mo.z)
				
				local fx = P_SpawnMobj(x,y,z-(mobjinfo[mo.type].height/3),MT_DUMMYFX)
				fx.state = S_THOK
				fx.scale = mo.scale
				fx.destscale = 1
				fx.scalespeed = FRACUNIT/5
				fx.color = mo.color
				fx.blendmode = AST_ADD
			end
		end
		
		mo.prev = {
			x = mo.x,
			y = mo.y,
			z = mo.z,
			scale = mo.scale,
		}
	end,
	attack = 4,
	speed = 5,
	homing = 3,
	reload = 5,
	down = 7,
})

FLCR.AddWeapon({
	name = "Sniper",
	desc = "Fires one quick, straight round. While the round flies fast, it leaves you in danger for a time.",
	spawnsound = sfx_snip,
	parttype = CRPT_GUN,
	spawnfunc = function(p, w)
		if not valid(p) then return end
		if not p.crplayerdata then return end
		local CRPD = FLCR.PlayerData[p.crplayerdata.id]
		if not valid(CRPD.player) then return end
		if not valid(p.mo) then return end
		local mo = p.mo
		
		if CRPD.firetics then return end
		CRPD.firetype = w.parttype
		CRPD.firetics = 4*TICRATE/3
		p.powers[pw_nocontrol] = CRPD.firetics - w.reload
		
		-- Let's spawn the bullet!
		local xyangle = mo.target and R_PointToAngle2(mo.x, mo.y, mo.target.x, mo.target.y) or p.drawangle
		local zangle = p.aiming
		local th = Lib.spawnCRMissile(mo, w, xyangle, zangle)
		if valid(th) then
			th.thinkfunc = w.thinkfunc
			th.damage = 120
			th.knockdown = th.damage/2
			th.state = S_RRNG1
			th.color = SKINCOLOR_WHITE
			th.fuse = 3*TICRATE
		end
		CRPD.firemaxrounds = $ + 1
	end,
	
	thinkfunc = function(mo)
		if not valid(mo) then return end
		if (mo.state == mo.info.deathstate) then return end
		if mo.prev then
			-- Interpolate fx graphics towards prev position
			for i = 1, 5 do
				local x = ease.linear(i*FRACUNIT/5, mo.prev.x, mo.x)
				local y = ease.linear(i*FRACUNIT/5, mo.prev.y, mo.y)
				local z = ease.linear(i*FRACUNIT/5, mo.prev.z, mo.z)
				
				local fx = P_SpawnMobj(x,y,z-(mobjinfo[mo.type].height/3),MT_DUMMYFX)
				fx.state = S_THOK
				fx.tics = 28
				fx.scale = mo.scale
				fx.destscale = 1
				fx.scalespeed = FRACUNIT/10
				fx.color = mo.color
				fx.blendmode = AST_ADD
			end
		end
		
		if (mo.fuse > (3*TICRATE)-3) then
			local inc = 3*TICRATE - mo.fuse
			local fx2 = P_SpawnMobjFromMobj(mo, 0,0,0, MT_DUMMYFX)
			fx2.state = S_FX_WIND
			fx2.angle = mo.angle - ANGLE_90
			if mo.momz then
				P_CreateFloorSpriteSlope(fx2)
				fx2.flags2 = $ | MF2_SPLAT
				fx2.renderflags = $ | RF_FLOORSPRITE | RF_SLOPESPLAT | RF_NOSPLATBILLBOARD
				fx2.floorspriteslope.o = { x = mo.x, y = mo.y, z = mo.z }
				fx2.floorspriteslope.xydirection = mo.angle
				fx2.floorspriteslope.zangle = FixedAngle(mo.momz/2) + ANGLE_90
				fx2.spritexscale = FixedMul(sin(abs(FixedAngle(mo.momz/2))), FRACUNIT)
			end
		end
		
		mo.prev = {
			x = mo.x,
			y = mo.y,
			z = mo.z,
			scale = mo.scale,
		}
	end,
	attack = 7,
	speed = 9,
	homing = 1, -- Literally no homing LMAO
	reload = 2,
	down = 7,
})

FLCR.AddWeapon({
	name = "Stun", 
	desc = "Fires continuous short-ranged electric shots that paralyze foes. Use at close range.",
	spawnsound = 0,
	parttype = CRPT_GUN,
	attack = 2,
	speed = 7,
	homing = 3,
	reload = 9,
	down = 7,
})

FLCR.AddWeapon({
	name = "Hornet", 
	desc = "Spreads five bee-shaped rounds that chase its target.",
	spawnsound = 0,
	parttype = CRPT_GUN,
	attack = 6,
	speed = 3,
	homing = 6,
	reload = 3,
	down = 6,
})

FLCR.AddWeapon({
	name = "Flame", 
	desc = "Fires flame-shaped rounds straight ahead. Its power increases with distance.",
	spawnsound = 0,
	parttype = CRPT_GUN,
	attack = 5,
	speed = 4,
	homing = 3,
	reload = 5,
	down = 7,
})

FLCR.AddWeapon({
	name = "Dragon", 
	desc = "Fires one dragon-shaped round that zeroes in on foes. Stay on your guard after firing.",
	spawnsound = 0,
	parttype = CRPT_GUN,
	attack = 7,
	speed = 4,
	homing = 7,
	reload = 3,
	down = 8,
})

FLCR.AddWeapon({
	name = "splash", 
	desc = "Fires 3 large yet weak rounds straight ahead. Briefly immobolizes foes.",
	spawnsound = 0,
	parttype = CRPT_GUN,
	attack = 1,
	speed = 4,
	homing = 3,
	reload = 10,
	down = 2,
})

-- Bombs
FLCR.AddWeapon({
	name = "standard", 
	desc = "Flies in an arc toward target. It's large blast radius makes aiming and multiple blows a snap.",
	spawnsound = sfx_s3k81,
	parttype = CRPT_BOMB,
	attack = 7,
	speed = 5,
	size = 5,
	time = 5,
	down = 6,
})

FLCR.AddWeapon({
	name = "standard f", 
	desc = "Flies in an arc toward target. Knocks target sideways on impact, flushing out hidden foes.",
	spawnsound = sfx_s3k81,
	parttype = CRPT_BOMB,
	special = CRL_F,
	attack = 6,
	speed = 5,
	size = 3,
	time = 5,
	down = 6,
})

FLCR.AddWeapon({
	name = "standard s", 
	desc = "Flies in an arc toward target. Immobilizes target upon impact for a short time.",
	spawnsound = sfx_s3k81,
	parttype = CRPT_BOMB,
	special = CRL_S,
	attack = 4,
	speed = 5,
	size = 4,
	time = 4,
	down = 3,
})

FLCR.AddWeapon({
	name = "standard k", 
	desc = "Flies in an arc toward target. Knocks target down on impact.",
	spawnsound = sfx_s3k81,
	parttype = CRPT_BOMB,
	special = CRL_K,
	attack = 6,
	speed = 5,
	size = 5,
	time = 5,
	down = 10,
})

FLCR.AddWeapon({
	name = "standard x", 
	desc = "Flies in an arc toward target. Explosion sends target high into the air.",
	spawnsound = sfx_s3k81,
	parttype = CRPT_BOMB,
	special = CRL_X,
	attack = 4,
	speed = 5,
	size = 4,
	time = 5,
	down = 5,
})

local crbombnames = {
	"freeze",
	"wave",
	"titan"
}
for _, bn in ipairs(crbombnames)
	FLCR.AddWeapon({ name = bn,
						parttype = CRPT_BOMB 
						})
end

-- Pods
FLCR.AddWeapon({
	name = "standard", 
	desc = "Flies straight ahead. Blows target diagonally upward.",
	spawnsound = sfx_s3k82,
	parttype = CRPT_POD,
	special = CRL_INVALID,
	attack = 4,
	speed = 5,
	homing = 4,
	size = 5,
	time = 5,
})

local crpodnames = {
	"seeker",
	"spider",
	"spider g",
	"freeze",
	"jumping b",
	"jumping g",
	"twin flank",
	"titan"
}
for _, pn in ipairs(crpodnames)
	FLCR.AddWeapon({ name = pn, 
						parttype = CRPT_POD 
						})
end

-- Legs
local crlegnames = {
	"standard",
	"high jump",
	"ground",
	"formula",
	"stabilizer",
	"short thrust",
	"long thrust",
	"quick jump",
	"feather",
	"wide jump",
	"booster"
}
