local storage = minetest.get_mod_storage()
local prefix = "newsOnJoinExceptions_"

local colors = {
    background_color = "#FFF0",
    font_color = "#FFF",
    heading_1_color = "#AFA",
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

local function show_news_formspec(name)
    local player_info = minetest.get_player_information(name)
    local language_code = player_info.lang_code

    if (language_code == "") then
        language_code = "en"
    end

    local news_formspec = "formspec_version[5]" ..
        "size[25, 15]" ..
        "noprepend[]" ..
        "bgcolor[" .. colors.background_color .. "]" ..
        "button_exit[21.8, 13.8; 3, 1;exit; OK]" ..
        "checkbox[0.2, 14.4;dont_show_again; Don't show me this again; false]"

    local news_filename = minetest.get_worldpath() .. "/news_" .. language_code .. ".md"
    local news_file = io.open(news_filename, "r")
    local news_markdown = news_file:read("*a")
    news_file:close()

    news_formspec = news_formspec .. md2f.md2f(0.2, 0.2, 24.8, 13.4, news_markdown, "server_news", colors)

    minetest.log("action", "Showing news to " .. name .. " in language " .. language_code)
    minetest.show_formspec(name, "server_news", news_formspec)
    
    minetest.register_on_player_receive_fields(function(player, formname, fields)
        name = player:get_player_name()

        -- Don't do anything when the exit button is clicked, because no checkbox data is sent then
        if not fields.exit then
            if (fields.dont_show_again == "true") then
                storage:set_int(prefix .. name, 1)
            else
                storage:set_int(prefix .. name, 0)
            end
        end
    end)
end

minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    
    if (storage:get_int(prefix .. name) == 0) then
        show_news_formspec(name)
    end
end)

minetest.register_chatcommand("news", {
    description = "Shows the server news",
    func = show_news_formspec
})

minetest.register_chatcommand("toggle_news", {
    description = "Toggles showing the news to you when you log in",
    func = function(name)
        local current_state = storage:get_int(prefix .. name)

        if (current_state == 0) then
            storage:set_int(prefix .. name, 1)
            minetest.chat_send_player(name, "You will no longer see automatic news")
        else
            storage:set_int(prefix .. name, 0)
            minetest.chat_send_player(name, "You will now see automatic news")
        end
    end
})