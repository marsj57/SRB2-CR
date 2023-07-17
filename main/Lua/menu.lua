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
			{"Confirm", 4}
		}
	},
	[CRPT_GUN] = {
		name = "Equippable guns",
		options = {}
	},
	[CRPT_BOMB] = {
		name = "Equippable Bombs",
		options = {}
	},
	[CRPT_POD] = {
		name = "Equippable Pods",
		options = {}
	}
	/*[CRPT_LEG] = {
		name = "Equippable Legs",
		options = {}
	}*/
}

addHook("PlayerSpawn", function(p)
	if not valid(p) then return end
	p.crmenu = {
		open = false, -- True/False
		ref = nil, -- What menu are we in? See crmenus above
		options = 0, -- Options in p.crmenu.ref
		choice = 1, -- Choice
		scroll = 1,
		maxscroll = 4,
		gunselect = 0,
		bombselect = 0,
		podselect = 0
	}
	if not G_IsFLCRGametype() then return end
	--if p.spectator then
		if (p == consoleplayer) then -- Populate locally
			for i = CRPT_GUN, CRPT_POD do
				crmenus[i].options = {}
				local t = Lib.getWeaponTable(i)
				for j = 1, #t
					table.insert(crmenus[i].options, { t[j].name, j })
				end
			end
		end
		-- Weapons are on a first name basis
		local menu = p.crmenu
		menu.gunselect = crmenus[CRPT_GUN].options[1][1]
		menu.bombselect = crmenus[CRPT_BOMB].options[1][1]
		menu.podselect = crmenus[CRPT_POD].options[1][1]
	--end
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
				if i == 1 then wsel = menu.gunselect
				elseif i == 2 then wsel = menu.bombselect
				elseif i == 3 then wsel = menu.podselect end
				if not wsel then continue end -- Validity check
				v.drawString(10+width, y, wsel)
			end
			y = $ + 10
		end
		-- ipairs method
		/*for k, option in ipairs(crmenus[p.crmenu.ref].options) do
			if (k < scroll) and (k > maxscroll) then continue end
			local str
			local flags = V_ALLOWLOWERCASE
			if k == p.crmenu.choice then
				str = ">" .. option[1]
				flags = $|V_YELLOWMAP
			else
				str = option[1]
			end
			y = $ + 10
			v.drawString(10, y, str, flags)
			if (p.crmenu.ref == 0) -- Main menu
			and (k < #crmenus[p.crmenu.ref].options) then
				local width = v.stringWidth(str)
				if k ~= p.crmenu.choice then width = $ + 8 end

				local wsel
				if k == 1 then wsel = p.crmenu.gunselect
				elseif k == 2 then wsel = p.crmenu.bombselect
				elseif k == 3 then wsel = p.crmenu.podselect
				else return end
				v.drawString(10+width, y, wsel)
			end
		end*/
	end
end

addHook("HUD", function(v,p,c)
	if not G_IsFLCRGametype() then return end
	if not valid(p) then return end
	-- Menu always closed when in-game
	if not p.spectator -- Not a spectator?
	or p.crplayerdata then -- Or in-game?
		p.crmenu.open = false
		return -- No menu drawing!
	else
		p.crmenu.open = true
		Lib.drawCRMenu(v, p, c)
	end	
end, "game")

Lib.menuSelection = function(p, option)
	if not (type(option) == "table") then return end -- No selection
	if (type(p.crmenu.ref) ~= "number") then return end -- Not a valid menu

	local menu = p.crmenu

	if menu.ref == 0 then -- Main Menu
		menu.ref = option[2]
		menu.choice = 1

		if (menu.ref == 4) then -- Enter the game!
			p.playerstate = PST_REBORN -- stupid dumb hack
			p.cmd.buttons = BT_ATTACK
			menu.ref = 0 -- Reset the menu
		end
		return
	elseif menu.ref == CRPT_GUN then -- Gun selection
		menu.gunselect = option[1]
		menu.choice = CRPT_GUN -- Memory
	elseif menu.ref == CRPT_BOMB then  -- Bomb selection
		menu.bombselect = option[1]
		menu.choice = CRPT_BOMB -- Memory
	elseif menu.ref == CRPT_POD then -- Pod selection
		menu.podselect = option[1]
		menu.choice = CRPT_POD -- Memory
	end
	menu.scroll = 1
	menu.ref = 0 -- Return to main menu
end

addHook("PreThinkFrame", do
	for p in players.iterate
		local menu = p.crmenu
		if menu.open then
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
				if (menu.choice <= menu.scroll) then menu.scroll = menu.choice end
				if (menu.choice <= 0) then 
					menu.choice = menu.options
					menu.scroll = max(1, menu.options - menu.maxscroll)
				end
				p.forwardheld = true
			elseif (cmd.forwardmove < 0) -- Down
			and not p.forwardheld then
				menu.choice = $ + 1
				if (menu.choice > menu.scroll+menu.maxscroll) then menu.scroll = menu.choice - menu.maxscroll end
				if (menu.choice > menu.options) then 
					menu.choice = 1
					menu.scroll = 1
				end
				p.forwardheld = true
			end
			cmd.forwardmove = 0
			cmd.sidemove = 0
			p.aiming = 0
			cmd.buttons = $ & ~BT_ATTACK
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
			cmd.buttons = $ & BT_ATTACK
		end
	end
end)