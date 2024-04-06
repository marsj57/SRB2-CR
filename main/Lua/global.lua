-- Hey, you're awfully nosy aren't you?
-- Just so you know, a lot of what you see here is mixed between original code,
-- and code that I've gotten permission to use.
--
-- You should assume that the code I borrowed is not reusable.
-- I've commented the names of individuals from whom,
-- I received permission to use their code.
-- GET PERMISSION TO USE THIS STUFF BEFORE YOU USE IT YOURSELF
-- 
-- Flame

rawset(_G, "FLCR", {}) -- Flame's Custom Robo
rawset(_G, "FLCRLib", {}) -- Flame's Custom Robo Library
rawset(_G, "FLCRDebug", 0)
FLCR.PlayerData = {} -- Player Data table
FLCR.Weapons = {} -- Weapons Table
FLCR.CameraBattleAngle = 0

rawset(_G, "valid", function(th)
	return th and th.valid
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
		if pcall(CheckSlot, item) then
			print("\131NOTICE:\128 " .. item .. " was not allocated, as it already exists.")
		else
			freeslot(item)
		end
	end
end)
-- End Lach

-- Flame
-- Creates 'flags' in powers of 2^n
rawset(_G, "createFlags", function(tname, t)
    for i = 1,#t do
		rawset(_G, t[i], 2^(i-1))
		table.insert(tname, {string = t[i], value = 2^(i-1)} )
    end
end)

-- Flame
-- Creates an enum from 1 - max size of provided table
rawset(_G, "createEnum", function(tname, t, from)
    if from == nil then from = 0 end
    for i = 1,#t do
		rawset(_G, t[i], from+(i-1))
		table.insert(tname, {string = t[i], value = from+(i-1)} )
    end
end)

-- Table sorting
-- Flame, 5-16-21
rawset(_G, "spairs", function(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end)

-- Linear Interpolation
rawset(_G, "FixedLerp", function(val1,val2,amt)
	local p = FixedMul(FRACUNIT-amt,val1) + FixedMul(amt,val2)
	return p
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

if FLCRDebug then
-- Amperbee
local dict = {
	["nil"] = "nil",
	["boolean"] = "bool",
	["number"] = "int",
	["string"] = "str",
	["function"] = "func",
	["userdata"] = "udata",
	["thread"] = "thrd",
	["table"] = "table",
}
rawset(_G, "drawContentsRecursively", function(dw, t, s)
	-- draws table t recursively
	-- dw must be a drawer, t must be a table, s must be a table
	-- ensure s is already populated with position, do not modify during runtime
	-- s = state
	
	--if s == nil then error("argument #3 is missing",2) end
	if s.level == nil then
		s.level = 0
	end
	
	local levelpush = s.level*4
	
	if next(t) == nil then
		dw.drawString(s.x + levelpush, s.y,
			"\134".."[empty]",
		V_ALLOWLOWERCASE, "small")
		s.y = $+4
		return
	end
	if t._HIDE then
		dw.drawString(s.x + levelpush, s.y,
			"\134".."[hidden]",
		V_ALLOWLOWERCASE, "small")
		s.y = $+4
		return
	end
	for k,v in pairs(t) do
		local vstr = tostring(v)
		local vtype,utype = type(v),""
		
		local hex = vstr:sub(-8,-1)
		local pre,post = dict[vtype],vstr
		
		if vtype == "userdata" then
			utype = userdataType(v)
			post = utype.." "..hex
			--if utype ~= "unknown" then post = utype end
		elseif vtype == "table" then
			--post = hex.." #"..#v
			post = hex
			pre = $.."["..#v.."]"
		elseif vtype == "function" or vtype == "thread" then
			post = hex
		end
		
		
		
		dw.drawString(s.x + levelpush, s.y,
			("\130%s \128%s \131%s"):format(pre, tostring(k), post),
		V_ALLOWLOWERCASE, "small")
		
		s.y = $+4
		if vtype == "table" then
			s.level = $+1
			drawContentsRecursively(dw, v, s)
			s.level = $-1
		end
	end
end)
end

-- Globalize constants to avoid using lib_getenum in C.
-- Yes, conceptually this is STUPID.
local g = rawset -- From here, refer to everything as "g"

-- Overall globals
g(_G, "FRACUNIT", FRACUNIT)
g(_G, "FRACBITS", FRACBITS)
g(_G, "TICRATE", TICRATE)

g(_G, "INT8_MIN", INT8_MIN)
g(_G, "INT16_MIN", INT16_MIN)
g(_G, "INT32_MIN", INT32_MIN)
g(_G, "INT8_MAX", INT8_MAX)
g(_G, "INT16_MAX", INT16_MAX)
g(_G, "INT32_MAX", INT32_MAX)
g(_G, "UINT8_MAX", UINT8_MAX)
g(_G, "UINT16_MAX", UINT16_MAX)
g(_G, "UINT32_MAX", UINT32_MAX)

-- Frame flags
g(_G, "FF_FRAMEMASK", FF_FRAMEMASK)
g(_G, "FF_PAPERSPRITE", FF_PAPERSPRITE)
g(_G, "FF_ANIMATE", FF_ANIMATE)
g(_G, "FF_FULLBRIGHT", FF_FULLBRIGHT)
g(_G, "FF_HORIZONTALFLIP", FF_HORIZONTALFLIP)
g(_G, "FF_SPR2SUPER", FF_SPR2SUPER)
g(_G, "FF_TRANSMASK", FF_TRANSMASK)
g(_G, "FF_TRANSSHIFT", FF_TRANSSHIFT)
g(_G, "FF_TRANS10", FF_TRANS10)
g(_G, "FF_TRANS20", FF_TRANS20)
g(_G, "FF_TRANS30", FF_TRANS30)
g(_G, "FF_TRANS40", FF_TRANS40)
g(_G, "FF_TRANS50", FF_TRANS50)
g(_G, "FF_TRANS60", FF_TRANS60)
g(_G, "FF_TRANS70", FF_TRANS70)
g(_G, "FF_TRANS80", FF_TRANS80)
g(_G, "FF_TRANS90", FF_TRANS90)
g(_G, "TR_TRANS10", tr_trans10<<FF_TRANSSHIFT)
g(_G, "TR_TRANS20", tr_trans20<<FF_TRANSSHIFT)
g(_G, "TR_TRANS30", tr_trans30<<FF_TRANSSHIFT)
g(_G, "TR_TRANS40", tr_trans40<<FF_TRANSSHIFT)
g(_G, "TR_TRANS50", tr_trans50<<FF_TRANSSHIFT)
g(_G, "TR_TRANS60", tr_trans60<<FF_TRANSSHIFT)
g(_G, "TR_TRANS70", tr_trans70<<FF_TRANSSHIFT)
g(_G, "TR_TRANS80", tr_trans80<<FF_TRANSSHIFT)
g(_G, "TR_TRANS90", tr_trans90<<FF_TRANSSHIFT)
g(_G, "tr_trans10", tr_trans10)
g(_G, "tr_trans20", tr_trans20)
g(_G, "tr_trans30", tr_trans30)
g(_G, "tr_trans40", tr_trans40)
g(_G, "tr_trans50", tr_trans50)
g(_G, "tr_trans60", tr_trans60)
g(_G, "tr_trans70", tr_trans70)
g(_G, "tr_trans80", tr_trans80)
g(_G, "tr_trans90", tr_trans90)

-- Angle stuff
g(_G, "ANG1", ANG1)
g(_G, "ANG2", ANG2)
g(_G, "ANG10", ANG10)
g(_G, "ANG15", ANG15)
g(_G, "ANG20", ANG20)
g(_G, "ANG30", ANG30)
g(_G, "ANG60", ANG60)
g(_G, "ANG64h", ANG64h)
g(_G, "ANG105", ANG105)
g(_G, "ANG210", ANG210)
g(_G, "ANG255", ANG255)
g(_G, "ANG340", ANG340)
g(_G, "ANG350", ANG350)

g(_G,"ANGLE_11hh", ANGLE_11hh)
g(_G,"ANGLE_22h", ANGLE_22h)
g(_G,"ANGLE_45", ANGLE_45)
g(_G,"ANGLE_67h", ANGLE_67h)
g(_G,"ANGLE_90", ANGLE_90)
g(_G,"ANGLE_112h", ANGLE_112h)
g(_G,"ANGLE_135", ANGLE_135)
g(_G,"ANGLE_157h", ANGLE_157h)
g(_G,"ANGLE_180", ANGLE_180)
g(_G,"ANGLE_202h", ANGLE_202h)
g(_G,"ANGLE_225", ANGLE_225)
g(_G,"ANGLE_247h", ANGLE_247h)
g(_G,"ANGLE_270", ANGLE_270)
g(_G,"ANGLE_292h", ANGLE_292h)
g(_G,"ANGLE_315", ANGLE_315)
g(_G,"ANGLE_337h", ANGLE_337h)
g(_G,"ANGLE_MAX", ANGLE_MAX)
g(_G,"DI_NODIR", DI_NODIR)
g(_G,"DI_EAST", DI_EAST)
g(_G,"DI_NORTHEAST", DI_NORTHEAST)
g(_G,"DI_NORTH", DI_NORTH)
g(_G,"DI_NORTHWEST", DI_NORTHWEST)
g(_G,"DI_WEST", DI_WEST)
g(_G,"DI_SOUTHWEST", DI_SOUTHWEST)
g(_G,"DI_SOUTH", DI_SOUTH)
g(_G,"DI_SOUTHEAST", DI_SOUTHEAST)
g(_G,"NUMDIRS", NUMDIRS)

-- Video flags
g(_G, "V_NOSCALEPATCH", V_NOSCALEPATCH)
g(_G, "V_SMALLSCALEPATCH", V_SMALLSCALEPATCH)
g(_G, "V_MEDSCALEPATCH", V_MEDSCALEPATCH)
g(_G, "V_6WIDTHSPACE", V_6WIDTHSPACE)
g(_G, "V_OLDSPACING", V_OLDSPACING)
g(_G, "V_MONOSPACE", V_MONOSPACE)
g(_G, "V_PURPLEMAP", V_PURPLEMAP)
g(_G, "V_YELLOWMAP", V_YELLOWMAP)
g(_G, "V_GREENMAP", V_GREENMAP)
g(_G, "V_BLUEMAP", V_BLUEMAP)
g(_G, "V_REDMAP", V_REDMAP)
g(_G, "V_GRAYMAP", V_GRAYMAP)
g(_G, "V_ORANGEMAP", V_ORANGEMAP)
g(_G, "V_SKYMAP", V_SKYMAP)
g(_G, "V_LAVENDERMAP", V_LAVENDERMAP)
g(_G, "V_GOLDMAP", V_GOLDMAP)
g(_G, "V_TEAMAP", V_TEAMAP)
g(_G, "V_STEELMAP", V_STEELMAP)
g(_G, "V_PINKMAP", V_PINKMAP)
g(_G, "V_BROWNMAP", V_BROWNMAP)
g(_G, "V_PEACHMAP", V_PEACHMAP)
g(_G, "V_TRANSLUCENT", V_TRANSLUCENT)
g(_G, "V_10TRANS", V_10TRANS)
g(_G, "V_20TRANS", V_20TRANS)
g(_G, "V_30TRANS", V_30TRANS)
g(_G, "V_40TRANS", V_40TRANS)
g(_G, "V_50TRANS", V_TRANSLUCENT)
g(_G, "V_60TRANS", V_60TRANS)
g(_G, "V_70TRANS", V_70TRANS)
g(_G, "V_80TRANS", V_80TRANS)
g(_G, "V_90TRANS", V_90TRANS)
g(_G, "V_HUDTRANSHALF", V_HUDTRANSHALF)
g(_G, "V_HUDTRANS", V_HUDTRANS)
g(_G, "V_AUTOFADEOUT", V_AUTOFADEOUT)
g(_G, "V_RETURN8", V_RETURN8)
g(_G, "V_ALLOWLOWERCASE", V_ALLOWLOWERCASE)
g(_G, "V_FLIP", V_FLIP)
g(_G, "V_SNAPTOTOP", V_SNAPTOTOP)
g(_G, "V_SNAPTOBOTTOM", V_SNAPTOBOTTOM)
g(_G, "V_SNAPTOLEFT", V_SNAPTOLEFT)
g(_G, "V_SNAPTORIGHT", V_SNAPTORIGHT)
g(_G, "V_NOSCALESTART", V_NOSCALESTART)
g(_G, "V_SPLITSCREEN", V_SPLITSCREEN)
g(_G, "V_HORZSCREEN", V_HORZSCREEN)
g(_G, "V_PARAMMASK", V_PARAMMASK)
g(_G, "V_SCALEPATCHMASK", V_SCALEPATCHMASK)
g(_G, "V_SPACINGMASK", V_SPACINGMASK)
g(_G, "V_CHARCOLORMASK", V_CHARCOLORMASK)
g(_G, "V_ALPHAMASK", V_ALPHAMASK)
g(_G, "V_CHARCOLORSHIFT", V_CHARCOLORSHIFT)
g(_G, "V_ALPHASHIFT", V_ALPHASHIFT)

-- Render flags
g(_G, "RF_HORIZONTALFLIP", RF_HORIZONTALFLIP)

-- Player Flags:
g(_G, "PF_FLIPCAM", PF_FLIPCAM)
g(_G, "PF_GODMODE", PF_GODMODE)
g(_G, "PF_NOCLIP", PF_NOCLIP)
g(_G, "PF_INVIS", PF_INVIS)
g(_G, "PF_ATTACKDOWN", PF_ATTACKDOWN)
g(_G, "PF_USEDOWN", PF_USEDOWN)
g(_G, "PF_JUMPDOWN", PF_JUMPDOWN)
g(_G, "PF_WPNDOWN", PF_WPNDOWN)
g(_G, "PF_STASIS", PF_STASIS)
g(_G, "PF_JUMPSTASIS", PF_JUMPSTASIS)
g(_G, "PF_TIMEOVER", PF_TIMEOVER)
g(_G, "PF_WANTSTOJOIN", PF_WANTSTOJOIN)
g(_G, "PF_JUMPED", PF_JUMPED)
g(_G, "PF_SPINNING", PF_SPINNING)
g(_G, "PF_STARTDASH", PF_STARTDASH)
g(_G, "PF_THOKKED", PF_THOKKED)
g(_G, "PF_GLIDING", PF_GLIDING)
g(_G, "PF_CARRIED", PF_CARRIED)
g(_G, "PF_SLIDING", PF_SLIDING)
g(_G, "PF_ROPEHANG", PF_ROPEHANG)
g(_G, "PF_ITEMHANG", PF_ITEMHANG)
g(_G, "PF_MACESPIN", PF_MACESPIN)
g(_G, "PF_NIGHTSMODE", PF_NIGHTSMODE)
g(_G, "PF_TRANSFERTOCLOSEST", PF_TRANSFERTOCLOSEST)
g(_G, "PF_NIGHTSFALL", PF_NIGHTSFALL)
g(_G, "PF_DRILLING", PF_DRILLING)
g(_G, "PF_SKIDDOWN", PF_SKIDDOWN)
g(_G, "PF_TAGGED", PF_TAGGED)
g(_G, "PF_TAGIT", PF_TAGIT)
g(_G, "PF_FORCESTRAFE", PF_FORCESTRAFE)
g(_G, "PF_ANALOGMODE", PF_ANALOGMODE)

-- Mobj Flags
g(_G, "MF_SPECIAL", MF_SPECIAL)
g(_G, "MF_SOLID", MF_SOLID)
g(_G, "MF_SHOOTABLE", MF_SHOOTABLE)
g(_G, "MF_NOSECTOR", MF_NOSECTOR)
g(_G, "MF_NOBLOCKMAP", MF_NOBLOCKMAP)
g(_G, "MF_PAPERCOLLISION", MF_PAPERCOLLISION)
g(_G, "MF_PUSHABLE", MF_PUSHABLE)
g(_G, "MF_BOSS", MF_BOSS)
g(_G, "MF_SPAWNCEILING", MF_SPAWNCEILING)
g(_G, "MF_NOGRAVITY", MF_NOGRAVITY)
g(_G, "MF_AMBIENT", MF_AMBIENT)
g(_G, "MF_SLIDEME", MF_SLIDEME)
g(_G, "MF_NOCLIP", MF_NOCLIP)
g(_G, "MF_FLOAT", MF_FLOAT)
g(_G, "MF_BOXICON", MF_BOXICON)
g(_G, "MF_MISSILE", MF_MISSILE)
g(_G, "MF_SPRING", MF_SPRING)
g(_G, "MF_BOUNCE", MF_BOUNCE)
g(_G, "MF_MONITOR", MF_MONITOR)
g(_G, "MF_NOTHINK", MF_NOTHINK)
g(_G, "MF_FIRE", MF_FIRE)
g(_G, "MF_NOCLIPHEIGHT", MF_NOCLIPHEIGHT)
g(_G, "MF_ENEMY", MF_ENEMY)
g(_G, "MF_SCENERY", MF_SCENERY)
g(_G, "MF_PAIN", MF_PAIN)
g(_G, "MF_STICKY", MF_STICKY)
g(_G, "MF_NIGHTSITEM", MF_NIGHTSITEM)
g(_G, "MF_NOCLIPTHING", MF_NOCLIPTHING)
g(_G, "MF_GRENADEBOUNCE", MF_GRENADEBOUNCE)
g(_G, "MF_RUNSPAWNFUNC", MF_RUNSPAWNFUNC)

-- Mobj Flags (2)
g(_G, "MF2_AXIS", MF2_AXIS)
g(_G, "MF2_TWOD", MF2_TWOD)
g(_G, "MF2_DONTRESPAWN", MF2_DONTRESPAWN)
g(_G, "MF2_DONTDRAW", MF2_DONTDRAW)
g(_G, "MF2_AUTOMATIC", MF2_AUTOMATIC)
g(_G, "MF2_RAILRING", MF2_RAILRING)
g(_G, "MF2_BOUNCERING", MF2_BOUNCERING)
g(_G, "MF2_EXPLOSION", MF2_EXPLOSION)
g(_G, "MF2_SCATTER", MF2_SCATTER)
g(_G, "MF2_BEYONDTHEGRAVE", MF2_BEYONDTHEGRAVE)
g(_G, "MF2_PUSHED", MF2_PUSHED)
g(_G, "MF2_SLIDEPUSH", MF2_SLIDEPUSH)
g(_G, "MF2_CLASSICPUSH", MF2_CLASSICPUSH)
g(_G, "MF2_STANDONME", MF2_STANDONME)
g(_G, "MF2_INFLOAT", MF2_INFLOAT)
g(_G, "MF2_DEBRIS", MF2_DEBRIS)
g(_G, "MF2_NIGHTSPULL", MF2_NIGHTSPULL)
g(_G, "MF2_JUSTATTACKED", MF2_JUSTATTACKED)
g(_G, "MF2_FIRING", MF2_FIRING)
g(_G, "MF2_SUPERFIRE", MF2_SUPERFIRE)
g(_G, "MF2_SHADOW", MF2_SHADOW)
g(_G, "MF2_STRONGBOX", MF2_STRONGBOX)
g(_G, "MF2_OBJECTFLIP", MF2_OBJECTFLIP)
g(_G, "MF2_SKULLFLY", MF2_SKULLFLY)
g(_G, "MF2_FRET", MF2_FRET)
g(_G, "MF2_BOSSNOTRAP", MF2_BOSSNOTRAP)
g(_G, "MF2_BOSSFLEE", MF2_BOSSFLEE)
g(_G, "MF2_BOSSDEAD", MF2_BOSSDEAD)
g(_G, "MF2_AMBUSH", MF2_AMBUSH)
g(_G, "MF2_LINKDRAW", MF2_LINKDRAW)
g(_G, "MF2_SHIELD", MF2_SHIELD)
g(_G, "MF2_SPLAT", MF2_SPLAT)

-- Mobj Extra Flags
g(_G, "MFE_ONGROUND", MFE_ONGROUND)
g(_G, "MFE_JUSTHITFLOOR", MFE_JUSTHITFLOOR)
g(_G, "MFE_TOUCHWATER", MFE_TOUCHWATER)
g(_G, "MFE_UNDERWATER", MFE_UNDERWATER)
g(_G, "MFE_JUSTSTEPPEDDOWN", MFE_JUSTSTEPPEDDOWN)
g(_G, "MFE_VERTICALFLIP", MFE_VERTICALFLIP)
g(_G, "MFE_GOOWATER", MFE_GOOWATER)
g(_G, "MFE_JUSTBOUNCEDWALL", MFE_JUSTBOUNCEDWALL)
g(_G, "MFE_SPRUNG", MFE_SPRUNG)
g(_G, "MFE_APPLYPMOMZ", MFE_APPLYPMOMZ)
g(_G, "MFE_TRACERANGLE", MFE_TRACERANGLE)

-- Character Abilities
g(_G,"CA_NONE", CA_NONE)
g(_G,"CA_THOK", CA_THOK)
g(_G,"CA_FLY", CA_FLY)
g(_G,"CA_GLIDEANDCLIMB", CA_GLIDEANDCLIMB)
g(_G,"CA_HOMINGTHOK", CA_HOMINGTHOK)
g(_G,"CA_DOUBLEJUMP", CA_DOUBLEJUMP)
g(_G,"CA_FLOAT", CA_FLOAT)
g(_G,"CA_SLOWFALL", CA_SLOWFALL)
g(_G,"CA_SWIM", CA_SWIM)
g(_G,"CA_TELEKINESIS", CA_TELEKINESIS)
g(_G,"CA_FALLSWITCH", CA_FALLSWITCH)
g(_G,"CA_JUMPBOOST", CA_JUMPBOOST)
g(_G,"CA_AIRDRILL", CA_AIRDRILL)
g(_G,"CA_JUMPTHOK", CA_JUMPTHOK)
g(_G,"CA_BOUNCE", CA_BOUNCE)
g(_G,"CA_TWINSPIN", CA_TWINSPIN)
g(_G,"CA2_NONE", CA2_NONE)
g(_G,"CA2_SPINDASH", CA2_SPINDASH)
g(_G,"CA2_GUNSLINGER", CA2_GUNSLINGER)
g(_G,"CA2_MELEE", CA2_MELEE)

-- Buttons
g(_G, "BT_WEAPONMASK", BT_WEAPONMASK)
g(_G, "BT_WEAPONNEXT", BT_WEAPONNEXT)
g(_G, "BT_WEAPONPREV", BT_WEAPONPREV)
g(_G, "BT_ATTACK", BT_ATTACK)
g(_G, "BT_SPIN", BT_SPIN)
g(_G, "BT_CAMLEFT", BT_CAMLEFT)
g(_G, "BT_CAMRIGHT", BT_CAMRIGHT)
g(_G, "BT_TOSSFLAG", BT_TOSSFLAG)
g(_G, "BT_JUMP", BT_JUMP)
g(_G, "BT_USE", BT_USE)
g(_G, "BT_FIRENORMAL", BT_FIRENORMAL)
g(_G, "BT_CUSTOM1", BT_CUSTOM1)
g(_G, "BT_CUSTOM2", BT_CUSTOM2)
g(_G, "BT_CUSTOM3", BT_CUSTOM3)

-- Translation Colormaps
g(_G, "TC_DEFAULT", TC_DEFAULT)
g(_G, "TC_BOSS", TC_BOSS)
g(_G, "TC_METALSONIC", TC_METALSONIC)
g(_G, "TC_ALLWHITE", TC_ALLWHITE)
g(_G, "TC_RAINBOW", TC_RAINBOW)
g(_G, "TC_BLINK", TC_BLINK)


-- Skincolours
g(_G, "SKINCOLOR_NONE", SKINCOLOR_NONE)
g(_G, "SKINCOLOR_WHITE", SKINCOLOR_WHITE)
g(_G, "SKINCOLOR_BONE", SKINCOLOR_BONE)
g(_G, "SKINCOLOR_CLOUDY", SKINCOLOR_CLOUDY)
g(_G, "SKINCOLOR_SILVER", SKINCOLOR_SILVER)
g(_G, "SKINCOLOR_CARBON", SKINCOLOR_CARBON)
g(_G, "SKINCOLOR_JET", SKINCOLOR_JET)
g(_G, "SKINCOLOR_BLACK", SKINCOLOR_BLACK)
g(_G, "SKINCOLOR_AETHER", SKINCOLOR_AETHER)
g(_G, "SKINCOLOR_SLATE", SKINCOLOR_SLATE)
g(_G, "SKINCOLOR_BLUEBELL", SKINCOLOR_BLUEBELL)
g(_G, "SKINCOLOR_PINK", SKINCOLOR_PINK)
g(_G, "SKINCOLOR_YOGURT", SKINCOLOR_YOGURT)
g(_G, "SKINCOLOR_BROWN", SKINCOLOR_BROWN)
g(_G, "SKINCOLOR_BRONZE", SKINCOLOR_BRONZE)
g(_G, "SKINCOLOR_TAN", SKINCOLOR_TAN)
g(_G, "SKINCOLOR_BEIGE", SKINCOLOR_BEIGE)
g(_G, "SKINCOLOR_MOSS", SKINCOLOR_MOSS)
g(_G, "SKINCOLOR_AZURE", SKINCOLOR_AZURE)
g(_G, "SKINCOLOR_LAVENDER", SKINCOLOR_LAVENDER)
g(_G, "SKINCOLOR_RUBY", SKINCOLOR_RUBY)
g(_G, "SKINCOLOR_SALMON", SKINCOLOR_SALMON)
g(_G, "SKINCOLOR_RED", SKINCOLOR_RED)
g(_G, "SKINCOLOR_CRIMSON", SKINCOLOR_CRIMSON)
g(_G, "SKINCOLOR_FLAME", SKINCOLOR_FLAME)
g(_G, "SKINCOLOR_KETCHUP", SKINCOLOR_KETCHUP)
g(_G, "SKINCOLOR_PEACHY", SKINCOLOR_PEACHY)
g(_G, "SKINCOLOR_QUAIL", SKINCOLOR_QUAIL)
g(_G, "SKINCOLOR_SUNSET", SKINCOLOR_SUNSET)
g(_G, "SKINCOLOR_COPPER", SKINCOLOR_COPPER)
g(_G, "SKINCOLOR_APRICOT", SKINCOLOR_APRICOT)
g(_G, "SKINCOLOR_ORANGE", SKINCOLOR_ORANGE)
g(_G, "SKINCOLOR_RUST", SKINCOLOR_RUST)
g(_G, "SKINCOLOR_GOLD", SKINCOLOR_GOLD)
g(_G, "SKINCOLOR_SANDY", SKINCOLOR_SANDY)
g(_G, "SKINCOLOR_YELLOW", SKINCOLOR_YELLOW)
g(_G, "SKINCOLOR_OLIVE", SKINCOLOR_OLIVE)
g(_G, "SKINCOLOR_LIME", SKINCOLOR_LIME)
g(_G, "SKINCOLOR_PERIDOT", SKINCOLOR_PERIDOT)
g(_G, "SKINCOLOR_APPLE", SKINCOLOR_APPLE)
g(_G, "SKINCOLOR_GREEN", SKINCOLOR_GREEN)
g(_G, "SKINCOLOR_FOREST", SKINCOLOR_FOREST)
g(_G, "SKINCOLOR_EMERALD", SKINCOLOR_EMERALD)
g(_G, "SKINCOLOR_MINT", SKINCOLOR_MINT)
g(_G, "SKINCOLOR_SEAFOAM", SKINCOLOR_SEAFOAM)
g(_G, "SKINCOLOR_AQUA", SKINCOLOR_AQUA)
g(_G, "SKINCOLOR_TEAL", SKINCOLOR_TEAL)
g(_G, "SKINCOLOR_WAVE", SKINCOLOR_WAVE)
g(_G, "SKINCOLOR_CYAN", SKINCOLOR_CYAN)
g(_G, "SKINCOLOR_SKY", SKINCOLOR_SKY)
g(_G, "SKINCOLOR_CRULEAN", SKINCOLOR_CERULEAN)
g(_G, "SKINCOLOR_ICY", SKINCOLOR_ICY)
g(_G, "SKINCOLOR_SAPPHIRE", SKINCOLOR_SAPPHIRE)
g(_G, "SKINCOLOR_CORNFLOWER", SKINCOLOR_CORNFLOWER)
g(_G, "SKINCOLOR_BLUE", SKINCOLOR_BLUE)
g(_G, "SKINCOLOR_COBALT", SKINCOLOR_COBALT)
g(_G, "SKINCOLOR_VAPOR", SKINCOLOR_VAPOR)
g(_G, "SKINCOLOR_DUSK", SKINCOLOR_DUSK)
g(_G, "SKINCOLOR_PASTEL", SKINCOLOR_PASTEL)
g(_G, "SKINCOLOR_PURPLE", SKINCOLOR_PURPLE)
g(_G, "SKINCOLOR_BUBBLEGUM", SKINCOLOR_BUBBLEGUM)
g(_G, "SKINCOLOR_MAGENTA", SKINCOLOR_MAGENTA)
g(_G, "SKINCOLOR_NEON", SKINCOLOR_NEON)
g(_G, "SKINCOLOR_VIOLET", SKINCOLOR_VIOLET)
g(_G, "SKINCOLOR_LILAC", SKINCOLOR_LILAC)
g(_G, "SKINCOLOR_PLUM", SKINCOLOR_PLUM)
g(_G, "SKINCOLOR_RASPBERRY", SKINCOLOR_RASPBERRY)
g(_G, "SKINCOLOR_ROSY", SKINCOLOR_ROSY)