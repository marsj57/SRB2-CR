-- Hey, you're awfully nosy aren't you?
-- Just so you know, a lot of what you see here is mixed between original code
-- and code that I've gotten permission to use.
--
-- A word of warning: YOU SHOULD ASSUME __NONE__ OF THE CODE HERE IS REUSABLE.
-- GET PERMISSION TO USE THIS STUFF BEFORE YOU USE IT YOURSELF
--
-- Flame

FLCR.weaponFire = function(p, id)
	local w = FLCR.Weapons[id]

	if (w.func ~= nil) then
		w.func(p, w)
	else
		print("NOT IMPLEMENTED YET!")
	end
end

FLCR.gameplayStuff = function(p)
	if not p.crloadout then return end
	local cmd = p.cmd
	p.weaponshuffleheld = $ or false

	if p.weaponfire then
		-- Autofiring
		
		-- Don't fire under the following conditions
		-- Spectator is already checked earlier so check these!
		if (p.playerstate == PST_DEAD) or P_PlayerInPain(p) then return end
		FLCR.weaponFire(p, p.crloadout[p.crselection])
		return -- Don't process anything else while this is going on
	else
		-- Weapon shuffling
		if (cmd.buttons & BT_WEAPONNEXT) and not p.weaponshuffleheld then
			p.crselection = (p.crselection >= #p.crloadout) and 1 or $ + 1
			p.weaponshuffleheld = true
		elseif (cmd.buttons & BT_WEAPONPREV) and not p.weaponshuffleheld then
			p.crselection = (p.crselection <= 1) and #p.crloadout or $ - 1
			p.weaponshuffleheld = true
		end
	end
	
	if p.weaponshuffleheld
	and not ((cmd.buttons & BT_WEAPONNEXT) 
	or (cmd.buttons & BT_WEAPONPREV)) then 
		p.weaponshuffleheld = false 
	end
end

addHook("PreThinkFrame", do
	for p in players.iterate
		if not valid(p.mo) 
		or p.spectator 
		or (p.playerstate == PST_DEAD) then
			continue 
		end
		 -- Do not fire rings, ever
		if (p.weapondelay <= 1) then p.weapondelay = 1 end
		p.weaponfire = (p.weapondelay > 1) and true or false
		p.weaponfirecount = (p.weapondelay > 1) and $ or 0
	end
end)

addHook("PlayerSpawn", function(p)
	-- Set yourself up with a noob pack!
	p.crloadout = {CRWEP_GUN_BASIC, CRWEP_GUN_GATLING, CRWEP_BOMB_STANDARD, CRWEP_POD_STANDARD}
	p.crselection = 1
end)

addHook("PlayerThink", function(p)
	if not valid(p) then return end
	if p.spectator then return end
	local cmd = p.cmd
	/*p.custbtn = ((cmd.buttons & BT_CUSTOM1) and 1 or 0) or
				((cmd.buttons & BT_CUSTOM2) and 2 or 0) or
				((cmd.buttons & BT_CUSTOM3) and 3 or 0)
	p.custheld = $ or {false, false, false} -- Three custom buttons*/
	local wmask = (cmd.buttons & BT_WEAPONMASK)
	p.wmaskheld = $ or {false, false, false} -- Use 3 weapon mask buttons

	--Testing
	--print(p.custheld[1] + ", " + p.custheld[2] + ", " + p.custheld[3] )

	FLCR.gameplayStuff(p)

	-- Weapon firing
	-- Do not process anything on these following conditions...
	if not p.crloadout then return end -- No loadout
	-- Spectator is already checked earlier so check these!
	if (p.playerstate == PST_DEAD) or P_PlayerInPain(p) then return end
	if not p.weaponfire then
		-- Checks passed, let's fire your weapon!
		if (cmd.buttons & BT_ATTACK) and not (p.pflags & PF_ATTACKDOWN) then
			FLCR.weaponFire(p, p.crloadout[p.crselection]) -- Use the current weapon you have selected
			p.pflags = $ | PF_ATTACKDOWN
		/*elseif p.custbtn and not p.custheld[p.custbtn] then
			p.crselection = p.custbtn
			FLCR.weaponFire(p, p.crloadout[p.crselection]) -- Use a dedicated button input w/ BT_CUSTOM
			p.custheld[p.custbtn] = true*/
		elseif wmask and (wmask >= 1)
		and (wmask <= #p.crloadout)
		and not p.wmaskheld[wmask] then
			p.crselection = wmask
			FLCR.weaponFire(p, p.crloadout[p.crselection]) -- Use a dedicated button input w/ BT_WEAPONMASK!
			p.wmaskheld[wmask] = true
		end
	end
	
	-- Release your held button
	/*for i = 1, 3 do -- 3 BT_CUSTOM buttons
		if (i == p.custbtn[i]) then continue end
		p.custheld[i] = false
	end*/
	for i = 1, #p.wmaskheld do -- Weapon Mask
		if (i == wmask) then continue end
		p.wmaskheld[i] = false
	end
end)