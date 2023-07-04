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
			{"Equipped Bomb weapon: ", CRPT_POD },
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
}

addHook("PlayerSpawn", function(p)
	p.crmenu = {
		open = false,
		ref = nil,
		options = 0,
		choice = 1,
		gunselect = 0,
		bombselect = 0,
		podselect = 0
	}
	if (p == consoleplayer) then -- Populate locally
		for i = CRPT_GUN, CRPT_POD do
			crmenus[i].options = {}
			local t = Lib.getWeaponTable(i)
			for j = 1, #t
				table.insert(crmenus[i].options, { t[j].name, j })
			end
		end
	end
	-- Weapon name basis
	p.crmenu.gunselect = crmenus[CRPT_GUN].options[1][1]
	p.crmenu.bombselect = crmenus[CRPT_BOMB].options[1][1]
	p.crmenu.podselect = crmenus[CRPT_POD].options[1][1]
end)

Lib.drawCRMenu = function(v, p, c)
	if not p.crmenu.open then return end
	if not p.crmenu.ref then p.crmenu.ref = 0 end
	if (type(p.crmenu.ref) == "number") then
		-- Draw menu options
		for k, option in ipairs(crmenus[p.crmenu.ref].options) do
			local str
			local flags = V_ALLOWLOWERCASE
			if k == p.crmenu.choice then
				str = ">" .. option[1]
				flags = $|V_YELLOWMAP
			else
				str = option[1]
			end
			local y = 10 + (k - 1)*10
			v.drawString(10, y, str, flags)
			if (p.crmenu.ref == 0)
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
		end
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

local function handleMenuSelection(p, option)
	if not (type(option) == "table") then return end -- No selection
	if (type(p.crmenu.ref) ~= "number") then return end -- Not a valid menu

	if p.crmenu.ref == 0 then -- Main Menu
		p.crmenu.ref = option[2]
		p.crmenu.choice = 1

		if (p.crmenu.ref == 4) then -- Enter the game!
			p.cmd.buttons = $ | BT_ATTACK
			print("Attack sent!")
			p.crmenu.ref = 0 -- Reset the menu
		end
		return
	elseif p.crmenu.ref == CRPT_GUN then -- Gun selection
		p.crmenu.gunselect = option[1]
		p.crmenu.choice = CRPT_GUN -- Memory
	elseif p.crmenu.ref == CRPT_BOMB then  -- Bomb selection
		p.crmenu.bombselect = option[1]
		p.crmenu.choice = CRPT_BOMB -- Memory
	elseif p.crmenu.ref == CRPT_POD then -- Pod selection
		p.crmenu.podselect = option[1]
		p.crmenu.choice = CRPT_POD -- Memory
	end
	p.crmenu.ref = 0 -- Return to main menu
end

addHook("PreThinkFrame", do
	for p in players.iterate
		if p.crmenu.open then
			local cmd = p.cmd
			if not cmd.forwardmove then p.forwardheld = false end
			-- Why does PF_JUMPDOWN and PF_SPINDOWN not work here???
			if not (cmd.buttons & BT_JUMP) then p.jumpheld = false end
			if not (cmd.buttons & BT_SPIN) then p.spinheld = false end

			p.crmenu.options = #crmenus[p.crmenu.ref].options

			if (cmd.forwardmove > 0)
			and not p.forwardheld then
				p.crmenu.choice = $ - 1
				if (p.crmenu.choice <= 0) then p.crmenu.choice = p.crmenu.options end
				p.forwardheld = true
			elseif (cmd.forwardmove < 0)
			and not p.forwardheld then
				p.crmenu.choice = $ + 1
				if (p.crmenu.choice > p.crmenu.options) then p.crmenu.choice = 1 end
				p.forwardheld = true
			end
			cmd.forwardmove = 0
			cmd.sidemove = 0
			cmd.buttons = $ & ~BT_ATTACK
			if (cmd.buttons & BT_JUMP)
			and not p.jumpheld then -- Confirm
				handleMenuSelection(p, crmenus[p.crmenu.ref].options[p.crmenu.choice])
				p.jumpheld = true
			elseif (cmd.buttons & BT_SPIN)
			and not p.spinheld then -- Cancel
				p.crmenu.ref = 0
				p.crmenu.choice = 1
				p.spinheld = true
			end
			cmd.buttons = $ & BT_ATTACK
		end
	end
end)