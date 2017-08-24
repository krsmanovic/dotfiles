--[[
draw_bars.lua for conky

written by easysid
Monday, 13 June 2016

modified by Sun For Miles
Thursday, 17 August 2017
]]--


require 'cairo'


-- defaults for the bars. Override in settings table.
height = 78
width = 5
--fill_color = {0xf0f0f0, 0.9}
--base_color = {0xf0f0f0, 0.3}
fill_color = {0x212121, 0.5}
base_color = {0xf0f0f0, 0}

-- settings table
t = {
    {
        arg = "cpu cpu0", -- conky var
        max = 100,   -- max value
        x = 125,      -- top left x
        y = 566,      -- top left y
        -- h = 78,      -- height
        -- w = 5,       -- width
        -- color = {0x223344, 1},0xE2DEDE
        -- base = {0x667788, 0.7}
    },
    {
        arg = "cpu cpu1",
        max = 100,
        x = 130,
        y = 566,
    },
    {
        arg = "cpu cpu2",
        max = 100,
        x = 135,
        y = 566,
    },
    {
        arg = "cpu cpu3",
        max = 100,
        x = 140,
        y = 566,
    },
    {
        arg = "memperc",
        max = 100,
        w = 20,
        x = 125,
        y = 691,
    },
    {
        arg = "fs_used_perc /",
        max = 100,
        x = 126,
        y = 810,
        h = 55,
        w = 7
    },
    {
        arg = "fs_used_perc /home",
        max = 100,
        x = 133,
        y = 810,
        h = 55,
        w = 7
    },
    {
        arg = "fs_used_perc /media/che/data",
        max = 100,
        x = 140,
        y = 810,
        h = 55,
        w = 6
    },
    {
        arg = "downspeedf eth0",
        max = 11800,
        x = 125,
        y = 909,
        h = 85,
        w = 10
    },
    {
        arg = "upspeedf eth0",
        max = 11800,
        x = 135,
        y = 909,
        h = 85,
        w = 10
    },
} -- end settings table t


function conky_main()
    if conky_window == nil then return end
    local cs = cairo_xlib_surface_create(conky_window.display,
    conky_window.drawable, conky_window.visual,
    conky_window.width, conky_window.height)
    cr = cairo_create(cs)
    local updates=tonumber(conky_parse('${updates}'))
    if updates>3 then
        for i in ipairs(t) do
            draw_bars(cr,t[i])
        end --for
    end --endif
    cairo_destroy(cr)
    cairo_surface_destroy(cs)
    cr=nil
end --end main()

function draw_bars(cr,t)
    -- this function just draws the graphs. We put the text in the conkyrc
    -- set defaults
    local h0 = t.h or height
    local w0 = t.w or width
    local col = t.color or fill_color
    local bcol = t.base or base_color
    -- calculate
    value = tonumber(conky_parse(string.format("${%s}", t.arg)))
    if value == nil then value = 0 end
    local h1 = h0*value/t.max
    local y1 = t.y + h0 - h1
    -- draw base rectangle
    cairo_set_line_width(cr, 1)
    cairo_set_source_rgba (cr, rgba_to_r_g_b_a(bcol))
    cairo_rectangle(cr, t.x, t.y, w0, h0)
    cairo_fill(cr)
    -- draw overlay rectangle
    cairo_set_source_rgba (cr, rgba_to_r_g_b_a(col))
    cairo_rectangle(cr, t.x, y1, w0, h1)
    cairo_fill(cr)
end -- end draw_bars()

function rgba_to_r_g_b_a(tcolor)
    local color,alpha=tcolor[1],tcolor[2]
    return ((color / 0x10000) % 0x100) / 255.,
    ((color / 0x100) % 0x100) / 255., (color % 0x100) / 255., alpha
end --end rgba_to_r_g_b_a()
