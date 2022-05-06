-- Hey, you're awfully nosy aren't you?
-- Just so you know, a lot of what you see here is mixed between original code
-- and code that I've gotten permission to use.
--
-- A word of warning: YOU SHOULD ASSUME __NONE__ OF THE CODE HERE IS REUSABLE.
-- GET PERMISSION TO USE THIS STUFF BEFORE YOU USE IT YOURSELF
--
-- Flame

-- Some funny splat thing I was thinking on doing
/*addHook("PlayerThink", function(p)
	if not valid(p) then return end
	if not valid(p.mo) then return end
	local mo = p.mo
	
	if not p.splat then
		local s = P_SpawnMobj(mo.x, mo.y, mo.z, MT_DUMMY)
		s.state = S_THOK
		s.tics = -1 -- Special S_THOK state thing. Don't make this disappear.
		s.angle = mo.angle
		s.color = mo.color
		s.target = mo
		P_CreateFloorSpriteSlope(s)
		s.flags2 = $ | MF2_SPLAT
		s.renderflags = $ | RF_FLOORSPRITE | RF_SLOPESPLAT | RF_NOSPLATBILLBOARD
		s.floorspriteslope.o = { x = mo.x, y = mo.y, z = mo.z }
		s.floorspriteslope.xydirection = s.angle
		s.floorspriteslope.zangle = 0

		p.splat = s
		print("splat created!")
	end
end)

addHook("MobjThinker", function(mo)
	if valid(mo.target) then
		local target = mo.target
		mo.color = target.color or SKINCOLOR_GREEN
		mo.floorspriteslope.o = { x = target.x, 
									y = target.y, 
									z = target.z
									}
		mo.angle = target.angle
		mo.floorspriteslope.xydirection = target.angle
		--P_TeleportMove(mo, target.x, target.y, target.z)
		P_TeleportMove(mo, target.x - FixedMul(cos(target.angle), 3*mo.height/4), 
							target.y - FixedMul(sin(target.angle), 3*mo.height/4), 
							target.z)
	else
		P_RemoveMobj(mo)
	end
end, MT_DUMMY)*/

addHook("PlayerSpawn", function(p)
	if not valid(p) then return false end
	if not valid(p.mo) then return false end
	local mo = p.mo
	
	if not mo.outline then
		local o = P_SpawnMobj(mo.x, mo.y, mo.z, MT_DUMMY)
		o.state = S_THOK
		o.angle = mo.angle
		o.target = mo
		o.skin = p.mo.skin
		o.tics = -1 -- Special S_THOK state thing. Don't make this disappear.
		mo.outline = o
	end
	
	-- Camera mobj. Not using camera_t.
	if not p.awayviewmobj and (gametype == GT_MATCH) then
		local o = P_SpawnMobj(mo.x, mo.y, mo.z, MT_DUMMY)
		o.state = S_THOK
		o.angle = mo.angle
		o.flags2 = $ | MF2_DONTDRAW
		o.tics = -1
		o.target = mo
		p.awayviewmobj = o
		p.awayviewtics = 2
	end
	
	p.pflags = $ | PF_ANALOGMODE
	--CV_Set(CV_FindVar("chasecam"), 1)
	camera.chase = true
	p.rings = 50
end, MT_PLAYER)