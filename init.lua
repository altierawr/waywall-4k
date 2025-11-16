local waywall = require("waywall")
local helpers = require("waywall.helpers")

-- CONFIGS - Edit these to customize
--
-- Paths to some files. MAKE SURE TO CHANGE THESE!
local PATHS = {
    overlay_png = "/home/alt/mcsr/wayfiles/measuring_overlay.png",
    ninbot_jar  = "/home/alt/mcsr/wayfiles/Ninjabrain-Bot-1.5.1.jar",
}

-- Remaps that are active while playing
local remaps_ingame = {
    ["MB4"] = "F3",
    ["MB5"] = "L", -- for chat key for search crafting
    ["V"] = "BACKSPACE",
    ["LEFTCTRL"] = "RIGHTSHIFT",
    ["CAPSLOCK"] = "LEFTCTRL",
    ["GRAVE"] = "ESC",
    ["H"] = "0"
}

-- Remaps that are active while in chat mode
local remaps_chat_mode = {
    ["MB4"] = "F3",
    ["MB5"] = "L", -- for chat key for search crafting
    ["GRAVE"] = "ESC",
    ["CAPSLOCK"] = "LEFTCTRL",
}

-- Keyboard layout for ingame (search crafting) + chatting mode. Make sure these are installed system-wide
-- You can set both to the same one (e.g. "us") if you use english for search crating or don't use search crafting at all
local ingame_layout = "norge2"
local chat_mode_layout = "us"

-- Sensitivity multipliers for in-game and eye measurement
local sens = 1.0
local eye_measure_sens = 0.04

-- Colors for pie and some texts
local primary_col = "#d08e2b"
local secondary_col = "#222222"
local ecount_text_color = "#ffffff"

-- Chat mode text
local chat_mode_text_x = 60
local chat_mode_text_y = 1380
local chat_mode_text_color = "#ffffff"
local chat_mode_text_size = 6
local chat_mode_text = "CHAT MODE ENABLED"

-- F3 pie mirror
local pie_output_size = 500
local pie_x = 2500
local pie_y = 1100

-- Eye measuring overlay
local overlay_x = 0
local overlay_y = 400
local overlay_width = 1600
local overlay_height = 900

-- F3 entity count mirror
local ecount_mirror_size_mult = 6
local ecount_mirror_x = 1000
local ecount_mirror_y = 1000

-- Pie directory mirror
local pie_dir_mirror_enabled = true
local pie_dir_y = 1300

-- CONFIGS OVER - don't edit these. More configs at the end of the file!
local is_chat_mode = false
local chat_mode_text_inst = nil

local function toggler(make_fn)
    local this
    return function(on)
        if on and not this then
            this = make_fn()
        elseif not on and this then
            this:close(); this = nil
        end
    end
end

local function image(path, dst)
    return toggler(function() return waywall.image(path, { dst = dst }) end)
end

local function mirror(src, dst, ki, ko)
    return toggler(function()
        return waywall.mirror { src = src, dst = dst, color_key = (ki and ko) and { input = ki, output = ko } or nil }
    end)
end

local is_ninb_running = function()
    local handle = io.popen("pgrep -f 'Ninjabrain.*jar'")
    local result = handle:read("*l")
    handle:close()
    return result ~= nil
end

local function exec_ninb()
    if not is_ninb_running() then
        waywall.exec(("java -jar %s"):format(PATHS.ninbot_jar))
    end
end

local function toggle_ninb()
    helpers.toggle_floating()
end

local pie_dir_rows = 8
local pie_dir_size_mult = 4
local pie_dir_width = 100
local pie_dir_mirror_height = 8 * pie_dir_rows * pie_dir_size_mult
local pie_dir_x = 3840 - pie_dir_width * pie_dir_size_mult

local pie_dir_mirror = mirror({ x = 3490, y = 1882, w = pie_dir_width, h = 8 * pie_dir_rows },
    { x = pie_dir_x, y = pie_dir_y, w = pie_dir_width * pie_dir_size_mult, h = pie_dir_mirror_height })
local is_pie_dir_mirror_visible = false

local eye_overlay = image(PATHS.overlay_png, { x = overlay_x, y = overlay_y, w = overlay_width, h = overlay_height })
local dst_pie = { x = pie_x, y = pie_y, w = pie_output_size, h = pie_output_size }

local function make_pie(src)
    return {
        ent  = mirror(src, dst_pie, "#e446c4", secondary_col),
        be   = mirror(src, dst_pie, "#ec6e4e", primary_col),
        uns  = mirror(src, dst_pie, "#46ce66", secondary_col),
        des  = mirror(src, dst_pie, "#cc6c46", secondary_col),
        prep = mirror(src, dst_pie, "#464C46", secondary_col)
    }
end

local function make_percent_mirrors(start_x, start_y)
    local width = 32
    local height = 8
    local dest_mult = 8
    local ent_color = "#e96d4d"

    local dest = { x = dst_pie.x, y = dst_pie.y + pie_output_size + 50, w = width * dest_mult, h = height * dest_mult }

    return {
        top = mirror(
            { x = start_x, y = start_y, w = width, h = height },
            dest,
            ent_color,
            primary_col
        ),
        middle = mirror(
            { x = start_x, y = start_y + height, w = width, h = height },
            dest,
            ent_color,
            primary_col
        ),
        bottom = mirror(
            { x = start_x, y = start_y + height * 2, w = width, h = height },
            dest,
            ent_color,
            primary_col
        ),
    }
end

local ecount_mirror_width = 76
local ecount_mirror_height = 14
local mirrors = {
    eye_measure  = mirror(
        { x = 162, y = 7902, w = 60, h = 580 },
        {
            x = overlay_x,
            y = overlay_y,
            w = overlay_width,
            h = overlay_height
        }
    ),
    f3           = {
        ecount = mirror(
            { x = 0, y = 76, w = ecount_mirror_width, h = ecount_mirror_height },
            {
                x = ecount_mirror_x,
                y = ecount_mirror_y,
                w = ecount_mirror_width * ecount_mirror_size_mult,
                h = ecount_mirror_height *
                    ecount_mirror_size_mult
            },
            "#dddddd",
            ecount_text_color
        ),
    },
    thin_pie     = make_pie({ x = 470, y = 1759, w = 320, h = 170 }),
    thin_percent = make_percent_mirrors(708, 1940),
    tall_pie     = make_pie({ x = 54, y = 15984, w = 320, h = 170 }),
    tall_percent = make_percent_mirrors(292, 16164),
}

local function reset()
    waywall.set_sensitivity(sens)
    eye_overlay(false)
    mirrors.eye_measure(false)
    for _, m in pairs(mirrors.f3) do m(false) end
    for _, m in pairs(mirrors.tall_pie) do m(false) end
    for _, m in pairs(mirrors.tall_percent) do m(false) end
    for _, m in pairs(mirrors.thin_percent) do m(false) end
    for _, m in pairs(mirrors.thin_pie) do m(false) end
end

local is_ingame = helpers.ingame_only(function() end)

local function resize(w, h)
    return function()
        reset()
        if is_chat_mode or is_ingame() == false then
            waywall.set_resolution(0, 0)
            return false
        end

        local aw, ah = waywall.active_res()
        if aw == w and ah == h then
            waywall.set_resolution(0, 0)
            return false
        else
            waywall.set_resolution(w, h)
            return true
        end
    end
end

local function eye_measure()
    local res = resize(384, 16384)()

    if res then
        eye_overlay(true)
        mirrors.eye_measure(true)
        waywall.set_sensitivity(eye_measure_sens)
        for _, m in pairs(mirrors.tall_pie) do m(true) end
        for _, m in pairs(mirrors.tall_percent) do m(true) end
    end
end

local function thin()
    local res = resize(800, 2160)()

    if res then
        mirrors.f3.ecount(true)
        for _, m in pairs(mirrors.thin_pie) do m(true) end
        for _, m in pairs(mirrors.thin_percent) do m(true) end
    end
end

local function chatmode()
    reset()

    if is_chat_mode then
        waywall.set_keymap({
            layout = ingame_layout
        })

        waywall.set_remaps(remaps_ingame)

        if chat_mode_text_inst then
            chat_mode_text_inst:close()
            chat_mode_text_inst = nil
        end
    else
        waywall.set_keymap({
            layout = chat_mode_layout
        })

        waywall.set_remaps(remaps_chat_mode)

        chat_mode_text_inst = waywall.text(
            chat_mode_text,
            { x = chat_mode_text_x, y = chat_mode_text_y, color = chat_mode_text_color, size = chat_mode_text_size }
        )
    end

    is_chat_mode = not is_chat_mode
end

local function pie_dir()
    if is_pie_dir_mirror_visible then
        pie_dir_mirror(false)
        is_pie_dir_mirror_visible = false
    else
        if not pie_dir_mirror_enabled then
            return
        end

        pie_dir_mirror(true)
        is_pie_dir_mirror_visible = true
    end
end

-- MORE CONFIGS, edit these to your liking
local config = {
    input = {
        layout = ingame_layout, -- change this at the top of the file
        repeat_rate = 40,
        repeat_delay = 350,
    },
    theme = {
        ninb_anchor = "topright",
        background = "#000000"
    }
}

config.actions = {
    ["*-Y"] = resize(3840, 800),
    ["*-E"] = function()
        if is_ingame() == false then
            waywall.press_key("E")
        end
        thin()
    end,
    ["*-Z"] = function()
        if is_ingame() == false then
            waywall.press_key("Z")
        end
        eye_measure()
    end,
    ["*-F7"] = exec_ninb,
    ["*-F8"] = toggle_ninb,
    ["*-F2"] = pie_dir,
    ["*-F3"] = chatmode,
}

config.input.remaps = remaps_ingame

return config
