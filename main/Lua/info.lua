-- Hey, you're awfully nosy aren't you?
-- Just so you know, a lot of what you see here is mixed between original code
-- and code that I've gotten permission to use.
--
-- A word of warning: YOU SHOULD ASSUME __NONE__ OF THE CODE HERE IS REUSABLE.
-- GET PERMISSION TO USE THIS STUFF BEFORE YOU USE IT YOURSELF
--
-- Flame

SafeFreeslot("MT_DUMMY", "MT_DUMMYFX")

local dummy_t = {
	doomednum = -1,
	spawnstate = S_INVISIBLE,
	spawnhealth = 1000,
	radius = 16*FRACUNIT,
	height = 32*FRACUNIT,
	flags = MF_NOGRAVITY|MF_NOCLIPTHING|MF_NOBLOCKMAP|MF_NOCLIPHEIGHT|MF_NOCLIP
}

mobjinfo[MT_DUMMY] = dummy_t
mobjinfo[MT_DUMMYFX] = dummy_t

-- Arrows!
SafeFreeslot("SPR_RKAW", "S_RKAW1")
states[S_RKAW1] = {SPR_RKAW, A|FF_FULLBRIGHT|FF_PAPERSPRITE, 1, nil, 0, 0, S_NULL}

-- Various FX!
-- "Real Explosion" - From Metal Slug
SafeFreeslot("SPR_RXPL")
for i = 0, 19 do
	SafeFreeslot("S_RXPL"..i+1)
	states[S_RXPL1+i] = {SPR_RXPL, i|FF_FULLBRIGHT, 2, nil, 0, 0, (i<19) and S_RXPL1+(i+1) or S_NULL}
end

-- Recovery Line FX - "Lines up"
SafeFreeslot("SPR_LINU", "S_FX_LINEUP")
states[S_FX_LINEUP] = {SPR_LINU, A|FF_FULLBRIGHT|FF_ANIMATE , 19, nil, 19, 1, S_NULL}

-- Wind dissapate FX - "B/W Fire center"
SafeFreeslot("SPR_WFX1", "S_FX_WIND")
states[S_FX_WIND] = { SPR_WFX1, A|FF_FULLBRIGHT|FF_ANIMATE|FF_PAPERSPRITE, 23, nil, 23, 1, S_NULL }

-- Hit FX Right
SafeFreeslot("SPR_HITA", "S_FX_HIT1")
states[S_FX_HIT1] = { SPR_HITA, A|FF_FULLBRIGHT|FF_ANIMATE|FF_PAPERSPRITE, 7, nil, 7, 1, S_NULL }
SafeFreeslot("SPR_HITB", "S_FX_HIT2")
states[S_FX_HIT2] = { SPR_HITB, A|FF_FULLBRIGHT|FF_ANIMATE|FF_PAPERSPRITE, 8, nil, 8, 1, S_NULL }
SafeFreeslot("SPR_HITC", "S_FX_HIT3")
states[S_FX_HIT3] = { SPR_HITC, A|FF_FULLBRIGHT|FF_ANIMATE|FF_PAPERSPRITE, 8, nil, 8, 1, S_NULL }
-- Hit FX Center
SafeFreeslot("SPR_HITD", "S_FX_HIT4")
states[S_FX_HIT4] = { SPR_HITD, A|FF_FULLBRIGHT|FF_ANIMATE, 7, nil, 7, 1, S_NULL }
SafeFreeslot("SPR_HITE", "S_FX_HIT5")
states[S_FX_HIT5] = { SPR_HITE, A|FF_FULLBRIGHT|FF_ANIMATE, 7, nil, 7, 1, S_NULL }
-- Sparks - Floor, Loop up
SafeFreeslot("SPR_FSPK", "S_FX_FSPARK")
states[S_FX_FSPARK] = { SPR_FSPK, A|FF_FULLBRIGHT|FF_ANIMATE, -1, nil, 3, 1, S_FX_FSPARK }

-- Energy Ray Up
SafeFreeslot("SPR_NRGU", "S_FX_ENERGYUP")
states[S_FX_ENERGYUP] = { SPR_NRGU, A|FF_FULLBRIGHT|FF_ANIMATE, 31, nil, 31, 1, S_NULL }

-- Electricity Hit FX - Floor up
SafeFreeslot("SPR_ELEA", "S_FX_ELECUP1")
states[S_FX_ELECUP1] = { SPR_ELEA, A|FF_FULLBRIGHT|FF_ANIMATE, 15, nil, 15, 1, S_NULL }
SafeFreeslot("SPR_ELEB", "S_FX_ELECUP2")
states[S_FX_ELECUP2] = { SPR_ELEB, A|FF_FULLBRIGHT|FF_ANIMATE, 12, nil, 12, 1, S_NULL }

-- Fire / Lava Hit FX - Floor up
SafeFreeslot("SPR_FIRA", "S_FX_FIREUP1")
states[S_FX_FIREUP1] = { SPR_FIRA, A|FF_FULLBRIGHT|FF_ANIMATE, 17, nil, 17, 1, S_NULL }

-- Sounds
SafeFreeslot("sfx_pplode")
sfxinfo[sfx_pplode].caption = "Player Explode"
sfxinfo[sfx_pplode].flags = SF_X2AWAYSOUND|SF_X4AWAYSOUND|SF_X8AWAYSOUND

SafeFreeslot("sfx_gtlng")
sfxinfo[sfx_gtlng].caption = "Gatling fire"
sfxinfo[sfx_gtlng].flags = SF_X2AWAYSOUND|SF_X4AWAYSOUND|SF_X8AWAYSOUND

SafeFreeslot("sfx_basic")
sfxinfo[sfx_basic].caption = "Basic fire"
sfxinfo[sfx_basic].flags = SF_X2AWAYSOUND|SF_X4AWAYSOUND|SF_X8AWAYSOUND

SafeFreeslot("sfx_3way")
sfxinfo[sfx_3way].caption = "3-Way fire"
sfxinfo[sfx_3way].flags = SF_X2AWAYSOUND|SF_X4AWAYSOUND|SF_X8AWAYSOUND

SafeFreeslot("sfx_vrtcl")
sfxinfo[sfx_vrtcl].caption = "Vertical fire"
sfxinfo[sfx_vrtcl].flags = SF_X2AWAYSOUND|SF_X4AWAYSOUND|SF_X8AWAYSOUND

SafeFreeslot("sfx_snip")
sfxinfo[sfx_snip].caption = "Sniper fire"
sfxinfo[sfx_snip].flags = SF_X2AWAYSOUND|SF_X4AWAYSOUND|SF_X8AWAYSOUND
