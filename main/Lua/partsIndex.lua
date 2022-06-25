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
	mo = MT_REDRING,
	usesound = sfx_basic,
	parttype = CRPT_GUN,
	func = function(p, w)
		if not valid(p) then return end
		if not p.crplayerdata then return end
		local CRPD = FLCR.PlayerData[p.crplayerdata.id]
		if not valid(CRPD.player) then return end
		if not valid(p.mo) then return end
		local mo = p.mo

		if (CRPD.firetics%w.multiint) -- Modulo by your weapon's firedelay, a non zero number?
		or (CRPD.firemaxrounds >= w.maxrounds)
			return
		elseif not CRPD.firetics then
			CRPD.firetype = w.parttype
			CRPD.firetics = (w.multiint * w.maxrounds)*2 -- 26.5
			p.powers[pw_nocontrol] = CRPD.firetics - 3*(w.reload) -- -12 = 14.5
		end
		
		local th = P_SpawnPlayerMissile(mo, w.mo)
		S_StopSound(mo)
		if valid(th) then 
			th.target = mo
			S_StartSound(th, w.usesound)
		else
			S_StartSound(mo, w.usesound)
		end
		CRPD.firemaxrounds = $ + 1
	end,
	
	multiint = TICRATE/4, -- Multishot interval
	maxrounds = 3, -- How many rounds can your weapon fire per-clip?

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
	func = function(p, w)
		if not valid(p) then return end
		if not p.crplayerdata then return end
		local CRPD = FLCR.PlayerData[p.crplayerdata.id]
		if not valid(CRPD.player) then return end
		if not valid(p.mo) then return end
		local mo = p.mo

		if (CRPD.firetics%w.multiint) -- Modulo by your weapon's firedelay, a non zero number?
		or (CRPD.firemaxrounds >= w.maxrounds)
			return
		elseif not CRPD.firetics then
			CRPD.firetype = w.parttype
			CRPD.firetics = (w.multiint * w.maxrounds)*2 -- 48
			p.powers[pw_nocontrol] = CRPD.firetics - 5*(w.reload)
		end
		
		for i = -1, 1, 1 do
			local fa = i*ANGLE_45
			--local th = P_SpawnPlayerMissile(mo, w.mo)
		end
		CRPD.firemaxrounds = $ + 1
	end,
		
	multiint = TICRATE/9, -- Multishot interval
	maxrounds = 9, -- How many rounds can your weapon fire per-clip?
	
	attack = 5,
	speed = 5,
	homing = 4,
	reload = 5,
	down = 6,
})

FLCR.AddWeapon({
	name = "Gatling", 
	desc = "Fires multiple small rounds straight ahead. Stay close to the enemy for better shots.",
	mo = MT_REDRING,
	usesound = sfx_gtlng,
	parttype = CRPT_GUN,
	func = function(p, w)
		if not valid(p) then return end
		if not p.crplayerdata then return end
		local CRPD = FLCR.PlayerData[p.crplayerdata.id]
		if not valid(CRPD.player) then return end
		if not valid(p.mo) then return end
		local mo = p.mo

		if (CRPD.firetics%w.multiint) -- Modulo by your weapon's firedelay, a non zero number?
		or (CRPD.firemaxrounds >= w.maxrounds)
			return
		elseif not CRPD.firetics then
			CRPD.firetype = w.parttype
			CRPD.firetics = (w.multiint * w.maxrounds)*2 -- 54
			p.powers[pw_nocontrol] = CRPD.firetics - 5*(w.reload)
		end
		
		local th = P_SpawnPlayerMissile(mo, w.mo)
		S_StopSound(mo)
		if valid(th) then 
			th.target = mo
			S_StartSound(th, w.usesound)
		else
			S_StartSound(mo, w.usesound)
		end
		CRPD.firemaxrounds = $ + 1
	end,
	
	multiint = TICRATE/9, -- Multishot interval
	maxrounds = 9, -- How many rounds can your weapon fire per-clip?

	attack = 4,
	speed = 7,
	homing = 2,
	reload = 3,
	down = 6,
})

FLCR.AddWeapon({
	name = "Vertical", 
	desc = "Fires 2 rounds that ascend diagonally, clearing walls. Use them as you hide behind walls.",
	usesound = sfx_gtlng,
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
	usesound = sfx_gtlng,
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
