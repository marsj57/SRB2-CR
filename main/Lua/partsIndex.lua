-- Hey, you're awfully nosy aren't you?
-- Just so you know, a lot of what you see here is mixed between original code
-- and code that I've gotten permission to use.
--
-- A word of warning: YOU SHOULD ASSUME __NONE__ OF THE CODE HERE IS REUSABLE.
-- GET PERMISSION TO USE THIS STUFF BEFORE YOU USE IT YOURSELF
--
-- Flame

local Lib = FLCRLib

-- Bullet thinker code
addHook("MobjThinker", function(mo)
	if not valid(mo.target) then return false end
	if not mo.thinkfunc then return false end
	mo.thinkfunc(mo)
	return false
end)


-- Guns
FLCR.AddWeapon({
	name = "basic",
	desc = "A training gun that fires 3 rounds straight ahead. It's for absolute beginners. The rounds are weaker at greater distances.",
	mt = MT_DUMMYMISSILE,
	spawnsound = sfx_basic,
	parttype = CRPT_GUN,
	spawnfunc = function(p, w)
		if not valid(p) then return end
		if not p.crplayerdata then return end
		local CRPD = FLCR.PlayerData[p.crplayerdata.id]
		if not valid(CRPD.player) then return end
		if not valid(p.mo) then return end
		local mo = p.mo

		local multifireinterval = TICRATE/4 -- Multishot interval
		local maxrounds = 3 -- How many rounds can your weapon fire per-clip?
		if (CRPD.firetics%multifireinterval) -- Modulo by your weapon's firedelay, a non zero number?
		or (CRPD.firemaxrounds >= maxrounds)
			return
		elseif not CRPD.firetics then
			CRPD.firetype = w.parttype
			CRPD.firetics = (multifireinterval * maxrounds)*2 -- 26.5
			p.powers[pw_nocontrol] = CRPD.firetics - 3*(w.reload) -- -12 = 14.5
		end

		-- Let's spawn the bullet!
		local xyangle = mo.target and R_PointToAngle2(mo.x, mo.y, mo.target.x, mo.target.y) or p.drawangle
		local zangle = p.aiming
		local th = Lib.spawnCRMissile(mo, w, xyangle, zangle)
		if valid(th) then
			th.thinkfunc = w.thinkfunc
			th.damage = w.attack * 8 -- 32
			th.knockdown = 24
			th.state = S_RRNG1
			th.color = SKINCOLOR_YELLOW
			th.fuse = 3*TICRATE
			if mo.target then th.tracer = mo.target end
		end
		CRPD.firemaxrounds = $ + 1
	end,
	
	thinkfunc = function(mo)
		if not valid(mo) then return end
		if (mo.state == mo.info.deathstate) then return end
		-- Interpolate fx graphics towards prev position
		if mo.prev then
			for i = 1, 5 do
				local x = ease.linear(i*FRACUNIT/5, mo.prev.x, mo.x)
				local y = ease.linear(i*FRACUNIT/5, mo.prev.y, mo.y)
				local z = ease.linear(i*FRACUNIT/5, mo.prev.z, mo.z)
				
				local fx = P_SpawnMobj(x,y,z-(mobjinfo[mo.type].height/3),MT_DUMMYFX)
				fx.state = S_THOK
				--fx.scale = mo.scale
				fx.scale = ease.linear(i*FRACUNIT/5, mo.prev.scale, mo.scale)
				fx.destscale = 1
				fx.scalespeed = FRACUNIT/5
				fx.color = mo.color
				fx.frame = $|FF_TRANS70
				fx.blendmode = AST_ADD
			end
		end
		
		local factor = 80
		mo.momx = $ - $/factor
		mo.momy = $ - $/factor
		mo.momz = $ - $/factor
		if valid(mo.tracer) then
			local t = mo.tracer
			local angle = R_PointToAngle2(mo.x, mo.y, t.x, t.y)
			P_Thrust(mo, angle, FRACUNIT/factor)
		end
		
		mo.prev = {
			x = mo.x,
			y = mo.y,
			z = mo.z,
			scale = mo.scale - FRACUNIT/5 -- scalespeed
		}
	end,

	attack = 4,
	speed = 5,
	homing = 2,
	reload = 4,
	down = 6,
})

FLCR.AddWeapon({
	name = "3way", 
	desc = "Fires 3 straight rounds in 3 rows. The farther you are from the enemy, the better its homing.",
	mt = MT_DUMMYMISSILE,
	spawnsound = sfx_3way,
	parttype = CRPT_GUN,
	spawnfunc = function(p, w)
		if not valid(p) then return end
		if not p.crplayerdata then return end
		local CRPD = FLCR.PlayerData[p.crplayerdata.id]
		if not valid(CRPD.player) then return end
		if not valid(p.mo) then return end
		local mo = p.mo

		local multifireinterval = TICRATE/7 -- Multishot interval
		local maxrounds = 3 -- How many rounds can your weapon fire per-clip?
		if (CRPD.firetics%multifireinterval) -- Modulo by your weapon's firedelay, a non zero number?
		or (CRPD.firemaxrounds >= maxrounds)
			return
		elseif not CRPD.firetics then
			CRPD.firetype = w.parttype
			CRPD.firetics = (multifireinterval * maxrounds)*3
			p.powers[pw_nocontrol] = CRPD.firetics - 2*(w.reload)
		end
		
		-- Let's spawn the bullets!
		for i = -1, 1, 1 do
			local xyangle = mo.target and R_PointToAngle2(mo.x, mo.y, mo.target.x, mo.target.y) or p.drawangle
			local zangle = p.aiming
			local offset = i*(70*FRACUNIT) -- XY offset
			-- Spawn the reference x,y,z object.
			local ref = P_SpawnMobjFromMobj(mo, FixedMul(cos(xyangle), FixedMul(cos(zangle), 4*mo.radius/2)) 
												+ FixedMul(cos(xyangle+ANGLE_90), offset)
												- FixedMul(cos(xyangle), FixedMul(cos(zangle), i*offset/2)),
												FixedMul(sin(xyangle), FixedMul(cos(zangle), 4*mo.radius/2)) 
												+ FixedMul(sin(xyangle+ANGLE_90), offset)
												- FixedMul(sin(xyangle), FixedMul(cos(zangle), i*offset/2)),
												FixedMul(sin(zangle), mo.height)
												- FixedMul(sin(zangle), abs(i)*(mo.height/2)),
												MT_DUMMY)
			-- Spawn the missile from the reference object
			local th = Lib.spawnCRMissile(ref, w, xyangle, zangle, MF_NOCLIPTHING)
			P_RemoveMobj(ref) -- We're done with our reference object here
			S_StartSoundAtVolume(mo, w.spawnsound, 192) -- Because our ref object disappears
			if valid(th) then
				th.target = mo
				th.extravalue1 = i
				th.thinkfunc = w.thinkfunc
				th.damage = w.attack * 8 -- 32
				th.knockdown = 24
				th.state = S_RRNG1
				th.color = SKINCOLOR_YELLOW
				th.fuse = 3*TICRATE
			end
		end
		CRPD.firemaxrounds = $ + 1
	end,
	
	thinkfunc = function(mo)
		if not valid(mo) then return end
		if (mo.state == mo.info.deathstate) then return end
		-- Interpolate fx graphics towards prev position
		if mo.prev then
			for i = 1, 5 do
				local x = ease.linear(i*FRACUNIT/5, mo.prev.x, mo.x)
				local y = ease.linear(i*FRACUNIT/5, mo.prev.y, mo.y)
				local z = ease.linear(i*FRACUNIT/5, mo.prev.z, mo.z)
				
				local fx = P_SpawnMobj(x,y,z-(mobjinfo[mo.type].height/3),MT_DUMMYFX)
				fx.state = S_THOK
				--fx.scale = mo.scale
				fx.scale = ease.linear(i*FRACUNIT/5, mo.prev.scale, mo.scale)
				fx.destscale = 1
				fx.scalespeed = FRACUNIT/5
				fx.color = mo.color
				fx.frame = $|FF_TRANS70
				fx.blendmode = AST_ADD
			end
		end
		mo.prev = {
			x = mo.x,
			y = mo.y,
			z = mo.z,
			scale = mo.scale - FRACUNIT/5 -- scalespeed
		}
		
		-- Middle bullet has a little bit of homing
		local factor = 60
		mo.momx = $ - $/factor
		mo.momy = $ - $/factor
		mo.momz = $ - $/factor
		if valid(mo.tracer)
		and not mo.extravalue1 then
			local t = mo.tracer
			local angle = R_PointToAngle2(mo.x, mo.y, t.x, t.y)
			P_Thrust(mo, angle, FRACUNIT/factor)
		end
	end,
	
	attack = 5,
	speed = 5,
	homing = 4,
	reload = 5,
	down = 6,
})

FLCR.AddWeapon({
	name = "gatling", 
	desc = "Fires multiple small rounds straight ahead. Stay close to the enemy for better shots.",
	mt = MT_DUMMYMISSILE,
	spawnsound = sfx_gtlng,
	parttype = CRPT_GUN,
	spawnfunc = function(p, w)
		if not valid(p) then return end
		if not p.crplayerdata then return end
		local CRPD = FLCR.PlayerData[p.crplayerdata.id]
		if not valid(CRPD.player) then return end
		if not valid(p.mo) then return end
		local mo = p.mo

		local multifireinterval = TICRATE/9 -- Multishot interval
		local maxrounds = 8 -- How many rounds can your weapon fire per-clip?
		if (CRPD.firetics%multifireinterval) -- Modulo by your weapon's firedelay, a non zero number?
		or (CRPD.firemaxrounds >= maxrounds)
			return
		elseif not CRPD.firetics then
			CRPD.firetype = w.parttype
			CRPD.firetics = (multifireinterval * maxrounds)*2
			p.powers[pw_nocontrol] = CRPD.firetics - 6*(w.reload)
		end
		
		-- Let's spawn the bullet!
		local xyangle = mo.target and R_PointToAngle2(mo.x, mo.y, mo.target.x, mo.target.y) or p.drawangle
		local zangle = p.aiming
		local th = Lib.spawnCRMissile(mo, w, xyangle, zangle)
		if valid(th) then
			th.thinkfunc = w.thinkfunc
			th.damage = w.attack * 3
			th.knockdown = 9
			th.state = S_RRNG1
			th.color = SKINCOLOR_YELLOW
			th.fuse = 3*TICRATE
			if mo.target then th.tracer = mo.target end
		end
		CRPD.firemaxrounds = $ + 1
	end,

	thinkfunc = function(mo)
		if not valid(mo) then return end
		if (mo.state == mo.info.deathstate) then return end		
		-- Interpolate fx graphics towards prev position
		if mo.prev then
			for i = 1, 5 do
				local x = ease.linear(i*FRACUNIT/5, mo.prev.x, mo.x)
				local y = ease.linear(i*FRACUNIT/5, mo.prev.y, mo.y)
				local z = ease.linear(i*FRACUNIT/5, mo.prev.z, mo.z)
				
				local fx = P_SpawnMobj(x,y,z-(mobjinfo[mo.type].height/3),MT_DUMMYFX)
				fx.state = S_THOK
				--fx.scale = mo.scale
				fx.scale = ease.linear(i*FRACUNIT/5, mo.prev.scale, mo.scale)
				fx.destscale = 1
				fx.scalespeed = FRACUNIT/5
				fx.color = mo.color
				fx.frame = $|FF_TRANS70
				fx.blendmode = AST_ADD
			end
		end
		
		local factor = 80
		mo.momx = $ - $/factor
		mo.momy = $ - $/factor
		mo.momz = $ - $/factor
		if valid(mo.tracer) then
			local t = mo.tracer
			local angle = R_PointToAngle2(mo.x, mo.y, t.x, t.y)
			P_Thrust(mo, angle, FRACUNIT/factor)
		end
		
		mo.prev = {
			x = mo.x,
			y = mo.y,
			z = mo.z,
			scale = mo.scale - FRACUNIT/5 -- scalespeed
		}
	end,

	attack = 4,
	speed = 7,
	homing = 2,
	reload = 3,
	down = 6,
})

FLCR.AddWeapon({
	name = "vertical", 
	desc = "Fires 2 rounds. One ascends diagonally, clearing walls. Use this as you hide behind walls.",
	mt = MT_DUMMYMISSILE,
	spawnsound = sfx_vrtcl,
	parttype = CRPT_GUN,
	spawnfunc = function(p, w)
		if not valid(p) then return end
		if not p.crplayerdata then return end
		local CRPD = FLCR.PlayerData[p.crplayerdata.id]
		if not valid(CRPD.player) then return end
		if not valid(p.mo) then return end
		local mo = p.mo
		
		local multifireinterval = TICRATE/4 -- Multishot interval
		local maxrounds = 2 -- How many rounds can your weapon fire per-clip?
		if (CRPD.firetics%multifireinterval) -- Modulo by your weapon's firedelay, a non zero number?
		or (CRPD.firemaxrounds >= maxrounds)
			return
		elseif not CRPD.firetics then
			CRPD.firetype = w.parttype
			CRPD.firetics = (multifireinterval * maxrounds)*2
			p.powers[pw_nocontrol] = CRPD.firetics - (w.reload)
		end
		
		-- Let's spawn the bullet(s)!
		local xyangle = mo.target and R_PointToAngle2(mo.x, mo.y, mo.target.x, mo.target.y) or p.drawangle
		local zangle = p.aiming
		local rt -- Reference thing for targeting
		for i = 0, 1, 1 do
			local fa = i*FixedAngle(50*FRACUNIT)
			local th = Lib.spawnCRMissile(mo, w, xyangle, zangle+fa)
			if valid(th) then
				if not (i&1) then
					rt = P_SpawnMobj(th.x, th.y, th.z, MT_DUMMY)

					rt.flags = $ & ~MF_NOCLIPTHING|MF_NOBLOCKMAP -- For homing.
					rt.momx = th.momx
					rt.momy = th.momy
					rt.momz = th.momz
					rt.fuse = 3*TICRATE
				else
					th.bbullet = rt
				end
				th.extravalue1 = i
				th.thinkfunc = w.thinkfunc
				th.damage = w.attack * 6
				th.knockdown = 30
				th.state = S_RRNG1
				th.color = SKINCOLOR_WHITE
				th.fuse = 3*TICRATE
				if mo.target then th.tracer = mo.target end
			end
		end
		CRPD.firemaxrounds = $ + 1
	end,
	
	thinkfunc = function(mo)
		if not valid(mo) then return end
		if (mo.state == mo.info.deathstate) then return end
		-- Interpolate fx graphics towards prev position
		if mo.prev then
			for i = 1, 5 do
				local x = ease.linear(i*FRACUNIT/5, mo.prev.x, mo.x)
				local y = ease.linear(i*FRACUNIT/5, mo.prev.y, mo.y)
				local z = ease.linear(i*FRACUNIT/5, mo.prev.z, mo.z)
				
				local fx = P_SpawnMobj(x,y,z-(mobjinfo[mo.type].height/3),MT_DUMMYFX)
				fx.state = S_THOK
				--fx.scale = mo.scale
				fx.scale = ease.linear(i*FRACUNIT/5, mo.prev.scale, mo.scale)
				fx.destscale = 1
				fx.scalespeed = FRACUNIT/5
				fx.color = mo.color
				fx.frame = $|FF_TRANS70
				fx.blendmode = AST_ADD
			end
		end
		
		if mo.extravalue1
		and (mo.fuse < (3*TICRATE)-4)
		and valid(mo.bbullet) then
			Lib.homingAttack(mo, mo.bbullet, 50*FRACUNIT)
		end
		
		local factor = 70
		mo.momx = $ - $/factor
		mo.momy = $ - $/factor
		mo.momz = $ - $/factor
		if valid(mo.tracer) then
			local t = mo.tracer
			local angle = R_PointToAngle2(mo.x, mo.y, t.x, t.y)
			P_Thrust(mo, angle, FRACUNIT/factor)
		end
		
		mo.prev = {
			x = mo.x,
			y = mo.y,
			z = mo.z,
			scale = mo.scale - FRACUNIT/5 -- scalespeed
		}
	end,
	attack = 4,
	speed = 5,
	homing = 3,
	reload = 5,
	down = 7,
})

FLCR.AddWeapon({
	name = "sniper",
	desc = "Fires one quick, straight round. While the round flies fast, it leaves you in danger for a time.",
	mt = MT_DUMMYMISSILE,
	spawnsound = sfx_snip,
	parttype = CRPT_GUN,
	spawnfunc = function(p, w)
		if not valid(p) then return end
		if not p.crplayerdata then return end
		local CRPD = FLCR.PlayerData[p.crplayerdata.id]
		if not valid(CRPD.player) then return end
		if not valid(p.mo) then return end
		local mo = p.mo
		
		if CRPD.firetics then return end
		CRPD.firetype = w.parttype
		CRPD.firetics = 4*TICRATE/3
		p.powers[pw_nocontrol] = CRPD.firetics - w.reload
		
		-- Let's spawn the bullet!
		local xyangle = mo.target and R_PointToAngle2(mo.x, mo.y, mo.target.x, mo.target.y) or p.drawangle
		local zangle = p.aiming
		local th = Lib.spawnCRMissile(mo, w, xyangle, zangle)
		if valid(th) then
			th.thinkfunc = w.thinkfunc
			th.damage = w.damage * 15
			th.knockdown = th.damage/2
			th.state = S_RRNG1
			th.color = SKINCOLOR_WHITE
			th.fuse = 3*TICRATE
		end
		CRPD.firemaxrounds = $ + 1
	end,
	
	thinkfunc = function(mo)
		if not valid(mo) then return end
		if (mo.state == mo.info.deathstate) then return end
		if mo.prev then
			-- Interpolate fx graphics towards prev position
			for i = 1, 5 do
				local x = ease.linear(i*FRACUNIT/5, mo.prev.x, mo.x)
				local y = ease.linear(i*FRACUNIT/5, mo.prev.y, mo.y)
				local z = ease.linear(i*FRACUNIT/5, mo.prev.z, mo.z)
				
				local fx = P_SpawnMobj(x,y,z-(mobjinfo[mo.type].height/3),MT_DUMMYFX)
				fx.state = S_THOK
				fx.tics = 28
				--fx.scale = mo.scale
				fx.scale = ease.linear(i*FRACUNIT/5, mo.prev.scale, mo.scale)
				fx.destscale = 1
				fx.scalespeed = FRACUNIT/10
				fx.color = mo.color
				fx.frame = $|FF_TRANS70
				fx.blendmode = AST_ADD
			end
		end
		
		if (mo.fuse > (3*TICRATE)-3) then
			local inc = 3*TICRATE - mo.fuse
			local fx2 = P_SpawnMobjFromMobj(mo, 0,0,0, MT_DUMMYFX)
			fx2.state = S_FX_WIND
			fx2.angle = mo.angle - ANGLE_90
			if mo.momz then
				P_CreateFloorSpriteSlope(fx2)
				fx2.flags2 = $ | MF2_SPLAT
				fx2.renderflags = $ | RF_FLOORSPRITE | RF_SLOPESPLAT | RF_NOSPLATBILLBOARD
				fx2.floorspriteslope.o = { x = mo.x, y = mo.y, z = mo.z }
				fx2.floorspriteslope.xydirection = mo.angle
				fx2.floorspriteslope.zangle = FixedAngle(mo.momz/2) + ANGLE_90
				fx2.spritexscale = FixedMul(sin(abs(FixedAngle(mo.momz/2))), FRACUNIT)
			end
		end
		
		mo.prev = {
			x = mo.x,
			y = mo.y,
			z = mo.z,
			scale = mo.scale - FRACUNIT/10 -- scalespeed
		}
	end,
	attack = 7,
	speed = 9,
	homing = 1, -- Literally no homing LMAO
	reload = 2,
	down = 7,
})

FLCR.AddWeapon({
	name = "stun", 
	desc = "Fire continuous short-ranged electric shots that paralyze foes. Use at close range.",
	mt = MT_DUMMYMISSILE,
	spawnsound = sfx_stun,
	parttype = CRPT_GUN,
	spawnfunc = function(p, w)
		if not valid(p) then return end
		if not p.crplayerdata then return end
		local CRPD = FLCR.PlayerData[p.crplayerdata.id]
		if not valid(CRPD.player) then return end
		if not valid(p.mo) then return end
		local mo = p.mo

		if CRPD.firetics then return end
		CRPD.firetype = w.parttype
		CRPD.firetics = TICRATE/3
		p.powers[pw_nocontrol] = CRPD.firetics - w.reload
		
		-- Let's spawn the bullet!
		local xyangle = mo.target and R_PointToAngle2(mo.x, mo.y, mo.target.x, mo.target.y) or p.drawangle
		local zangle = p.aiming
		local th = Lib.spawnCRMissile(mo, w, xyangle, zangle)
		if valid(th) then
			th.momx = 1
			th.momy = 1
			th.momz = 1
			th.damage = w.attack * 15
			th.knockdown = th.damage/2
			th.state = S_FX_ELECEXPLODE
			th.color = SKINCOLOR_COBALT
			--th.scale = 2*FRACUNIT
			th.fuse = TICRATE/3
			
			-- Below is purely cosmetic
			for i = -2, 2, 1 do
				if not i then continue end
				local j = (i<0) and -1 or 1
				local fa = j*ANGLE_45
				local fxangle = xyangle + fa

				local fx = P_SpawnMobjFromMobj(th, FixedMul(cos(fxangle), th.radius),
													FixedMul(sin(fxangle), th.radius),
													0,
													MT_DUMMYFX)
				fx.state = S_FX_ELECDIAG
				fx.angle = fxangle + ANGLE_180
				--fx.scale = 2*FRACUNIT
				local camangle, ra = R_PointToAngle(mo.x, mo.y)
				if abs(i) > 1 then
					fx.rollangle = $ - ANGLE_90
					fx.z = $ - th.height
				end
				if ((camangle - mo.angle) < 0) then 
					fx.rollangle = InvAngle($)
				end
			end
		end
		CRPD.firemaxrounds = $ + 1
	end,
	
	attack = 2,
	speed = 7,
	homing = 3,
	reload = 8,
	down = 7,
})

FLCR.AddWeapon({
	name = "ion", 
	desc = "Fires two rounds that turn mid-flight.",
	-- Instant down if hit. Between 35-40 dmg
	spawnsound = 0,
	parttype = CRPT_GUN,
	attack = 2,
	speed = 2,
	homing = 5,
	reload = 4,
	down = 2,
})

FLCR.AddWeapon({
	name = "hornet", 
	desc = "Spreads five bee-shaped rounds that chase its target.",
	mt = MT_DUMMYMISSILE,
	spawnsound = sfx_hnet,
	parttype = CRPT_GUN,
	spawnfunc = function(p, w)
		if not valid(p) then return end
		if not p.crplayerdata then return end
		local CRPD = FLCR.PlayerData[p.crplayerdata.id]
		if not valid(CRPD.player) then return end
		if not valid(p.mo) then return end
		local mo = p.mo

		if CRPD.firetics then return end
		CRPD.firetype = w.parttype
		CRPD.firetics = 4*TICRATE/3
		p.powers[pw_nocontrol] = CRPD.firetics - w.reload
		
		-- Let's spawn the bullet!
		for i = -2, 2, 1 do 
			local xyangle = mo.target and R_PointToAngle2(mo.x, mo.y, mo.target.x, mo.target.y) or p.drawangle
			local fa = i*ANGLE_22h
			xyangle = $ + fa
			local zangle = ease.linear(AngleFixed(p.aiming+ANGLE_90) / 180, -ANGLE_45, ANGLE_45)
			local th = Lib.spawnCRMissile(mo, w, xyangle, zangle)
			if valid(th) then
				th.scale = 2*FRACUNIT
				th.extravalue1 = i
				th.tracer = mo.target
				th.thinkfunc = w.thinkfunc
				th.damage = w.attack * 4
				th.knockdown = th.damage - 10
				th.state = S_BUMBLEBORE_BULLET
				th.color = SKINCOLOR_YELLOW
				th.fuse = 3*TICRATE
			end
		end
		--CRPD.firemaxrounds = $ + 1
	end,
	
	thinkfunc = function(mo)
		if not valid(mo) then return end
		if (mo.state == mo.info.deathstate) then return end
		
		if not (leveltime%(TICRATE/3)) then
			local fx = P_SpawnMobjFromMobj(mo, 0,0,0, MT_SPARK)
		end
		
		local timethreshold = 3*TICRATE-7
		if (mo.fuse <= timethreshold) then
			if not valid(mo.tracer)
			and (mo.fuse == timethreshold) then
				mo.angle = $ - mo.extravalue1*ANGLE_22h
				local speed = FixedHypot(mo.momx, mo.momy)
				P_InstaThrust(mo, mo.angle, speed)
			elseif valid(mo.tracer)
			and (mo.fuse >= TICRATE) then -- Don't home in forever
				local angle = R_PointToAngle2(mo.x, mo.y, mo.tracer.x, mo.tracer.y) or FixedHypot(mo.momx, mo.momy)
				mo.angle = angle
				Lib.homingAttack(mo, mo.tracer, 25*FRACUNIT)
			end
		end
	end,
	attack = 6,
	speed = 3,
	homing = 6,
	reload = 3,
	down = 6,
})

FLCR.AddWeapon({
	name = "flame", 
	desc = "Fires flame-shaped rounds straight ahead. Its power increases with distance.",
	mt = MT_DUMMYMISSILE,
	spawnsound = sfx_frame,
	parttype = CRPT_GUN,
	spawnfunc = function(p, w)
		if not valid(p) then return end
		if not p.crplayerdata then return end
		local CRPD = FLCR.PlayerData[p.crplayerdata.id]
		if not valid(CRPD.player) then return end
		if not valid(p.mo) then return end
		local mo = p.mo
		
		local multifireinterval = TICRATE/12 -- Multishot interval
		local maxrounds = 9 -- How many rounds can your weapon fire per-clip?
		if (CRPD.firetics%multifireinterval) -- Modulo by your weapon's firedelay, a non zero number?
		or (CRPD.firemaxrounds >= maxrounds)
			return
		elseif not CRPD.firetics then
			CRPD.firetype = w.parttype
			CRPD.firetics = (multifireinterval * maxrounds)*2
			p.powers[pw_nocontrol] = CRPD.firetics - (w.reload)
		end
		
		-- Let's spawn the bullet!
		local xyangle = mo.target and R_PointToAngle2(mo.x, mo.y, mo.target.x, mo.target.y) or p.drawangle
		local zangle = p.aiming
		local th = Lib.spawnCRMissile(mo, w, xyangle, zangle)
		if valid(th)
			if mo.target then th.tracer = mo.target end
			th.thinkfunc = w.thinkfunc
			th.damage = w.attack * 2
			th.knockdown = th.damage/2
			--th.state = S_RRNG1
			--th.frame = $|FF_TRANS50
			--th.blendmode = AST_ADD
			th.scale = FRACUNIT/2
			th.color = SKINCOLOR_RED
			th.fuse = TICRATE
			th.destscale = 8*FRACUNIT
			th.scalespeed = FRACUNIT/(TICRATE/4)
		end
		CRPD.firemaxrounds = $ + 1
	end,
	
	thinkfunc = function(mo)
		if not valid(mo) then return end
		if (mo.state == mo.info.deathstate) then return end
		
		local factor = 9
		mo.momx = $ - $/factor
		mo.momy = $ - $/factor
		mo.momz = $ - $/factor
		if valid(mo.tracer) then
			local t = mo.tracer
			local angle = R_PointToAngle2(mo.x, mo.y, t.x, t.y)
			P_Thrust(mo, angle, FRACUNIT/factor)
		end
		
		for i = 0, 1 do
			local r = mo.radius>>FRACBITS
			local e = P_SpawnMobj(mo.x + (P_RandomRange(r, -r)<<FRACBITS),
								mo.y + (P_RandomRange(r, -r)<<FRACBITS),
								mo.z - mo.height/2
								+ P_MobjFlip(mo)*(P_RandomKey(mo.height>>FRACBITS)<<FRACBITS),
								MT_DUMMYFX)
			e.state = S_FX_FIREUP2
			e.frame = $|FF_PAPERSPRITE
			local camangle, ra = R_PointToAngle(mo.x, mo.y), -FixedAngle(90*FRACUNIT) + FixedAngle(mo.momz)
			e.angle = mo.angle
			--e.angle = R_PointToAngle(mo.target.x, mo.target.y, mo.x, mo.y) + ANGLE_90
			if ((camangle - mo.angle) < 0) then 
				ra = InvAngle($)
			end
			e.rollangle = ra
			
			-- Max Speed can be 40*FRACUNIT
			local speed = abs(FixedHypot(FixedHypot(mo.momz, mo.momy), mo.momz))
			local momz = ease.linear(speed/40, 3*FRACUNIT, 1)
			P_SetObjectMomZ(e, momz, false)
		end
	end,
	attack = 5,
	speed = 4,
	homing = 3,
	reload = 5,
	down = 7,
})

FLCR.AddWeapon({
	name = "dragon", 
	desc = "Fires one dragon-shaped round that zeroes in on foes. Stay on your guard after firing.",
	spawnsound = sfx_drag01,
	parttype = CRPT_GUN,
	spawnfunc = function(p, w)
		if not valid(p) then return end
		if not p.crplayerdata then return end
		local CRPD = FLCR.PlayerData[p.crplayerdata.id]
		if not valid(CRPD.player) then return end
		if not valid(p.mo) then return end
		local mo = p.mo
		
		if CRPD.firetics then return end
		CRPD.firetype = w.parttype
		CRPD.firetics = 2*TICRATE
		p.powers[pw_nocontrol] = CRPD.firetics - w.reload
		
		-- Let's spawn the bullet!
		local xyangle = mo.target and R_PointToAngle2(mo.x, mo.y, mo.target.x, mo.target.y) or p.drawangle
		local zangle = p.aiming
		local th = Lib.spawnCRMissile(mo, w, xyangle, zangle)
		if valid(th) then
			th.thinkfunc = w.thinkfunc
			if P_IsObjectOnGround(mo) then -- Stronger on the ground
				th.damage = w.attack * 20
			else -- Weaker in the air
				th.damage = w.attack * 15
			end
			th.knockdown = th.damage/2
			th.state = S_RRNG2
			th.color = SKINCOLOR_ORANGE
			th.fuse = 3*TICRATE
			S_StartSound(mo, sfx_drag02, consoleplayer)
		end
		CRPD.firemaxrounds = $ + 1
	end,
	
	thinkfunc = function(mo)
		if not valid(mo) then return end
		if (mo.state == mo.info.deathstate) then 
			if valid(consoleplayer.mo) and S_SoundPlaying(consoleplayer.mo, sfx_drag02) then 
				S_StopSound(consoleplayer.mo) 
			end
			return 
		end
		if mo.prev then
			-- Interpolate fx graphics towards prev position
			for i = 1, 5 do
				local x = ease.linear(i*FRACUNIT/5, mo.prev.x, mo.x)
				local y = ease.linear(i*FRACUNIT/5, mo.prev.y, mo.y)
				local z = ease.linear(i*FRACUNIT/5, mo.prev.z, mo.z)
				
				local fx = P_SpawnMobj(x,y,z-(mobjinfo[mo.type].height/3),MT_DUMMYFX)
				fx.state = S_THOK
				fx.tics = 28
				--fx.scale = mo.scale
				fx.scale = ease.linear(i*FRACUNIT/5, mo.prev.scale, mo.scale)
				fx.destscale = 1
				fx.scalespeed = FRACUNIT/10
				fx.color = mo.color
				fx.frame = $|FF_TRANS70
				fx.blendmode = AST_ADD
			end
		end
		
		if valid(mo.tracer)
		and (mo.fuse >= TICRATE) then -- Don't home in forever
			local angle = R_PointToAngle2(mo.x, mo.y, mo.tracer.x, mo.tracer.y) or FixedHypot(mo.momx, mo.momy)
			mo.angle = angle
			Lib.homingAttack(mo, mo.tracer, 35*FRACUNIT)
		end
		
		mo.prev = {
			x = mo.x,
			y = mo.y,
			z = mo.z,
			scale = mo.scale - FRACUNIT/10 -- scalespeed
		}
	end,
	attack = 7,
	speed = 4,
	homing = 7,
	reload = 3,
	down = 8,
})

FLCR.AddWeapon({
	name = "splash", 
	desc = "Fires 3 large yet weak rounds straight ahead. Briefly immobolizes foes.",
	spawnsound = sfx_splash,
	parttype = CRPT_GUN,
	spawnfunc = function(p, w)
		if not valid(p) then return end
		if not p.crplayerdata then return end
		local CRPD = FLCR.PlayerData[p.crplayerdata.id]
		if not valid(CRPD.player) then return end
		if not valid(p.mo) then return end
		local mo = p.mo

		if CRPD.firetics then return end
		CRPD.firetype = w.parttype
		CRPD.firetics = TICRATE/4
		p.powers[pw_nocontrol] = CRPD.firetics
		
		-- Let's spawn the bullet!
		for i = -1, 1, 1 do 
			local xyangle = mo.target and R_PointToAngle2(mo.x, mo.y, mo.target.x, mo.target.y) or p.drawangle
			local fa = i*ANGLE_22h
			xyangle = $ + fa
			local zangle = ease.linear(AngleFixed(p.aiming+ANGLE_90) / 180, -ANGLE_45, ANGLE_45)
			local th = Lib.spawnCRMissile(mo, w, xyangle, zangle)
			if valid(th) then
				th.scale = 3*FRACUNIT/2
				th.extravalue1 = i
				th.tracer = mo.target
				th.thinkfunc = w.thinkfunc
				th.damage = w.attack * 15
				th.knockdown = th.damage/2
				th.state = S_RRNG1
				th.color = SKINCOLOR_SKY
				th.fuse = 2*TICRATE
			end
		end
		--CRPD.firemaxrounds = $ + 1
	end,
	
	thinkfunc = function(mo)
		if not valid(mo) then return end
		if (mo.state == mo.info.deathstate) then return end

		for i = 0, 1 do
			local r = mo.radius>>FRACBITS
			local e = P_SpawnMobj(mo.x + (P_RandomRange(r, -r)<<FRACBITS),
								mo.y + (P_RandomRange(r, -r)<<FRACBITS),
								mo.z - mo.height/2
								+ P_MobjFlip(mo)*(P_RandomKey(mo.height>>FRACBITS)<<FRACBITS),
								MT_DUMMYFX)
			e.state = P_RandomRange(S_SMALLBUBBLE, S_MEDIUMBUBBLE)
			e.fuse = TICRATE
			P_SetObjectMomZ(e, 3*FRACUNIT, false)
		end

		local timethreshold = 2*TICRATE-7
		if (mo.fuse <= timethreshold) then
			if not valid(mo.tracer)
			and (mo.fuse == timethreshold) then
				mo.angle = $ - mo.extravalue1*ANGLE_22h
				P_InstaThrust(mo, mo.angle, 5*FRACUNIT)
			elseif valid(mo.tracer)
			and (mo.fuse >= TICRATE) then -- Don't home in forever
				local angle = R_PointToAngle2(mo.x, mo.y, mo.tracer.x, mo.tracer.y) or FixedHypot(mo.momx, mo.momy)
				mo.angle = angle
				Lib.homingAttack(mo, mo.tracer, 5*FRACUNIT)
			end
		end
	end,
	attack = 1,
	speed = 4,
	homing = 3,
	reload = 10,
	down = 2,
})

-- Bombs
FLCR.AddWeapon({
	name = "standard", 
	desc = "Flies in an arc toward target. It's large blast radius makes aiming and multiple blows a snap.",
	spawnsound = sfx_s3k81,
	parttype = CRPT_BOMB,
	attack = 7,
	speed = 5,
	size = 5,
	time = 5,
	down = 6,
})

FLCR.AddWeapon({
	name = "standard f", 
	desc = "Flies in an arc toward target. Knocks target sideways on impact, flushing out hidden foes.",
	spawnsound = sfx_s3k81,
	parttype = CRPT_BOMB,
	special = CRL_F,
	attack = 6,
	speed = 5,
	size = 3,
	time = 5,
	down = 6,
})

FLCR.AddWeapon({
	name = "standard s", 
	desc = "Flies in an arc toward target. Immobilizes target upon impact for a short time.",
	spawnsound = sfx_s3k81,
	parttype = CRPT_BOMB,
	special = CRL_S,
	attack = 4,
	speed = 5,
	size = 4,
	time = 4,
	down = 3,
})

FLCR.AddWeapon({
	name = "standard k", 
	desc = "Flies in an arc toward target. Knocks target down on impact.",
	spawnsound = sfx_s3k81,
	parttype = CRPT_BOMB,
	special = CRL_K,
	attack = 6,
	speed = 5,
	size = 5,
	time = 5,
	down = 10,
})

FLCR.AddWeapon({
	name = "standard x", 
	desc = "Flies in an arc toward target. Explosion sends target high into the air.",
	spawnsound = sfx_s3k81,
	parttype = CRPT_BOMB,
	special = CRL_X,
	attack = 4,
	speed = 5,
	size = 4,
	time = 5,
	down = 5,
})

local crbombnames = {
	"freeze",
	"wave",
	"titan"
}
for _, bn in ipairs(crbombnames)
	FLCR.AddWeapon({ name = bn,
						parttype = CRPT_BOMB 
						})
end

-- Pods
FLCR.AddWeapon({
	name = "standard", 
	desc = "Flies straight ahead. Blows target diagonally upward.",
	spawnsound = sfx_s3k82,
	parttype = CRPT_POD,
	special = CRL_INVALID,
	attack = 4,
	speed = 5,
	homing = 4,
	size = 5,
	time = 5,
})

local crpodnames = {
	"seeker",
	"spider",
	"spider g",
	"freeze",
	"jumping b",
	"jumping g",
	"twin flank",
	"titan"
}
for _, pn in ipairs(crpodnames)
	FLCR.AddWeapon({ name = pn, 
						parttype = CRPT_POD 
						})
end

-- Legs
local crlegnames = {
	"standard",
	"high jump",
	"ground",
	"formula",
	"stabilizer",
	"short thrust",
	"long thrust",
	"quick jump",
	"feather",
	"wide jump",
	"booster"
}
