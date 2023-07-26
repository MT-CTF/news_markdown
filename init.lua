local hud = mhud.init()

news_markdown = {}

local colors = {
	background_color = "#FFF0",
	font_color = "#FFF",
	heading_1_color = "#AFF",
	heading_2_color = "#FAA",
	heading_3_color = "#AAF",
	heading_4_color = "#FFA",
	heading_5_color = "#AFF",
	heading_6_color = "#FAF",
	heading_1_size = "26",
	heading_2_size = "24",
	heading_3_size = "22",
	heading_4_size = "20",
	heading_5_size = "18",
	heading_6_size = "16",
	code_block_mono_color = "#6F6",
	code_block_font_size = 14,
	mono_color = "#6F6",
	block_quote_color = "#FFA",
}

local news_files = {}
local current_hash
local loaded_files = false

local tabs = {}
local tab_id = {}
---@param name string Name of the tab
---@param func function params: name, lang_code_forced
---@param func function params: player, formname, fields
function news_markdown.register_tab(name, func, fieldfunc)
	table.insert(tabs, {
		name = name,
		func = func,
		fieldfunc = fieldfunc,
	})

	tab_id[name] = #tabs
end

local function get_tab_names()
	local out = ""

	for _, data in pairs(tabs) do
		out = out .. data.name .. ","
	end

	return out:sub(1, -2)
end

-- Check the player's last seen news hash against the current hash, if they are different then notify of updates
local function check_hash(player)
	if not loaded_files then
		minetest.after(1, check_hash, player)
		return
	elseif not news_files["news_en.md"] then
		minetest.log("warning", "[news_markdown] News is either set up incorrectly, or isn't set up at all")
		return
	end

	local meta = player:get_meta()

	if current_hash ~= meta:get_string("news_markdown:last_seen_hash") then
		minetest.chat_send_player(player:get_player_name(), minetest.colorize("green", "There are news updates, type /news to see them"))

		if not hud:exists(player, "text") and not hud:exists(player, "bg") then
			hud:add(player, "text", {
				hud_elem_type = "text",
				position = {x = 1, y = 1},
				offset = {x = -24, y = -22},
				alignment = {x = "left", y = "up"},
				text = "There are news updates, type /news to see them",
				color = 0x00FF00,
				z_index = 100
			})
			hud:add(player, "bg", {
				hud_elem_type = "image",
				position = {x = 1, y = 1},
				alignment = {x = "left", y = "up"},
				texture = "news_markdown_gui_formbg.png",
				image_scale = 0.8,
				z_index = 99
			})

			local pname = player:get_player_name()
			minetest.after(60, function()
				if hud:exists(pname, "text") then
					hud:clear(pname)
				end
			end)
		end
	end
end

-- Loads the news files into memory
local function update_news_files(name)
	loaded_files = false

	minetest.handle_async(function()
		local news_dir = minetest.get_worldpath() .. "/news/"
		local dirs = minetest.get_dir_list(news_dir, false)
		local news_files_update = {}

		for _, filename in pairs(dirs) do
			if filename:match("news_.+%.md") then
				local file, err = io.open(news_dir .. filename, "r")

				if not file then
					minetest.log("error", err)
				else
					news_files_update[filename] = file:read("*a")
					file:close()
				end
			end
		end

		return news_files_update
	end, function(news_files_update)
		news_files = news_files_update

		if news_files["news_en.md"] then
			current_hash = minetest.sha1(news_files["news_en.md"])
			loaded_files = true
		end

		for _, p in ipairs(minetest.get_connected_players()) do
			check_hash(p)
		end

		if name then
			minetest.chat_send_player(name, "News files updated.")
		end
	end)
end

local tabposition = {}
-- name, cmdparams?
function news_markdown.show_news_formspec(name, ...)
	if not minetest.get_player_by_name(name) then
		return false, "You need to be ingame to run this command"
	end

	if hud:exists(name, "text") then
		hud:clear(name)
	end

	local news_formspec = "formspec_version[5]" ..
		"size[25,15]" ..
		"noprepend[]" ..
		"bgcolor[" .. colors.background_color .. "]" ..
		"tabheader[0,0;tabs;"..get_tab_names()..";"..(tabposition[name] or 1)..";false;true]" ..
		"button_exit[11,14;3,0.9;exit;OK]"

	local out = tabs[tabposition[name] or 1].func(name, ...)

	if out then
		news_formspec = news_formspec .. out
	else
		return
	end

	-- Gotta log 'em all!
	minetest.log("action", "Showing news from tab "..(tabposition[name] or 1).." to " .. name)
	minetest.show_formspec(name, "news_markdown:server_news", news_formspec)
end

minetest.register_on_player_receive_fields(function(player, formname, fields, ...)
	if formname ~= "news_markdown:server_news" then return end

	local name = player:get_player_name()

	if fields.tabs then
		tabposition[name] = tonumber(fields.tabs)
		news_markdown.show_news_formspec(name)
	end

	return tabs[tabposition[player:get_player_name()] or 1].fieldfunc(player, formname, fields, ...)
end)

news_markdown.register_tab("News", function(name, lang_code_forced)
	local language_code = minetest.get_player_information(name).lang_code

	if language_code == "" then
		language_code = "en"
	end

	if lang_code_forced and lang_code_forced ~= "" then
		language_code = lang_code_forced
	end

	local news = news_files["news_" .. language_code .. ".md"]

	if not news then
		if language_code ~= "en" then
			news_markdown.show_news_formspec(name, "en")
			return
		end

		return
	end

	minetest.get_player_by_name(name):get_meta():set_string("news_markdown:last_seen_hash", current_hash)

	--[[
		(language_code == "en" and
			"button[0.1,14;5,0.9;switch_back;" or
			"button[0.1,14;5,0.9;switch_en;"
		) ..
		S("Toggle English Translation") .."]" ..
	--]]
	return md2f.md2f(0.2, 0.2, 24.8, 13.4, news, "hypertext", colors)
end,

-- on_player_receive_fields
function(player, formname, fields)
	local name = player:get_player_name()

	if fields.switch_en then
		news_markdown.show_news_formspec(name, "en")
	elseif fields.switch_back then
		news_markdown.show_news_formspec(name)
	end

	return true
end)

minetest.register_on_joinplayer(function(player)
	check_hash(player)
end)

minetest.register_chatcommand("news", {
	description = "Shows the server news",
	func = news_markdown.show_news_formspec
})

minetest.register_chatcommand("update_news", {
	description = "Checks for news updates",
	privs = {server = true},
	func = update_news_files,
})

minetest.after(0, function()
	update_news_files()
end)
