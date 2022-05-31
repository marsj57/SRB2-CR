-- Hey, you're awfully nosy aren't you?
-- Just so you know, a lot of what you see here is mixed between original code
-- and code that I've gotten permission to use.
--
-- A word of warning: YOU SHOULD ASSUME __NONE__ OF THE CODE HERE IS REUSABLE.
-- GET PERMISSION TO USE THIS STUFF BEFORE YOU USE IT YOURSELF
--
-- Flame

SafeFreeslot("MT_DUMMY")

mobjinfo[MT_DUMMY] = {
	doomednum = -1,
	spawnstate = S_INVISIBLE,
	spawnhealth = 1000,
	radius = 16*FRACUNIT,
	height = 32*FRACUNIT,
	flags = MF_NOGRAVITY|MF_NOCLIPTHING|MF_NOBLOCKMAP|MF_NOCLIPHEIGHT|MF_NOCLIP
}

-- Flame
-- Detailed explosion
SafeFreeslot("SPR_RXPL")
for i = 0, 19 do
	SafeFreeslot("S_RXPL"..i+1)
	states[S_RXPL1+i] = {SPR_RXPL, i|FF_FULLBRIGHT, 2, nil, 0, 0, (i<19) and S_RXPL1+(i+1) or S_NULL}
end

-- Arrows!
SafeFreeslot("SPR_RKAW")
SafeFreeslot("S_RKAW1")
states[S_RKAW1] = {SPR_RKAW, A|FF_FULLBRIGHT|FF_PAPERSPRITE, 1, nil, 0, 0, S_NULL}

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
