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
	mo = MT_DUMMY,
	usesound = sfx_basic,
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
		local xyangle, zangle = p.drawangle, p.aiming
		local th = P_SpawnPlayerMissile(mo, w.mo)
		if valid(th) 
		and P_TryMove(th, th.x + FixedMul(cos(xyangle), FixedMul(2*th.radius,mo.scale)), 
							th.y + FixedMul(sin(xyangle), FixedMul(2*th.radius,mo.scale)), true) then
			th.target = mo -- Host
			if mo.target then -- Host has a target?
				xyangle, zangle = Lib.getXYZangle(mo, mo.target)
				th.tracer = mo.target -- Set your tracer to your host's target for later
			end
			S_StartSoundAtVolume(th, w.usesound, 192)
			if not (mobjinfo[w.mo].flags & MF_MISSILE) then -- Some weird behavior with non-native missles
				th.flags = MF_NOGRAVITY|MF_MISSILE
				P_SetObjectMomZ(th, (zangle/(4*ANG1/3))*FRACUNIT, false)
			end
			th.thinkfunc = w.thinkfunc
			th.damage = w.attack * 8 -- 32
			th.knockdown = 24 -- Getting hit with all 3 shots applies 74 knockdown
			th.angle = xyangle
			th.state = S_RRNG1
			th.color = SKINCOLOR_YELLOW
			th.fuse = 3*TICRATE
			P_InstaThrust(th,th.angle,(10*FRACUNIT)*w.speed)
		end
		CRPD.firemaxrounds = $ + 1
	end,
	
	thinkfunc = function(mo)
		if not valid(mo) then return end
		local fx = P_SpawnMobjFromMobj(mo, 0,0,-(mobjinfo[mo.type].height/3), MT_THOK)
		fx.color = mo.color
		fx.destscale = 1
		fx.scalespeed = FRACUNIT/5
		
		local factor = 64
		mo.momx = $ - $/factor
		mo.momy = $ - $/factor
		mo.momz = $ - $/factor
		if mo.tracer then
			local t = mo.tracer
			local angle = R_PointToAngle2(mo.x, mo.y, t.x, t.y)
			P_Thrust(mo, angle, FRACUNIT/factor)
		end
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
	usesound = sfx_3way,
	parttype = CRPT_GUN,
	spawnfunc = function(p, w)
		if not valid(p) then return end
		if not p.crplayerdata then return end
		local CRPD = FLCR.PlayerData[p.crplayerdata.id]
		if not valid(CRPD.player) then return end
		if not valid(p.mo) then return end
		local mo = p.mo

		local multifireinterval = TICRATE/9 -- Multishot interval
		local maxrounds = 3 -- How many rounds can your weapon fire per-clip?
		if (CRPD.firetics%multifireinterval) -- Modulo by your weapon's firedelay, a non zero number?
		or (CRPD.firemaxrounds >= maxrounds)
			return
		elseif not CRPD.firetics then
			CRPD.firetype = w.parttype
			CRPD.firetics = (multifireinterval * maxrounds)*2 -- 48
			p.powers[pw_nocontrol] = CRPD.firetics - 5*(w.reload)
		end
		
		-- Let's spawn the bullets!
		/*for i = -1, 1, 1 do
			local xyangle, zangle = mo.angle, p.aiming
			local fa = i*ANGLE_45
			mo.extravalue1 = i
			local th = P_SpawnMobjFromMobj(mo, 0, 0, mo.height/2, MT_DUMMY)
			if valid(th) 
			and P_TryMove(th, th.x + FixedMul(cos(mo.angle + fa), FixedMul(2*th.radius,mo.scale)), 
							th.y + FixedMul(sin(mo.angle + fa), FixedMul(2*th.radius,mo.scale)), true) then
				th.target = mo -- Host
				if mo.target then -- Host has a target?
					xyangle, zangle = Lib.getXYZangle(mo, mo.target)
					th.tracer = mo.target -- Set your tracer to your host's target for later
				end
				if not i then S_StartSoundAtVolume(th, w.usesound, 192) end -- Only spawn one sound.
				-- TODO: Z AIMING
				th.thinkfunc = w.thinkfunc
				th.damage = w.attack * 8 -- 32
				th.knockdown = 24 -- Getting hit with all 3 shots applies 74 knockdown
				th.angle = xyangle
				th.state = S_RRNG1
				th.color = SKINCOLOR_YELLOW
				th.fuse = 3*TICRATE
				P_InstaThrust(th,th.angle,(10*FRACUNIT)*w.speed)
			end
		end*/
		CRPD.firemaxrounds = $ + 1
	end,
	
	thinkfunc = function(mo)
		if not valid(mo) then return end
		-- Bullet Lifetime equals 1/7th of a second?
		-- Stop heading in an angle and straighten out
		if mo.extravalue1 then return end
		-- Middle bullet has a little bit of homing
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
	mo = MT_DUMMY,
	usesound = sfx_gtlng,
	parttype = CRPT_GUN,
	spawnfunc = function(p, w)
		if not valid(p) then return end
		if not p.crplayerdata then return end
		local CRPD = FLCR.PlayerData[p.crplayerdata.id]
		if not valid(CRPD.player) then return end
		if not valid(p.mo) then return end
		local mo = p.mo

		local multifireinterval = TICRATE/9 -- Multishot interval
		local maxrounds = 9 -- How many rounds can your weapon fire per-clip?
		if (CRPD.firetics%multifireinterval) -- Modulo by your weapon's firedelay, a non zero number?
		or (CRPD.firemaxrounds >= maxrounds)
			return
		elseif not CRPD.firetics then
			CRPD.firetype = w.parttype
			CRPD.firetics = (multifireinterval * maxrounds)*2 -- 54
			p.powers[pw_nocontrol] = CRPD.firetics - 5*(w.reload)
		end
		
		-- Let's spawn the bullet!
		local xyangle, zangle = p.drawangle, p.aiming
		local th = P_SpawnPlayerMissile(mo, w.mo)
		if valid(th) 
		and P_TryMove(th, th.x + FixedMul(cos(xyangle), FixedMul(2*th.radius,mo.scale)), 
							th.y + FixedMul(sin(xyangle), FixedMul(2*th.radius,mo.scale)), true) then
			th.target = mo -- Host
			if mo.target then -- Host has a target?
				xyangle, zangle = Lib.getXYZangle(mo, mo.target)
				th.tracer = mo.target -- Set your tracer to your host's target for later
			end
			S_StartSoundAtVolume(th, w.usesound, 192)
			if not (mobjinfo[w.mo].flags & MF_MISSILE) then -- Some weird behavior with non-native missles
				th.flags = MF_NOGRAVITY|MF_MISSILE
				P_SetObjectMomZ(th, (zangle/(4*ANG1/3))*FRACUNIT, false)
			end
			th.thinkfunc = w.thinkfunc
			th.damage = w.attack * 8 -- 32
			th.knockdown = 9 -- Getting hit with all 9 shots applies 72 knockdown
			th.angle = xyangle
			th.state = S_RRNG1
			th.color = SKINCOLOR_YELLOW
			th.fuse = 3*TICRATE
			P_InstaThrust(th,th.angle,(10*FRACUNIT)*w.speed)
		end
		CRPD.firemaxrounds = $ + 1
	end,

	thinkfunc = function(mo)
		if not valid(mo) then return end
		local fx = P_SpawnMobjFromMobj(mo, 0,0,-(mobjinfo[mo.type].height/3), MT_THOK)
		fx.color = mo.color
		fx.destscale = 1
		fx.scalespeed = FRACUNIT/5
		
		local factor = 64
		mo.momx = $ - $/factor
		mo.momy = $ - $/factor
		mo.momz = $ - $/factor
		if mo.tracer then
			local t = mo.tracer
			local angle = R_PointToAngle2(mo.x, mo.y, t.x, t.y)
			P_Thrust(mo, angle, FRACUNIT/factor)
		end
	end,

	attack = 4,
	speed = 7,
	homing = 2,
	reload = 3,
	down = 6,
})

FLCR.AddWeapon({
	name = "Vertical", 
	desc = "Fires 2 rounds that ascend diagonally, clearing walls. Use them as you hide behind walls.",
	usesound = sfx_vrtcl,
	parttype = CRPT_GUN,
	attack = 4,
	speed = 5,
	homing = 3,
	reload = 5,
	down = 7,
})

FLCR.AddWeapon({
	name = "Sniper",
	desc = "Fires one quick, straight round. While the round flies fast, it leaves you in danger for a time.",
	usesound = sfx_snip,
	parttype = CRPT_GUN,
	attack = 7,
	speed = 9,
	homing = 1,
	reload = 2,
	down = 7,
})

FLCR.AddWeapon({
	name = "Stun", 
	desc = "Fires continuous short-ranged electric shots that paralyze foes. Use at close range.",
	usesound = 0,
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
	usesound = 0,
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
	usesound = 0,
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
	usesound = 0,
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
	usesound = 0,
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
	mo = MT_REDRING,
	usesound = sfx_s3k81,
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
	usesound = sfx_s3k81,
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
	usesound = sfx_s3k81,
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
	usesound = sfx_s3k81,
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
	usesound = sfx_s3k81,
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
	usesound = sfx_s3k82,
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
