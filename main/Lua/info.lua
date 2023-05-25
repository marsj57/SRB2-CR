-- Hey, you're awfully nosy aren't you?
-- Just so you know, a lot of what you see here is mixed between original code
-- and code that I've gotten permission to use.
--
-- A word of warning: YOU SHOULD ASSUME __NONE__ OF THE CODE HERE IS REUSABLE.
-- GET PERMISSION TO USE THIS STUFF BEFORE YOU USE IT YOURSELF
--
-- Flame

SafeFreeslot("MT_DUMMY", "MT_DUMMYMISSILE", "MT_DUMMYFX")

for i = 1, #players do
	skincolors[freeslot("SKINCOLOR_P" + i + "_OUTLINE")] = {
		name = "Custom Robo P" + i + " Outline",
		ramp = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
		invcolor = SKINCOLOR_BLACK,
		invshade = 0,
		chatcolor = V_INVERTMAP,
		accessible = false
	}
end

local dummy_t = {
	doomednum = -1,
	spawnstate = S_INVISIBLE,
	deathstate = S_SPRK2,
	spawnhealth = 1000,
	radius = 16*FRACUNIT,
	height = 32*FRACUNIT,
	flags = MF_NOGRAVITY|MF_NOCLIPTHING|MF_NOBLOCKMAP|MF_NOCLIPHEIGHT|MF_NOCLIP
}

mobjinfo[MT_DUMMY] = dummy_t
mobjinfo[MT_DUMMYMISSILE] = dummy_t
mobjinfo[MT_DUMMYMISSILE].flags = mobjinfo[MT_REDRING].flags --MF_NOBLOCKMAP|MF_MISSILE|MF_NOGRAVITY
mobjinfo[MT_DUMMYFX] = dummy_t

-- Custom Bee!
SafeFreeslot("S_BUMBLEBORE_BULLET")
states[S_BUMBLEBORE_BULLET] = { SPR_BUMB, A|FF_FULLBRIGHT|FF_ANIMATE, -1, nil, 1, 2, S_NULL }

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
states[S_FX_LINEUP] = {SPR_LINU, A|FF_FULLBRIGHT|FF_ANIMATE, 19, nil, 19, 1, S_NULL}

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

-- Electricity / Hit FX - Floor up
SafeFreeslot("SPR_ELEA", "S_FX_ELECUP1")
states[S_FX_ELECUP1] = { SPR_ELEA, A|FF_FULLBRIGHT|FF_ANIMATE, 15, nil, 15, 1, S_NULL }
SafeFreeslot("SPR_ELEB", "S_FX_ELECUP2")
states[S_FX_ELECUP2] = { SPR_ELEB, A|FF_FULLBRIGHT|FF_ANIMATE, 11, nil, 11, 1, S_NULL }

-- SPR_ELEC is already occupied!

-- Electricity / Charge Right
SafeFreeslot("SPR_ELED", "S_FX_ELECDIAG")
states[S_FX_ELECDIAG] = { SPR_ELED, A|FF_FULLBRIGHT|FF_ANIMATE|FF_PAPERSPRITE|FF_TRANS20, 20, nil, 20, 1, S_NULL }
-- Electricity / Hit Explosion Radial
SafeFreeslot("SPR_ELEE", "S_FX_ELECEXPLODE")
states[S_FX_ELECEXPLODE] = { SPR_ELEE, A|FF_FULLBRIGHT|FF_ANIMATE, 10, nil, 10, 1, S_NULL }

-- Fire / Lava Hit FX - Floor up
SafeFreeslot("SPR_FIRA", "S_FX_FIREUP1")
states[S_FX_FIREUP1] = { SPR_FIRA, A|FF_FULLBRIGHT|FF_ANIMATE, 18, nil, 18, 1, S_NULL }
-- Fire / Fireball Radial
SafeFreeslot("SPR_FIRB", "S_FX_FIREBALL")
states[S_FX_FIREBALL] = { SPR_FIRB, A|FF_FULLBRIGHT|FF_ANIMATE, 23, nil, 23, 1, S_NULL }
-- Fire / Hit FX Up
SafeFreeslot("SPR_FIRC", "S_FX_FIREUP2")
states[S_FX_FIREUP2] = { SPR_FIRC, A|FF_FULLBRIGHT|FF_ANIMATE, 24, nil, 24, 1, S_NULL }

-- Sounds
-- Sounds may not be in order of addition, or time of when the weapon was worked on.
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

SafeFreeslot("sfx_frame")
sfxinfo[sfx_frame].caption = "Flame fire"
sfxinfo[sfx_frame].flags = SF_X2AWAYSOUND|SF_X4AWAYSOUND|SF_X8AWAYSOUND

SafeFreeslot("sfx_hnet")
sfxinfo[sfx_frame].caption = "Hornet fire"
sfxinfo[sfx_frame].flags = SF_X2AWAYSOUND|SF_X4AWAYSOUND|SF_X8AWAYSOUND

SafeFreeslot("sfx_stun")
sfxinfo[sfx_frame].caption = "Stun fire"
sfxinfo[sfx_frame].flags = SF_X2AWAYSOUND|SF_X4AWAYSOUND|SF_X8AWAYSOUND

SafeFreeslot("sfx_drag01")
sfxinfo[sfx_frame].caption = "Dragon fire"
sfxinfo[sfx_frame].flags = SF_X2AWAYSOUND|SF_X4AWAYSOUND|SF_X8AWAYSOUND

SafeFreeslot("sfx_drag02")
sfxinfo[sfx_frame].caption = "Dragon bullet"
sfxinfo[sfx_frame].flags = SF_X2AWAYSOUND|SF_X4AWAYSOUND|SF_X8AWAYSOUND

-- sfx_splash already occupied!
SafeFreeslot("sfx_splasf")
sfxinfo[sfx_frame].caption = "Splash fire"
sfxinfo[sfx_frame].flags = SF_X2AWAYSOUND|SF_X4AWAYSOUND|SF_X8AWAYSOUND