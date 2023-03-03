-- Hey, you're awfully nosy aren't you?
-- Just so you know, a lot of what you see here is mixed between original code
-- and code that I've gotten permission to use.
--
-- A word of warning: YOU SHOULD ASSUME __NONE__ OF THE CODE HERE IS REUSABLE.
-- GET PERMISSION TO USE THIS STUFF BEFORE YOU USE IT YOURSELF
--
-- Flame

rawset(_G, "FLCR", {}) -- Flame's Custom Robo
rawset(_G, "FLCRLib", {}) -- Flame's Custom Robo Library
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