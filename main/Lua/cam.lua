-- Hey, you're awfully nosy aren't you?
-- Just so you know, a lot of what you see here is mixed between original code
-- and code that I've gotten permission to use.
--
-- A word of warning: YOU SHOULD ASSUME __NONE__ OF THE CODE HERE IS REUSABLE.
-- GET PERMISSION TO USE THIS STUFF BEFORE YOU USE IT YOURSELF
--
-- Flame

addHook("MapLoad", function(mapnum)
	ABSOLUTE_ANGLE = 0
end)

addHook("PostThinkFrame", do
	if (gametype ~= GT_MATCH) then return end
	ABSOLUTE_ANGLE = $+ANG1/2
	local totalPlayers = {} -- Self explainitory
	for p in players.iterate
		if not valid(p.mo) or p.spectator then continue end
		table.insert(totalPlayers, p.mo) -- Insert every player's mo into the above table
	end
	
	if not #totalPlayers then return end
	
	local cv = {
				height = CV_FindVar("cam_height").value,
				dist = CV_FindVar("cam_dist").value
				}
	
	-- Get our center x, y, and z coordinates
	local center = {
						x = 0,
						y = 0,
						z = 0
					}
	for _,v in ipairs(totalPlayers)
		if valid(v) then
			center.x = $+(v.x/#totalPlayers) -- Our center x
			center.y = $+(v.y/#totalPlayers) -- Our center y
			center.z = $+(v.z/#totalPlayers)+(FixedMul(v.scale, (mobjinfo[v.type].height * P_MobjFlip(v)))/#totalPlayers) -- Our center z
		end
	end
	
	-- Get the furthest player from the center
	local temp = 0 -- Temp value
	local furthest = {
						--x = {nil, 0},
						--y = {nil, 0},
						z = {nil, 0},
						d = {nil, 0}
					}
	for _,v in ipairs(totalPlayers)
		temp = R_PointToDist2(v.x, v.y, center.x, center.y)
		if (temp > furthest.d[2]) then
			furthest.d = {v, temp}
		end
		/*temp = abs(v.x - center.x)
		if (temp > furthest.x[2]) then
			furthest.x = {v, temp}
		end
		
		temp = abs(v.y - center.y)
		if (temp > furthest.y[2]) then
			furthest.y = {v, temp}
		end*/
		
		temp = abs(v.z + FixedMul(v.scale, (mobjinfo[v.type].height * P_MobjFlip(v))) - center.z)
		if (temp > furthest.z[2]) then
			furthest.z = {v, temp}
		end
	end

	-- Set these coordinates...
	local new = {
				x = center.x - FixedMul(cos(ABSOLUTE_ANGLE), furthest.d[2]) - FixedMul(cos(ABSOLUTE_ANGLE), cv.dist),
				y = center.y - FixedMul(sin(ABSOLUTE_ANGLE), furthest.d[2]) - FixedMul(sin(ABSOLUTE_ANGLE), cv.dist),
				z = center.z + cv.height --+ furthest.d[2]/3
			}

	/*if (#totalPlayers > 1) and (players[0].cmd.buttons & BT_CUSTOM1) then 
		print(string.format("FurthestZ Name: %3s | FurthestZ Dist: %3s", furthest.d[1].player.name or "nil", furthest.d[2]>>FRACBITS))
	end
	
	local debug = { 
				center = P_SpawnMobj(center.x, center.y, center.z, MT_THOK),
				centeroffs = P_SpawnMobj(new.x, new.y, new.z, MT_THOK)
				}
	debug.center.color = SKINCOLOR_RED
	debug.center.tics = 1
	debug.centeroffs.color = SKINCOLOR_BLUE
	debug.centeroffs.destscale = FRACUNIT/16*/

	-- And move!
	local factor = 8
	local zoomMax = 3*RING_DIST
	local zoomPercent = (furthest.d[2] >= zoomMax) and FRACUNIT or FixedDiv(furthest.d[2] + furthest.z[2]*3, zoomMax)
	local zoom = ease.linear(zoomPercent, 10, 100)<<FRACBITS
	for p in players.iterate -- Since everybody has their own awayviewmobj...
		if not valid(p.awayviewmobj) then continue end
		local cam = p.awayviewmobj -- Not using the exposed camera_t because the exposed camera_t likes to angle itself to the consoleplayer.

		-- Ease towards destination
		P_TeleportMove(cam,
						cam.x + (new.x - cam.x)/factor - FixedMul(cos(ABSOLUTE_ANGLE), zoom),
						cam.y + (new.y - cam.y)/factor - FixedMul(sin(ABSOLUTE_ANGLE), zoom),
						cam.z + (new.z - cam.z)/factor + zoom)
		
		-- Face the center
		cam.angle = R_PointToAngle2(cam.x, cam.y, center.x, center.y)
		
		-- Aiming math towards the center
		local dist = R_PointToDist2(cam.x, cam.y, center.x, center.y)
		local hdist = (cam.z - center.z) --R_PointToDist2(0, cam.z, dist, center.z) --(cam.z - center.z)
		-- Aim towards the center
		p.awayviewaiming = R_PointToAngle2(0, 0, dist, -hdist) - ANG2
		
		-- Actual camera teleporting. Not used except to reference in our hud function.
		P_TeleportCameraMove(camera,cam.x,cam.y,cam.z)
		camera.angle = cam.angle
		camera.aiming = p.awayviewaiming
	end
end)

hud.add(function(v,p,c)
	--if not valid(v) then return end
	if not valid(p) then return end
	if not p.awayviewmobj or p.spectator then return end
	--if not valid(p.mo) then return end
	--if not valid(c) then return end
	for m in mobjs.iterate()
		if not valid(m) then continue end
		if (m.health <= 0)
		or (m.player and (m.player.playerstate == PST_DEAD)) then continue end
		if (m.flags2 & MF2_DONTDRAW) then continue end
		if P_CheckSight(p.awayviewmobj, m) then continue end
		R_ProjectSprite(v, m, c)
	end
end, "game")

addHook("NetVars", function(n)
	ABSOLUTE_ANGLE = n($)
end)