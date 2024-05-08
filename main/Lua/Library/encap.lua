-- My attempt at translating Unity's bounds encapsulation to Lua
-- From: https://github.com/Unity-Technologies/UnityCsReference/tree/master/Runtime/Export/Geometry
--
-- Flame

local mt = {}
local mt2 = {}
-- setters
function mt.__newindex( self, index, value )
	if type(value) ~= 'string' then error(index .. " cannot be assigned to") end
	if index == 'center' then
		self.setCenter(value)
	elseif index == 'size' then
		self.setSize(value)
	elseif index == 'extents' then
		self.setExtents(value)
	elseif index == 'min' then
		local tmp = self.min
		self.setMin(tmp, value)
	elseif index == 'max' then
		local tmp = self.max
		self.setMax(value, tmp)
	elseif index == 'encapsulate' then
		self.encapsulate(value)
	elseif index == 'expand' then
		self.expand(value)
	else
		rawset( self, index, value )
	end
end

-------------------------------------------------------
-- getters
function mt.__index( self, index )
	if index == 'center' then
		return self.getCenter()
	elseif index == 'size' then
		return self.getSize()
	elseif index == 'extents' then
		return self.getExtents()
	elseif index == 'min' then
		return (self.getCenter() - self.getExtents())
	elseif index == 'max' then
		return (self.getCenter() + self.getExtents())
	else
		return rawget( self, index )
	end
end
-------------------------------------------------------
-- math
function mt2.__add(a, b)
	local aIsTable = (type(a) == "table")
	local bIsTable = (type(b) == "table")
	if aIsTable and bIsTable then
		return setmetatable({x = a.x + b.x, y = a.y + b.y, z = a.z + b.z}, mt2)
	elseif (bIsTable) then
		-- check for custom type
		local t = type(a)
		if t == "number" then
			return setmetatable({x = a + b.x, y = a + b.y, z = a + b.z}, mt2)
		else
			error("bad argument #1 to '?' (table expected, got " .. t .. ")")
		end
	elseif (aIsTable) then
		local t = type(b)
		if t == "number" then
			return setmetatable({x = a.x + b, y = a.y + b, z = a.z + b}, mt2)
		else
			error("bad argument #2 to '?' (table expected, got " .. t .. ")")
		end
	end
end

function mt2.__sub(a, b)
	local aIsTable = (type(a) == "table")
	local bIsTable = (type(b) == "table")
	if aIsTable and bIsTable then
		return setmetatable({x = a.x - b.x, y = a.y - b.y, z = a.z - b.z}, mt2)
	elseif (bIsTable) then
		-- check for custom type
		local t = type(a)
		if t == "number" then
			return setmetatable({x = a - b.x, y = a - b.y, z = a - b.z}, mt2)
		else
			error("bad argument #1 to '?' (table expected, got " .. t .. ")")
		end
	elseif (aIsTable) then
		-- check for custom type
		local t = type(b)
		if t == "number" then
			return setmetatable({x = a.x - b, y = a.y - b, z = a.z - b}, mt2)
		else
			error("bad argument #2 to '?' (table expected, got " .. t .. ")")
		end
	end
end

function mt2.__mul(a, b)
	local aIsTable = (type(a) == "table")
	local bIsTable = (type(b) == "table")
	if aIsTable and bIsTable then
		return setmetatable({x = FixedMul(a.x, b.x), y = FixedMul(a.y, b.y), z = FixedMul(a.z, b.z)}, mt2)
	elseif (bIsTable) then
		-- check for custom type
		local t = type(a)
		if t == "number" then
			return setmetatable({x = FixedMul(a, b.x), y = FixedMul(a, b.y), z = FixedMul(a, b.z)}, mt2)
		else
			error("bad argument #1 to '?' (table expected, got " .. t .. ")")
		end
	elseif (aIsTable) then
		-- check for custom type
		local t = type(b)
		if t == "number" then
			return setmetatable({x = FixedMul(a.x, b), y = FixedMul(a.y, b), z = FixedMul(a.z, b)}, mt2)
		else
			error("bad argument #2 to '?' (table expected, got " .. t .. ")")
		end
	end
end

function mt2.__div(a, b)
	local aIsTable = (type(a) == "table")
	local bIsTable = (type(b) == "table")
	if aIsTable and bIsTable then
		return setmetatable({x = FixedDiv(a.x, b.x), y = FixedDiv(a.y, b.y), z = FixedDiv(a.z, b.z)}, mt2)
	elseif (bIsTable) then
		-- check for custom type
		local t = type(a)
		if t == "number" then
			return setmetatable({x = FixedDiv(a, b.x), y = FixedDiv(a, b.y), z = FixedDiv(a, b.z)}, mt2)
		else
			error("bad argument #1 to '?' (table expected, got " .. t .. ")")
		end
	elseif (aIsTable) then
		-- check for custom type
		local t = type(b)
		if t == "number" then
			return setmetatable({x = FixedDiv(a.x, b), y = FixedDiv(a.y, b), z = FixedDiv(a.z, b)}, mt2)
		else
			error("bad argument #2 to '?' (table expected, got " .. t .. ")")
		end
	end
end
-------------------------------------------------------
-- other funcs
local point = {}
function point.max(lhs, rhs)
	return setmetatable({ x = max(lhs.x, rhs.x), y = max(lhs.y, rhs.y), z = max(lhs.z, rhs.z) }, mt2)
end

function point.min(lhs, rhs)
	return setmetatable({ x = min(lhs.x, rhs.x), y = min(lhs.y, rhs.y), z = min(lhs.z, rhs.z) }, mt2)
end
-------------------------------------------------------
-- stringy
function mt2.__tostring(v)
	if type(v) ~= "table" then return error("bad argument #1 to '?' (table expected, got " .. type(v) .. ")") end
	return v.x/FRACUNIT .. ", " .. v.y/FRACUNIT .. ", " .. v.z/FRACUNIT
end
-------------------------------------------------------

rawset(_G, "Bounds", {})
function Bounds.new(center, size)
	-- Creates new Bounds with a given center and total size. 
	-- Extents will be half the given size.
	local isTable = type(center) == "table"
	if not isTable then 
		error("bad argument #1 to '?' (table expected, got " .. type(center) .. ")")
	end
	local m_Center = setmetatable(center, mt2)
	local m_Extents = setmetatable(size, mt2) * (FRACUNIT/2)
	
	-- setMinMax
	-- Sets the bounds to the *min and *max value of the box.
	local function setMinMax(mini, maxi)
		m_Extents = (maxi - mini) * (FRACUNIT/2)
		m_Center = mini + m_Extents
	end

	local object = {
		-- Center
		-- The center of the bounding box.
		getCenter = function()
			return m_Center
		end,
		setCenter = function(val)
			m_Center = setmetatable(val, mt2)
		end,

		-- Size
		-- The total size of the box.
		-- This is always twice as large as self.extents.
		getSize = function()
			return m_Extents * (2*FRACUNIT)
		end,
		setSize = function(val)
			m_Extents = setmetatable(val, mt2) * (FRACUNIT/2)
		end,

		-- Extents
		-- The extents of the box.
		-- This is always half of self.size.
		getExtents = function()
			return m_Extents
		end,
		setExtents = function(val)
			m_Extents = setmetatable(val, mt2)
		end,

		-- The minimal point of the box. This is always equal to 'center-extents'.
		setMin = function(val, maxi)
			setmetatable(val, mt2)
			setMinMax(val,maxi)
		end,
		-- The maximal point of the box. This is always equal to 'center+extents'.
		setMax = function(mini, val)
			setmetatable(val, mt2)
			setMinMax(mini,val)
		end,

		-- encapsulate
		-- Grows the Bounds to include the *point.
		encapsulate = function(p)
			setmetatable(p, mt2)
			local mini = m_Center - m_Extents
			local maxi = m_Center + m_Extents
			setMinMax(point.min(mini, p), point.max(maxi, p))
		end,

		-- expand
		-- Expand the bounds by increasing its size by amt along each side.
		expand = function(amt)
			amt = $ * (FRACUNIT/2)
			m_Extents = $ + setmetatable({x=amt, y=amt, z=amt}, mt2)
		end,
	}
	return setmetatable(object, mt)
end

local bound = Bounds.new({x=0,y=0,z=0}, {x=100*FRACUNIT, y=100*FRACUNIT, z=100*FRACUNIT})
print(bound.center) -- 0,0,0 table, as a string
print(bound.size) -- 100,100,100
print(bound.extents) -- 50,50,50
print(bound.min) -- -50,-50,-50
print(bound.max) -- 50,50,50
--bound.expand(39) -- 69 (39/2 = 19.5 rounded down)
--print(bound.extents) -- 69, 69, 69

print("Encapsulate point -100,-100,-100:")
bound.encapsulate({x=-100*FRACUNIT,y=-100*FRACUNIT,z=-100*FRACUNIT})
print(bound.center) -- -25,-25,-25
print(bound.size) -- 150, 150, 150
print(bound.extents) -- 75, 75, 75
print(bound.min) -- -100,-100,-100
print(bound.max) -- 50,50,50

/*for k,v in pairs(bound) do 
    print(k,v) --> get function: ...
               --> set function: ...
end*/