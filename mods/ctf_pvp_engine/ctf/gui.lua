ctf.gui = {
	tabs = {}
}

ctf.register_on_init(function()
	ctf._set("gui",                        true)
	ctf._set("gui.team",                   true)
	ctf._set("gui.team.initial",           "news")

	for name, tab in pairs(ctf.gui.tabs) do
		ctf._set("gui.tab." .. name,       true)
	end
end)

function ctf.gui.register_tab(name, title, func)
	ctf.gui.tabs[name] = {
		name  = name,
		title = title,
		func  = func
	}

	if ctf._defsettings and ctf._defsettings["gui.tab." .. name] == nil then
		ctf._set("gui.tab." .. name, true)
	end
end

function ctf.gui.show(name, tab, tname)
	if not tab then
		tab = ctf.setting("gui.team.initial") or "news"
	end

	if not tab or not ctf.gui.tabs[tab] or not name or name == "" then
		ctf.log("gui", "Invalid tab or name given to ctf.gui.show")
		return
	end

	if not ctf.setting("gui.team") or not ctf.setting("gui") then
		return
	end

	if not ctf.team(tname) then
		tname = ctf.player(name).team
	end

	if ctf.team(tname) then
		ctf.action("gui", name .. " views " .. tname .. "'s " .. tab .. " page")
		ctf.gui.tabs[tab].func(name, tname)
	else
		ctf.log("gui", "Invalid team given to ctf.gui.show")
	end
end

-- Get tab buttons
function ctf.gui.get_tabs(name, tname)
	local result = ""
	local id = 1
	local function addtab(name,text)
		result = result .. "button[" .. (id*1.5-1) .. ",0;1.5,1;" .. name .. ";" .. text .. "]"
		id = id + 1
	end

	for name, tab in pairs(ctf.gui.tabs) do
		if ctf.setting("gui.tab." .. name) then
			addtab(name, tab.title)
		end
	end

	return result
end

-- Team interface
ctf.gui.register_tab("news", "News", function(name, tname)
	local result = ""
	local team = ctf.team(tname).log

	if not team then
		team = {}
	end

	local amount = 0

	for i = 1, #team do
		if team[i].type == "request" then
			if ctf.can_mod(name, tname) then
				amount = amount + 2
				local height = (amount*0.5) + 0.5
				amount = amount + 1

				if team[i].mode == "diplo" then
					result = result .. "background[0.5," .. height .. ";8.3,1;diplo_" .. team[i].msg .. ".png]"
					if team[i].msg == "alliance" then
						result = result .. "label[1," .. height .. ";" ..
								team[i].team .. " offers an " ..
								minetest.formspec_escape(team[i].msg) .. " treaty]"
					else
						result = result .. "label[1," .. height .. ";" ..
								team[i].team .. " offers a " ..
								minetest.formspec_escape(team[i].msg) .. " treaty]"
					end
					result = result .. "button[6," .. height .. ";1,1;btn_y" .. i .. ";Yes]"
					result = result .. "button[7," .. height .. ";1,1;btn_n" .. i .. ";No]"
				end
			end
		else
			amount = amount + 1
			local height = (amount*0.5) + 0.5

			if height > 5 then
				break
			end

			result = result .. "label[0.5," .. height .. ";" ..
					minetest.formspec_escape(team[i].msg) .. "]"
		end
	end

	if ctf.can_mod(name, tname) then
		result = result .. "button[4,6;2,1;clear;Clear all]"
	end

	if amount == 0 then
		result = "label[0.5,1;Welcome to the news panel]" ..
			"label[0.5,1.5;News such as attacks will appear here]"
	end

	minetest.show_formspec(name, "ctf:news",
		"size[10,7]" ..
		ctf.gui.get_tabs(name, tname) ..
		result)
end)

ctf.gui.register_tab("applications","Applications", function(name, tname)
	local result = ""
	local data = {}
	
	result = result .. "label[0.5,1;Applicants to join " .. tname .. "]"
	
	for key, value in pairs(ctf.teams) do
		if key == tname then
			local height = 1.5
			for key, value in pairs(value.applications) do
				result = result .. "label[0.5.75," .. height .. ";" .. value .. "]"
				if ctf.player(name).auth or ctf.player(name).recruit then
					result = result .. "button[2.5," .. height .. ";2,1;player_" ..
						value .. ";Accept]"
					result = result .. "button[4.5," .. height .. ";2,1;player_" ..
						value .. ";Reject]"
				end
				height = height + 1
			end
		end
	end
	
	minetest.show_formspec(name, "ctf:applications",
		"size[10,7]" ..
		ctf.gui.get_tabs(name, tname) ..
		result
	)
end)
 
local scroll_diplomacy = 0
local scroll_max = 0
-- Team interface
ctf.gui.register_tab("diplo", "Diplomacy", function(name, tname)
	local result = ""
	local data = {}

	local amount = 0

	for key, value in pairs(ctf.teams) do
		if key ~= tname then
			table.insert(data,{
					team  = key,
					state = ctf.diplo.get(tname, key),
					to    = ctf.diplo.check_requests(tname, key),
					from  = ctf.diplo.check_requests(key, tname)
				})
		end
	end

	result = result .. "label[1,1;Diplomacy from the perspective of " .. tname .. "]"
	
	scroll_max = 0
	for i = 1, #data do
		scroll_max = i
		end
	scroll_max = scroll_max - 4
	
	if scroll_diplomacy > (scroll_max+4) then
		scroll_diplomacy = (scroll_max+4)
		end
		
	if scroll_diplomacy > 0 then
		result = result .. "button[9.2,0.44;1,3;scroll_up;Up]"
	end
	if scroll_diplomacy < scroll_max then
		result = result .. "button[9.2,3.8;1,3;scroll_down;Down]"
	end
		
	for i = 1, #data do
		amount = i
		local height = (i*1)+0.5

		if height > 5 then
			break
		end

		local L = i + scroll_diplomacy
		if data[L].state and data[L].team then
		result = result .. "background[1," .. height .. ";8.2,1;diplo_" ..
				data[L].state .. ".png]"
		result = result .. "button[1.25," .. height .. ";2,1;team_" ..
				data[L].team .. ";" .. data[L].team .. "]"
		result = result .. "label[3.75," .. height .. ";" .. data[L].state
				.. "]"
		end
		if ctf.can_mod(name, tname) and ctf.player(name).team == tname then
			if not data[L].from and not data[L].to then
				if data[L].state == "war" then
					result = result .. "button[7.5," .. height ..
							";1.5,1;peace_" .. data[L].team .. ";Peace]"
				elseif data[L].state == "peace" then
					result = result .. "button[6," .. height ..
							";1.5,1;war_" .. data[L].team .. ";War]"
					result = result .. "button[7.5," .. height ..
							";1.5,1;alli_" .. data[L].team .. ";Alliance]"
				elseif data[L].state == "alliance" then
					result = result .. "button[6," .. height ..
							";1.5,1;peace_" .. data[L].team .. ";Peace]"
				end
			elseif data[L].from ~= nil then
				result = result .. "label[6," .. height ..
						";request recieved]"
			elseif data[L].to ~= nil then
				result = result .. "label[5.5," .. height ..
						";request sent]"
				result = result .. "button[7.5," .. height ..
						";1.5,1;cancel_" .. data[L].team .. ";Cancel]"
			end
		end
	end

	minetest.show_formspec(name, "ctf:diplo",
		"size[10,7]" ..
		ctf.gui.get_tabs(name, tname) ..
		result
	)
end)

local function formspec_is_ctf_tab(fsname)
	for name, tab in pairs(ctf.gui.tabs) do
		if fsname == "ctf:" .. name then
			return true
		end
	end
	return false
end
function remove_application_log_entry(tname, pname)
	local entries = ctf.team(tname).log
	if not entries then
		return
	end
	for i = 1, #entries do
		if entries[i].mode == "applications" and entries[i].player == pname then
			table.remove(entries, i)
			return
		end
	end
end
 
minetest.register_on_player_receive_fields(function(player, formname, fields)
	if not formspec_is_ctf_tab(formname) then
		return false
	end

	local name    = player:get_player_name()
	local tplayer = ctf.player(name)
	local tname   = tplayer.team
	local team    = ctf.team(tname)

	if not team then
		return false
	end

	-- Do navigation
	for tabname, tab in pairs(ctf.gui.tabs) do
		if fields[tabname] then
			ctf.gui.show(name, tabname)
			return true
		end
	end

	-- Todo: move callbacks
	-- News page
	if fields.clear then
		team.log = {}
		ctf.needs_save = true
		ctf.gui.show(name, "news")
		return true
	end
end)

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local name    = player:get_player_name()
	local tplayer = ctf.player(name)
	local tname   = tplayer.team
	local team    = ctf.team(tname)

	if not team or formname ~= "ctf:news" then
		return false
	end

	for key, field in pairs(fields) do
		local ok, id = string.match(key, "btn_([yn])([0123456789]+)")
		if ok and id then
			if ok == "y" then
				ctf.diplo.set(tname, team.log[tonumber(id)].team, team.log[tonumber(id)].msg)

				-- Post to acceptor's log
				ctf.post(tname, {
					msg = "You have accepted the " ..
							team.log[tonumber(id)].msg .. " request from " ..
							team.log[tonumber(id)].team })

				-- Post to request's log
				ctf.post(team.log[tonumber(id)].team, {
					msg = tname .. " has accepted your " ..
							team.log[tonumber(id)].msg .. " request" })

				id = id + 1
			end

			table.remove(team.log, id)
			ctf.needs_save = true
			ctf.gui.show(name, "news")
			return true
		end
		local applicant_name, id = string.match(key, "player_([^_]+)_([0123456789]+)")
		if applicant_name then
			local acceptor_name = name
			local team_name = tname
			local decision = field
			ctf.decide_application(
				applicant_name,
				acceptor_name,
				team_name,
				decision)
			return true
		end
	end
end)

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local acceptor_name = player:get_player_name()
	local team_name = ctf.player(acceptor_name).team
	local team = ctf.team(team_name)
	
	if not team or formname ~= "ctf:applications" then
		return false
	end
	
	for key, field in pairs(fields) do
		if ctf.player(acceptor_name).auth or ctf.player(acceptor_name).recruit then
			local applicant_name = string.match(key, "player_(.+)")
			if applicant_name then
				local decision = field
				ctf.decide_application(
					applicant_name,
					acceptor_name,
					team_name,
					decision)
				ctf.gui.show(acceptor_name, "applications")
				return true
			end
		end
	end
end)
local cur_team = nil
minetest.register_on_player_receive_fields(function(player, formname, fields)
	local name    = player:get_player_name()
	local tplayer = ctf.player(name)
	local tname   = tplayer.team
	local team    = ctf.team(tname)

	if not team or formname ~= "ctf:diplo" then
		cur_team = nil
		return false
	end
	
	if cur_team == nil then
		cur_team = tname
		end
	if fields.scroll_up then
		if scroll_diplomacy > 0 then
			scroll_diplomacy = scroll_diplomacy - 1
		else
			scroll_diplomacy = 0
		end
		ctf.gui.show(name, "diplo", cur_team)
		end
	if fields.scroll_down then
		if scroll_diplomacy < (scroll_max) then
			scroll_diplomacy = scroll_diplomacy + 1
		else
			scroll_diplomacy = scroll_max
		end
		ctf.gui.show(name, "diplo", cur_team)
		end

	for key, field in pairs(fields) do
		local tname2 = string.match(key, "team_(.+)")
		if tname2 and ctf.team(tname2) then
			ctf.gui.show(name, "diplo", tname2)
			cur_team = tname2
			return true
		end

		if ctf.can_mod(name, tname) then
			tname2 = string.match(key, "peace_(.+)")
			if tname2 then
				if ctf.diplo.get(tname, tname2) == "war" then
					ctf.post(tname2, {
						type = "request",
						msg  = "peace",
						team = tname,
						mode = "diplo" })
				else
					ctf.diplo.set(tname, tname2, "peace")
					ctf.post(tname, {
						msg = "You have cancelled the alliance treaty with " .. tname2 })
						if minetest.get_modpath("irc") then
							irc:say(tname .. " has cancelled the alliance treaty with " .. tname2 .. "!")
						end
						minetest.chat_send_all(tname .. " has cancelled the alliance treaty with " .. tname2 .. "!")
					ctf.post(tname2, {
						msg = tname .. " has cancelled the alliance treaty" })
				end

				ctf.gui.show(name, "diplo")
				return true
			end

			tname2 = string.match(key, "war_(.+)")
			if tname2 then
				ctf.diplo.set(tname, tname2, "war")
				ctf.post(tname, {
					msg = "You have declared war on " .. tname2 })
					if minetest.get_modpath("irc") then
						irc:say(tname .. " has declared war on " .. tname2 .. "!")
					end
					minetest.chat_send_all(tname .. " has declared war on " .. tname2 .. "!")
				ctf.post(tname2, {
					msg = tname .. " has declared war on you" })
				ctf.gui.show(name, "diplo")
				return true
			end

			tname2 = string.match(key, "alli_(.+)")
			if tname2 then
				ctf.post(tname2, {
					type = "request",
					msg  = "alliance",
					team = tname,
					mode = "diplo" })

				ctf.gui.show(name, "diplo")
				return true
			end

			tname2 = string.match(key, "cancel_(.+)")
			if tname2 then
				ctf.diplo.cancel_requests(tname, tname2)
				ctf.gui.show(name, "diplo")
				return true
			end
		end -- end if can mod
	end -- end for each field
end)
