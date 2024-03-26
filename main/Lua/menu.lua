-- Flame
-- This is my horrible menu implementation.
-- Please don't use this. I don't know how to make a proper menu. :(

local Lib = FLCRLib

Lib.getWeaponTable = function(parttype)
	local t = {}
	
	for k,v in ipairs(FLCR.Weapons) do
		if (v.parttype ~= parttype) then continue end
		table.insert(t, v)
	end
	
	return t
end

local crmenus = {
	[0] = {
		name = "Main Menu",
		options = {
			{"Equipped Gun weapon:   ", CRPT_GUN },
			{"Equipped Bomb weapon: ", CRPT_BOMB },
			{"Equipped Pod weapon: ", CRPT_POD },
			--{"Equipped Leg parts: ", CRPT_LEG },
			{"Confirm", 99}
		}
	},
	[CRPT_GUN] = { -- 1
		name = "Equippable guns",
		options = {}
	},
	[CRPT_BOMB] = { -- 2
		name = "Equippable Bombs",
		options = {}
	},
	[CRPT_POD] = { -- 3
		name = "Equippable Pods",
		options = {}
	}
	/*[CRPT_LEG] = { -- 4
		name = "Equippable Legs",
		options = {}
	}*/
}

Lib.resetWeaponMenu = function()
	for i = CRPT_GUN, CRPT_POD do
		crmenus[i].options = {}
		local t = Lib.getWeaponTable(i)
		for j = 1, #t
			table.insert(crmenus[i].options, { t[j].name, j })
		end
	end
end
Lib.resetWeaponMenu()

addHook("PlayerSpawn", function(p)
	if not valid(p) then return end
	if G_IsFLCRGametype() then
		if not p.crmenu then -- Not intialized?
			p.crmenu = {
				open = false, -- True/False
				ref = 0, -- What menu are we in? See crmenus above
				options = 0, -- Count for menu of options in p.crmenu.ref
				choice = 1, -- Choice
				scroll = 1,
				maxscroll = 4,
				gunselect = 0,
				bombselect = 0,
				podselect = 0
				--legselect = 0
			}

			local menu = p.crmenu
			menu.gunselect = crmenus[CRPT_GUN].options[1]
			menu.bombselect = crmenus[CRPT_BOMB].options[1]
			menu.podselect = crmenus[CRPT_POD].options[1]
		end
	else
		p.crmenu = nil
		return
	end
end)

Lib.drawCRMenu = function(v, p, c)
	local menu = p.crmenu
	if not menu.open then return end
	if not menu.ref then menu.ref = 0 end
	if (type(menu.ref) == "number") then
		-- Draw menu options
		local scroll, maxscroll = menu.scroll, menu.maxscroll
		local y = 10
		local flags = V_ALLOWLOWERCASE
		for i = scroll, min(scroll+maxscroll, menu.options) do
			if not crmenus[menu.ref].options[i] then continue end -- Validity check
			local option = crmenus[menu.ref].options[i][1]
			local str
			local flags = V_ALLOWLOWERCASE
			if i == menu.choice then
				str = ">" .. option
				flags = $|V_YELLOWMAP
			else
				str = option
			end
			v.drawString(10, y, str, flags)
			if (menu.ref == 0) -- Main menu
			and (i < menu.options) then
				local width = v.stringWidth(str)
				if i ~= menu.choice then width = $ + 8 end
				local wsel
				if i == 1 then wsel = menu.gunselect[1]
				elseif i == 2 then wsel = menu.bombselect[1]
				elseif i == 3 then wsel = menu.podselect[1] end
				if not wsel then continue end -- Validity check
				v.drawString(10+width, y, wsel)
			end
			y = $ + 10
		end
	end
end

addHook("HUD", function(v,p,c)
	if not G_IsFLCRGametype() then return end
	if not valid(p) then return end
	-- Menu always closed when in-game
	if p.spectator -- If a spectator
	and not p.crplayerdata -- Not in-game
	and p.crmenu.open then -- And the menu is open?
		Lib.drawCRMenu(v, p, c) -- Then draw it!
	end
end, "game")

Lib.menuSelection = function(p, option)
	if not (type(option) == "table") then return end -- No selection
	if (type(p.crmenu.ref) ~= "number") then return end -- Not a valid menu

	local menu = p.crmenu
	local sound = sfx_menu1 -- Default sound

	if menu.ref == 0 then -- Main Menu
		menu.ref = option[2]
		menu.options = #crmenus[max(1, min(menu.ref, $-1))].options
		if (menu.ref == CRPT_GUN) then
			menu.choice = menu.gunselect[2]
			menu.scroll = max(1, min(menu.gunselect[2]-2, menu.options-menu.maxscroll))
		elseif (menu.ref == CRPT_BOMB) then
			menu.choice = menu.bombselect[2]
			menu.scroll = max(1, min(menu.bombselect[2]-2, menu.options-menu.maxscroll))
		elseif (menu.ref == CRPT_POD) then
			menu.choice = menu.podselect[2]
			menu.scroll = max(1, min(menu.podselect[2]-2, menu.options-menu.maxscroll))
		/*elseif (menu.ref == CRPT_LEGS) then
			menu.choice = menu.legselect[2]
			menu.scroll = max(1, min(menu.legselect[2]-2, menu.options-menu.maxscroll))*/
		elseif (menu.ref > #crmenus) then -- Enter the game!
			p.playerstate = PST_REBORN -- stupid dumb hack
			p.cmd.buttons = BT_ATTACK -- Spawn with simulated button
			menu.ref = 0 -- Reset the menu
			menu.options = 0
			sound = sfx_s3k63 -- Confirm!
		end
		S_StartSound(nil, sound, p)
		return
	elseif (menu.ref == CRPT_GUN) then -- Gun selection
		menu.gunselect = option
		menu.choice = CRPT_GUN -- Memory
	elseif (menu.ref == CRPT_BOMB) then  -- Bomb selection
		menu.bombselect = option
		menu.choice = CRPT_BOMB -- Memory
	elseif (menu.ref == CRPT_POD) then -- Pod selection
		menu.podselect = option
		menu.choice = CRPT_POD -- Memory
	end
	S_StartSound(nil, sound, p)
	menu.scroll = 1
	menu.ref = 0 -- Return to main menu
end

addHook("PreThinkFrame", do
	for p in players.iterate do
		if not p.crmenu then continue end
		if G_IsFLCRGametype()
		and p.spectator -- Player is a spectator
		and not p.crplayerdata then -- Definitely not in-game already?
			p.crmenu.open = true -- Open the menu
		else
			p.crmenu.open = false
		end

		local menu = p.crmenu
		if menu.open then
			local sound = sfx_menu1 -- Default sound
			local cmd = p.cmd
			if not cmd.forwardmove then p.forwardheld = false end
			-- Why does PF_JUMPDOWN and PF_SPINDOWN not work here???
			if not (cmd.buttons & BT_JUMP) then p.jumpheld = false end
			if not (cmd.buttons & BT_SPIN) then p.spinheld = false end

			menu.options = #crmenus[menu.ref].options
			if not menu.scroll then menu.scroll = 1 end

			if (cmd.forwardmove > 0) -- Up
			and not p.forwardheld then
				menu.choice = $ - 1
				S_StartSound(nil, sound, p)
				if (menu.choice <= menu.scroll) then menu.scroll = menu.choice end
				if (menu.choice <= 0) then 
					menu.choice = menu.options
					menu.scroll = max(1, menu.options - menu.maxscroll)
				end
				p.forwardheld = true
			elseif (cmd.forwardmove < 0) -- Down
			and not p.forwardheld then
				menu.choice = $ + 1
				S_StartSound(nil, sound, p)
				if (menu.choice > menu.scroll+menu.maxscroll) then menu.scroll = menu.choice - menu.maxscroll end
				if (menu.choice > menu.options) then 
					menu.choice = 1
					menu.scroll = 1
				end
				p.forwardheld = true
			end
			
			-- Below are a bunch of hacks to prevent movement as a spectator.
			-- And allow jump/spin to be used as menu confirm/back buttons.
			cmd.forwardmove = 0
			cmd.sidemove = 0
			p.aiming = 0
			--cmd.angleturn = p.realmo.angle>>16 -- See PlayerCmd hook below
			cmd.buttons = $ & ~BT_ATTACK -- Prevent player from spawning with the 'Fire' button
			if (cmd.buttons & BT_JUMP)
			and not p.jumpheld then -- Confirm
				Lib.menuSelection(p, crmenus[menu.ref].options[menu.choice])
				p.jumpheld = true
			elseif (cmd.buttons & BT_SPIN)
			and not p.spinheld then -- Cancel
				menu.choice = menu.ref or 1
				menu.ref = 0
				p.spinheld = true
			end
			-- Prevent the player from rising as spectator
			-- Also prevent Lib.menuSelection repeat trigger
			cmd.buttons = $ & BT_ATTACK
		end
	end
end)

-- Don't allow turning left/right while in menu
addHook("PlayerCmd", function(p, cmd)
	local mo = p.mo or p.realmo
	if not valid(mo) then return end
	if G_IsFLCRGametype()
	and p.crmenu
	and p.crmenu.open then
		cmd.angleturn = mo.angle>>16
	end
end)


/*if FLCRDebug then
addHook("HUD", function(v,p,c)
	--if p.spectator then return end
	local x, y = 0, 24
	local flags = V_ALLOWLOWERCASE
	if not p.crmenu.open then return end
	v.drawString(x,y,"p.crmenu debug table:", flags, "small")
	for pl in players.iterate do
		local menu = pl.crmenu
		--y = 32+(8*(i-1))
		--v.drawString(x,y,str,flags)
		drawContentsRecursively(v, menu, {x=x, y=y+8})
		x = $ + 110
	end
end,"game")

addHook("HUD", function(v,p,c)
	if p.spectator then return end
	local x, y = 0, 24
	local flags = V_SNAPTOLEFT|V_ALLOWLOWERCASE
	v.drawString(x,y,"Current FLCR.PlayerData table (Disp. 8 Entries):", flags, "small")
	for i = 1, 8
		local PD = FLCR.PlayerData[i]
		local name = PD.player and PD.player.name or "nil"
		if (PD.player == p)
			flags = $|V_YELLOWMAP
		end
		local equip = { PD.loadout[CRPT_GUN], PD.loadout[CRPT_BOMB], PD.loadout[CRPT_POD] }
		local str = name + ", " + equip[CRPT_GUN] + ", " + equip[CRPT_BOMB] + ", " + equip[CRPT_POD]
		y = 32+(8*(i-1))
		v.drawString(x,y,str,flags)
	end
end,"game")
end*/

addHook("NetVars", function(n)
	crmenus = n($)
end)