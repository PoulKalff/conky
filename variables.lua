-- This file contains, or populates, all variables needed for conky, and adds these to the space [variables]
--   Disk rings should be set variable, according to useres wishes
--   CPU rings will be automatically added [TODO]
--   bg_alpha can be set fomr 0 to 1, determines transparency of all elements

-- find interface
local interface = "lo"
local p = io.popen("ip route show default | awk '/default/ {print $5; exit}'")

if p then
    local result = p:read("*l")
    p:close()

    if result and result ~= "" then
        interface = result
    end
end

-- find resolution
local p = io.popen([[xrandr --current | awk '/\*/ {print $1; exit}']])
local resolution = p:read("*l")
p:close()

local screen_width, screen_height = resolution:match("(%d+)x(%d+)")

screen_width  = tonumber(screen_width)
screen_height = tonumber(screen_height)


variables = {
  bg_alpha = 0.6,
  interface = interface,
  screenW = screen_width,
  screenH = screen_height,

  disk_rings = {
    { command = 'fs_used /', max = 'fs_size /' },
    { command = 'fs_used /home', max = 'fs_size /home' },
    { command = 'fs_used /mnt/3tb_hdd', max = 'fs_size /mnt/3tb_hdd' },
    { command = 'fs_used /mnt/8tb_hdd', max = 'fs_size /mnt/8tb_hdd' }
  },

  ram_rings = {
    { command = 'mem', max = 'memmax' },
    { command = 'swap', max = 'swapmax' }
  },

  cpu_rings = {
    { command = 'cpu cpu1', max = 100 },
    { command = 'cpu cpu2', max = 100 },
    { command = 'cpu cpu3', max = 100 },
    { command = 'cpu cpu4', max = 100 },
    { command = 'cpu cpu5', max = 100 },
    { command = 'cpu cpu6', max = 100 },
    { command = 'cpu cpu7', max = 100 },
    { command = 'cpu cpu8', max = 100 }
  }
}






-- NOTES: 
-------------------------------------------
-- Examples of getting variables from conky:
--   cpu_percent = tonumber(conky_parse("${cpu}")) -- Fetch CPU usage as a number
--   conky_parse() :                 conky_parse("${cpu}") → "25.5"
--   conky_get_info() :              cores = conky.get_info().cpus
