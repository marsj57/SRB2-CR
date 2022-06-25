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

FLCR.AddWeapon = function(t)
	t = $ or {}
	assert(t.name, "Weapon name not provided!")
	assert(t.parttype, "Weapon Part Type not provided!")
	local rsn = "CRWEP_"
	local pt = t.parttype
	if (pt == CRPT_GUN) then -- Gun
		rsn = $ + "GUN_" + string.upper(t.name:gsub(" ", ""))
	elseif (pt == CRPT_BOMB) then -- Bomb
		rsn = $ + "BOMB_" + string.upper(t.name:gsub(" ", ""))
	elseif (pt == CRPT_POD) then -- Pod
		rsn = $ + "POD_" + string.upper(t.name:gsub(" ", ""))
	/*elseif (pt == CRPT_LEG) then
		rsn = $ + "LEG_" + string.upper(t.name:gsub(" ", ""))*/
	end
	assert(not FLCR.Weapons[_G[rsn]], "Weapon "..t.name.." ("..rsn..") not registered as it is already registered!")

	local id = #FLCR.Weapons + 1
	rawset(_G, rsn, id)
	FLCR.Weapons[id] = t

	--local pts = string.sub(rsn, 7, 8) -- Part type String
	if (pt == CRPT_GUN) then -- Gun
		print("Added new GUN Weapon:  " + t.name + " (" + rsn + ")")
	elseif (pt == CRPT_BOMB) then -- Bomb
		print("Added new BOMB Weapon: " + t.name + " (" + rsn + ")")
	elseif (pt == CRPT_POD) then -- Pod
		print("Added new POD Weapon:  " + t.name + " (" + rsn + ")")
	/*elseif (pt == CRPT_LEG) then -- Legs?
		print("Added new LEG Part:  " + t.name + " (" + rsn + ")")*/
	end
end

local defaultWeaponStruct = {
	name = "Invalid", -- Name of weapon to rawset (CRWEP_ (Part Type below) _Name)
	desc = "This weapon is missing a description. Please give this weapon a description!", -- Self explainitory
	mo = MT_DUMMY,
	usesound = 0, -- Use sound for spawning
	parttype = CRPT_INVALID, -- Gun, Bomb, or Pod
	special = CRL_INVALID, -- Special letter, see above table
	func = nil, -- Function

	-- For multi-fire weapons
	firedelay = 0, -- Firing delay between shots
	maxrounds = 0, -- How many rounds can your weapon fire per-clip?
	
	-- Hud Display stuff
	attack = 0,
	speed = 0,
	homing = 0, -- Gun and Pod ONLY
	reload = 0, -- Gun ONLY
	down = 0, -- Gun and Bomb ONLY, affects how much endurance is removed from opponent's meter
	size = 0, -- Bomb and Pod ONLY, Size of the blast
	time = 0, -- Bomb and Pod ONLY, How long the blast lasts
}
--registerMetatable(defaultWeaponStruct)

local function ResetCRWeapons()
	FLCR.Weapons = setmetatable({}, {
		__newindex = function(t,k,v)
			for Dk,Dv in pairs(defaultWeaponStruct) do -- iterate thru fallback table
				if v[Dk] == nil then -- if v does not have a value assigned to this key,
					v[Dk] = Dv -- we give it the one in fallback
				end
			end
			rawset(t,k,v)
		end
	})
	dofile("partsIndex.lua")
end
ResetCRWeapons()

local defaultPlayerStruct = {
	__index = {
		id = 0,
		player = nil,
		loadout = {CRWEP_GUN_BASIC, CRWEP_BOMB_STANDARD, CRWEP_POD_STANDARD}, -- Noob Pack
		loadoutsel = 1,
		health = 0,
		firetics = 0,
		firemaxrounds = 0,
		firetype = CRPT_INVALID,
		downed = false
	}
}
registerMetatable(defaultPlayerStruct)

local function ResetCRPlayerData()
	FLCR.PlayerData = $ or {}
	
	for i = 1, #players do
		FLCR.PlayerData[i] = setmetatable({}, defaultPlayerStruct)
		FLCR.PlayerData[i].id = i
	end
end
ResetCRPlayerData()