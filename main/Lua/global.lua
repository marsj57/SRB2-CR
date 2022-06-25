-- Hey, you're awfully nosy aren't you?
-- Just so you know, a lot of what you see here is mixed between original code
-- and code that I've gotten permission to use.
--
-- A word of warning: YOU SHOULD ASSUME __NONE__ OF THE CODE HERE IS REUSABLE.
-- GET PERMISSION TO USE THIS STUFF BEFORE YOU USE IT YOURSELF
--
-- Flame

rawset(_G, "FLCR", {}) -- Flame's Custom Robo
FLCR.PlayerData = {}
FLCR.Weapons = {} -- Weapons table
FLCR.CameraBattleAngle = 0

rawset(_G, "valid", function(th)
	return th and th.valid
end)

rawset(_G, "createFlags", function(tname, t)
    for i = 1,#t do
		rawset(_G, t[i], 2^(i-1))
		table.insert(tname, {string = t[i], value = 2^(i-1)} )
    end
end)

rawset(_G, "createEnum", function(tname, t, from)
    if from == nil then from = 0 end
    for i = 1,#t do
		rawset(_G, t[i], from+(i-1))
		table.insert(tname, {string = t[i], value = from+(i-1)} )
    end
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
		if pcall(CheckSlot, item)
			print("\131NOTICE:\128 " .. item .. " was not allocated, as it already exists.")
		else
			freeslot(item)
		end
	end
end)
-- End Lach

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