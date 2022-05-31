-- Hey, you're awfully nosy aren't you?
-- Just so you know, a lot of what you see here is mixed between original code
-- and code that I've gotten permission to use.
--
-- A word of warning: YOU SHOULD ASSUME __NONE__ OF THE CODE HERE IS REUSABLE.
-- GET PERMISSION TO USE THIS STUFF BEFORE YOU USE IT YOURSELF
--
-- Flame

local Guns = FLCR.Weapons.Guns
local Bombs = FLCR.Weapons.Bombs
local Pods = FLCR.Weapons.Pods

-- Guns
FLCR.AddGunWeapon({
	name = "basic",
	desc = "A training gun that fires 3 rounds straight ahead. It's for absolute beginners. The rounds are weaker at greater distances.",
	usesound = sfx_basic,
	parttype = CRPT_GUN,
	special = CRL_INVALID,
	attack = 4,
	speed = 5,
	homing = 2,
	reload = 4,
	down = 6,
})

FLCR.AddGunWeapon({
	name = "3way", 
	desc = "Fires 3 straight rounds in 3 rows. The farther you are from the enemy, the better its homing.",
	usesound = sfx_3way,
	parttype = CRPT_GUN,
	special = CRL_INVALID,
	attack = 5,
	speed = 5,
	homing = 4,
	reload = 5,
	down = 6,
})

FLCR.AddGunWeapon({
	name = "gatling", 
	desc = "Fires multiple small rounds straight ahead. Stay close to the enemy for better shots.",
	usesound = sfx_gtlng,
	parttype = CRPT_GUN,
	special = CRL_INVALID,
	attack = 4,
	speed = 7,
	homing = 2,
	reload = 3,
	down = 6,
})

FLCR.AddGunWeapon({
	name = "Vertical", 
	desc = "Fires 2 rounds that ascend diagonally, clearing walls. Use them as you hide behind walls.",
	usesound = sfx_gtlng,
	parttype = CRPT_GUN,
	special = CRL_INVALID,
	attack = 4,
	speed = 5,
	homing = 3,
	reload = 5,
	down = 7,
})

FLCR.AddGunWeapon({
	name = "Sniper", 
	desc = "Fires one quick, straight round. While the round flies fast, it leaves you in danger for a time.",
	usesound = sfx_gtlng,
	parttype = CRPT_GUN,
	special = CRL_INVALID,
	attack = 7,
	speed = 9,
	homing = 1,
	reload = 2,
	down = 7,
})

local crgunnames = {
	"stun",
	"hornet",
	"flame",
	"dragon",
	"splash",
}
for _, gn in ipairs(crgunnames)
	FLCR.AddGunWeapon({ name = gn, 
						parttype = CRPT_GUN 
						})
end

-- Bombs
FLCR.AddBombWeapon({
	name = "standard", 
	desc = "Flies in an arc toward target. It's large blast radius makes aiming and multiple blows a snap.",
	usesound = sfx_s3k81,
	parttype = CRPT_BOMB,
	special = CRL_INVALID,
	attack = 7,
	speed = 5,
	size = 5,
	time = 5,
	down = 6,
})

FLCR.AddBombWeapon({
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

FLCR.AddBombWeapon({
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

FLCR.AddBombWeapon({
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

FLCR.AddBombWeapon({
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
	FLCR.AddBombWeapon({ name = bn,
						parttype = CRPT_BOMB 
						})
end

-- Pods
FLCR.AddPodWeapon({
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
	FLCR.AddPodWeapon({ name = pn, 
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