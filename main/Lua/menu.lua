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
--
-- This is my horrible menu implementation.
-- Please don't use this. I don't know how to make a proper menu. :(

local Lib = FLCRLib

Lib.getWeaponTable = function(parttype)
	local t = {}
	
	for k,v in ipairs(FLCR.Weapons) do
		if (v.parttype ~= parttype) then continue end
		-- Index 1 (t[x][1]): Weapon name
		-- Index 2 (t[x][2]): Actual weapon index in FLCR.Weapons
		table.insert(t, {v, k})
	end
	
	return t
end

local crmenus = {
	[0] = {
		name = "Main Menu",
		options = {
			{ CRPT_GUN , "Equipped Gun weapon:"},
			{ CRPT_BOMB, "Equipped Bomb weapon:"},
			{ CRPT_POD, "Equipped Pod weapon:" },
			--{ CRPT_LEG, "Equipped Leg parts: " },
			{ 99, "Confirm"}
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
			-- Index 1: Inserted menu position. Menu specific number.
			-- Index 2: Weapon name
			-- Index 3: Actual weapon index in FLCR.Weapons
			table.insert(crmenus[i].options, { j, t[j][1].name, t[j][2] })
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

-- Simple menu BG. This is just color.
Lib.drawCRMenuBG = function(v, p)
	local center = {
		x = (v.width()/v.dupx())/2,
		y = (v.height()/v.dupy())/2
	}
	local offset = {
		x = 136,
		y = 100
	}
	local c = p.skincolor or SKINCOLOR_GREY
	local c1, c2 = skincolors[c].ramp[10], skincolors[c].ramp[14]
	local f = V_SNAPTOTOP|V_SNAPTOLEFT
	v.drawFill(center.x - offset.x, center.y - offset.y, offset.x*2, offset.y*2, c2|f) -- BG
	v.drawFill(center.x - (offset.x-4), center.y - (offset.y-4), (offset.x-4)*2, (offset.y-4)*2, c1|f) -- FG
end

local function wrap(str, limit, indent, indent1)
	indent = indent or ""
	indent1 = indent1 or indent
	limit = limit or 72
	local here = 1-#indent1
	local function check(sp, st, word, fi)
		if fi - here > limit then
			here = st - #indent
			return "\n"..indent..word
		end
	end
	return indent1..str:gsub("(%s+)()(%S+)()", check)
end

Lib.drawCRMenuText = function(v, p)
	local menu = p.crmenu
	if not menu.open then return end
	if not menu.ref then menu.ref = 0 end
	local center = {
		x = (v.width()/v.dupx())/2,
		y = (v.height()/v.dupy())/2
	}
	local offset = {
		x = 134,
		y = 96
	}
	local vflags = V_SNAPTOLEFT|V_SNAPTOTOP
	if (type(menu.ref) == "number") then
		-- Get graphic info
		local wstats = {}
		if not menu.ref then -- Main Menu
			if menu.choice < menu.options then
				local index
				if menu.choice == CRPT_GUN then index = menu.gunselect[3]
				elseif menu.choice == CRPT_BOMB then index = menu.bombselect[3]
				elseif menu.choice == CRPT_POD then index = menu.podselect[3] end
				wstats = Lib.getWepStats(index) -- Pull from Weapon table
			end
		else -- Sub menu
			local index = crmenus[menu.ref].options[menu.choice][3]
			wstats = Lib.getWepStats(index) -- Pull from Weapon table
		end

		-- Draw the text and graphic
		for Dk,Dv in ipairs(wstats) do
			local stat, val = Dv[1], Dv[2]
			local statwidth = v.stringWidth(stat)
			local gfx = v.cachePatch("CRWS"..val)
			local x = ease.linear((Dk-1)*FRACUNIT/5, center.x - offset.x + gfx.width, center.x + offset.x - gfx.width)
			v.draw(x, center.y - offset.y + 4, gfx, vflags) -- gfx
			v.drawString(x + 6, center.y - offset.y + gfx.height+6, stat, V_ALLOWLOWERCASE|vflags) -- text
		end

		-- Draw menu options
		local scroll, maxscroll = menu.scroll, menu.maxscroll
		local y = center.y - offset.y + v.cachePatch("CRWS1").height + 18
		for i = scroll, min(scroll+maxscroll, menu.options) do
			if not crmenus[menu.ref].options[i] then continue end -- Validity check
			local option = crmenus[menu.ref].options[i][2]
			local str
			local flags = V_ALLOWLOWERCASE|vflags
			if i == menu.choice then -- THIS is our selected item
				str = ">" .. option
				flags = $|V_YELLOWMAP
			else
				str = option
			end
			--local strwidth = 3*v.stringWidth(str)/4
			v.drawString(center.x-offset.x + 16, y, str, flags) -- Menu header
			
			if (menu.ref == 0) -- Main menu
			and (i < menu.options) then
				--local selwidth = v.stringWidth(">")-1
				--if i ~= menu.choice then strwidth = $ + selwidth end
				local wsel
				if i == 1 then wsel = menu.gunselect[2]
				elseif i == 2 then wsel = menu.bombselect[2]
				elseif i == 3 then wsel = menu.podselect[2] end
				if not wsel then continue end -- Validity check
				--local wselwidth = v.stringWidth(wsel)
				v.drawString(center.x+offset.x-16, y, wsel, flags, "right") -- Weapon
			end
			y = $ + 10
		end
		
		-- Display weapon description
		local desc = ""
		if not menu.ref then -- Main Menu
			if menu.choice < menu.options then
				local index
				if menu.choice == CRPT_GUN then index = menu.gunselect[3]
				elseif menu.choice == CRPT_BOMB then index = menu.bombselect[3]
				elseif menu.choice == CRPT_POD then index = menu.podselect[3] end
				desc = FLCR.Weapons[index].desc
			end
		else -- Sub menu
			local index = crmenus[menu.ref].options[menu.choice][3]
			desc = FLCR.Weapons[index].desc
		end
		-- Draw the descriptive text if descriptive text is present.
		if string.len(desc) then
			v.drawString(center.x, center.y+offset.y-58, "-INFORMATION-", vflags|V_GRAYMAP, "center")
			v.drawString(center.x-offset.x+16, center.y+offset.y-48, wrap(desc,32), vflags|V_AZUREMAP|V_ALLOWLOWERCASE)
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
		-- Then draw it!
		Lib.drawCRMenuBG(v, p)
		Lib.drawCRMenuText(v, p)
	end
end, "game")

Lib.menuSelection = function(p, option)
	if not (type(option) == "table") then return end -- No selection
	if (type(p.crmenu.ref) ~= "number") then return end -- Not a valid menu

	local menu = p.crmenu
	local sound = sfx_menu1 -- Default sound

	if menu.ref == 0 then -- Main Menu
		menu.ref = option[1]
		menu.options = #crmenus[max(1, min(menu.ref, $-1))].options
		if (menu.ref == CRPT_GUN) then
			menu.choice = menu.gunselect[1]
			menu.scroll = max(1, min(menu.gunselect[1]-2, menu.options-menu.maxscroll))
		elseif (menu.ref == CRPT_BOMB) then
			menu.choice = menu.bombselect[1]
			menu.scroll = max(1, min(menu.bombselect[1]-2, menu.options-menu.maxscroll))
		elseif (menu.ref == CRPT_POD) then
			menu.choice = menu.podselect[1]
			menu.scroll = max(1, min(menu.podselect[1]-2, menu.options-menu.maxscroll))
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
			and not p.spinheld then -- Cancel/back
				if (menu.ref == CRPT_GUN) then -- Gun selection
					menu.choice = CRPT_GUN -- Memory
				elseif (menu.ref == CRPT_BOMB) then  -- Bomb selection
					menu.choice = CRPT_BOMB -- Memory
				elseif (menu.ref == CRPT_POD) then -- Pod selection
					menu.choice = CRPT_POD -- Memory
				else
					menu.choice = 1
				end
				menu.ref = 0
				menu.scroll = 1
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
		local crdeathangle = p.crdeathangle or mo.angle
		cmd.angleturn = crdeathangle>>16
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