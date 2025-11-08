local waywall = require("waywall")
local helpers = require("waywall.helpers")

local PATHS = {
    overlay_png = "/home/alt/mcsr/wayfiles/measuring_overlay.png",
    ninbot_jar  = "/home/alt/mcsr/wayfiles/Ninjabrain-Bot-1.5.1.jar",
}

local sens = 1.0

local primary_col = "#d08e2b"
local secondary_col = "#222222"
local is_chat_mode = false
local chat_mode_text = nil

local config = {
    input = {
        layout = "norge2",
        repeat_rate = 20,
        repeat_delay = 150,
    },
    theme = {
        ninb_anchor = "topright",
        background = "#000000"
    }
}

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

local overlay_width = 1600
local overlay_height = 900

local eye_overlay = image(PATHS.overlay_png, { x = 0, y = 400, w = overlay_width, h = overlay_height })

local pie_output_size = 500
local dst_pie = { x = 2500, y = 1100, w = pie_output_size, h = pie_output_size }
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

    local dest = { x = dst_pie.x, y = dst_pie.y + pie_output_size + 50, w = width * dest_mult, h = height * dest_mult }

    return {
        top = mirror(
            { x = start_x, y = start_y, w = width, h = height },
            dest,
            "#e96d4d",
            primary_col
        ),
        middle = mirror(
            { x = start_x, y = start_y + height, w = width, h = height },
            dest,
            "#e96d4d",
            primary_col
        ),
        bottom = mirror(
            { x = start_x, y = start_y + height * 2, w = width, h = height },
            dest,
            "#e96d4d",
            primary_col
        ),
    }
end

local mirrors = {
    eye_measure  = mirror(
        { x = 162, y = 7902, w = 60, h = 580 },
        {
            x = 0,
            y = 400,
            w = overlay_width,
            h = overlay_height
        }
    ),
    f3           = {
        ecount = mirror({ x = 0, y = 76, w = 76, h = 14 }, { x = 1000, y = 1000, w = 76 * 6, h = 14 * 6 }, "#dddddd",
            "#ffffff"),
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

local function resize(w, h)
    return function()
        reset()
        if is_chat_mode then
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
        waywall.set_sensitivity(0.04)
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
            layout = "norge2"
        })

        if chat_mode_text then
            chat_mode_text:close()
            chat_mode_text = nil
        end
    else
        waywall.set_keymap({
            layout = "us"
        })

        chat_mode_text = waywall.text("CHAT MODE ENABLED", { x = 60, y = 1380, color = "#FFFFFF", size = 6 })
    end

    is_chat_mode = not is_chat_mode
end

config.actions = {
    ["*-Y"] = resize(3840, 800),
    ["*-E"] = function()
        if is_chat_mode then
            waywall.press_key("E")
        end
        thin()
    end,
    ["*-Z"] = function()
        if is_chat_mode then
            waywall.press_key("Z")
        end
        eye_measure()
    end,
    ["*-F7"] = exec_ninb,
    ["*-F8"] = toggle_ninb,
    ["*-F3"] = chatmode,
}

config.input.remaps = {
    ["MB4"] = "F3",
    ["LEFTCTRL"] = "RIGHTSHIFT",
}

return config
