-- Hey, you're awfully nosy aren't you?
-- Just so you know, a lot of what you see here is mixed between original code
-- and code that I've gotten permission to use.
--
-- A word of warning: YOU SHOULD ASSUME __NONE__ OF THE CODE HERE IS REUSABLE.
-- GET PERMISSION TO USE THIS STUFF BEFORE YOU USE IT YOURSELF
--
-- Flame

/*
	Parts will be separated into categories

	Gun Parts
	Bomb Parts
	Pod Parts
*/
local partType = {}
createEnum(partType, {
	"CRPT_INVALID",
	
	"CRPT_GUN",
	"CRPT_BOMB",
	"CRPT_POD",
})

/*
	Some details about Custom Robo itself as a game...
	Many of the bombs and pods have a letter after the name. 
	Here's what they stand for. Think of this as a glossary.

	B (Burst)- Blows opponent sideways slowly, blast lingers
	C (Cyclone)- Blows opponent slowly upwards
	D (Destroy)- Blows opponent diagonally upwards, blast lingers
	F (Flipper)- Blows opponent sideways
	G (Gazer)- Blows opponent upwards
	H (Horizon)- Blows opponent slowly sideways
	K (Knockdown)- Will always knock opponent down
	P (Pillar)- Blows opponent upwards, blast lingers
	S (Stun)- Immobilizes target
	T (Traction)- Pulls opponent towards you
	X (Explosion)- Blows opponent diagonally high in the air
*/
local specialLetter = {}
createEnum(specialLetter, {
	"CRL_INVALID",
	
	"CRL_B",
	"CRL_C",
	"CRL_D",
	"CRL_F",
	"CRL_G",
	"CRL_H",
	"CRL_K",
	"CRL_P",
	"CRL_S",
	"CRL_T",
	"CRL_X"
})

local defaultWeaponStruct = {
	name = "Invalid",
	desc = "This weapon is missing a description. Please give this weapon a description!",
	mt = MT_DUMMY,
	usesound = 0,
	parttype = CRPT_INVALID, -- Gun, Bomb, or Pod
	special = CRL_INVALID,
	fuse = 0, -- Bullet lifetime
	attack = 0,
	speed = 0,
	homing = 0, -- Gun and Pod ONLY
	reload = 0, -- Gun ONLY
	down = 0, -- Gun and Bomb ONLY, affects how much endurance is removed from opponent's meter
	size = 0, -- Bomb and Pod ONLY, Size of the blast
	time = 0, -- Bomb and Pod ONLY, How long the blast lasts
	spawnfunc = nil,
	thinkfunc = nil
}
--registerMetatable(defaultWeaponStruct)

local newIndexMethod = setmetatable({}, {
	__newindex = function(t,k,v)
		for Dk,Dv in pairs(defaultWeaponStruct) do -- iterate thru fallback table
			if v[Dk] == nil then -- if v does not have a value assigned to this key,
				v[Dk] = Dv -- we give it the one in fallback
			end
		end
		rawset(t,k,v)
	end
})

local function ResetGunWeapons()
	FLCR.Weapons.Guns = newIndexMethod
end

local function ResetBombWeapons()
	FLCR.Weapons.Bombs = newIndexMethod
end

local function ResetPodWeapons()
	FLCR.Weapons.Pods = newIndexMethod
end

ResetGunWeapons()
ResetBombWeapons()
ResetPodWeapons()

FLCR.AddGunWeapon = function(t)
	t = $ or {}
	assert(t.name, "Gun name not provided!")
	local rsn = "CRWEP_GUN_" + string.upper(t.name:gsub(" ", ""))
	assert(not FLCR.Weapons.Guns[_G[rsn]], "Gun "..t.name.." not registered as it is already registered!")

	local id = #FLCR.Weapons.Guns + 1
	rawset(_G, rsn, id)
	FLCR.Weapons.Guns[id] = t
	print("Added new GUN Weapon: " + t.name + " (" + rsn + ")")
end

FLCR.AddBombWeapon = function(t)
	t = $ or {}
	assert(t.name, "Bomb name not provided!")
	local rsn = "CRWEP_BOMB_" + string.upper(t.name:gsub(" ", ""))
	assert(not FLCR.Weapons.Bombs[_G[rsn]], "Bomb "..t.name.." not registered as it is already registered!")

	local id = #FLCR.Weapons.Bombs + 1
	rawset(_G, rsn, id)
	FLCR.Weapons.Bombs[id] = t
	print("Added new BOMB Weapon: " + t.name + " (" + rsn + ")")
end

FLCR.AddPodWeapon = function(t)
	t = $ or {}
	assert(t.name, "Pod name not provided!")
	local rsn = "CRWEP_POD_" + string.upper(t.name:gsub(" ", ""))
	assert(not FLCR.Weapons.Pods[_G[rsn]], "Pod "..t.name.." not registered as it is already registered!")

	local id = #FLCR.Weapons.Pods + 1
	rawset(_G, rsn, id)
	FLCR.Weapons.Pods[id] = t
	print("Added new POD Weapon: " + t.name + " (" + rsn + ")")
end
