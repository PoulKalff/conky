-- This file contains, or populates, all variables needed for conky, and adds these to the space [variables]
--   BG_ALPHA can be set from 0 to 1, determines transparency of all elements
--   DISK_RINGS should be set manually, since conky cannot know what user wants to monitor



-- find number of CPUs
local p = io.popen("nproc")
local cpus = tonumber(p:read("*l"))
p:close()

local _cpu_rings = {}

for i = 1, cpus do
    _cpu_rings[#_cpu_rings + 1] = {
        command = 'cpu cpu' .. i,
        max = 100
    }
end

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

variables = {
  bg_alpha = 0.6,
  interface = interface,
  screenW = tonumber(screen_width),
  screenH = tonumber(screen_height),
  cpu_rings = _cpu_rings,

  disk_rings = {
    { command = 'fs_used /', max = 'fs_size /' },
    { command = 'fs_used /home', max = 'fs_size /home' },
    { command = 'fs_used /mnt/3tb_hdd', max = 'fs_size /mnt/3tb_hdd' },
    { command = 'fs_used /mnt/8tb_hdd', max = 'fs_size /mnt/8tb_hdd' }
  },

  ram_rings = {
    { command = 'mem', max = 'memmax' },
    { command = 'swap', max = 'swapmax' }
  }
}






-- NOTES: 
-------------------------------------------
-- Examples of getting variables from conky:
--   cpu_percent = tonumber(conky_parse("${cpu}")) -- Fetch CPU usage as a number
--   conky_parse() :                 conky_parse("${cpu}") → "25.5"
--   conky_get_info() :              cores = conky.get_info().cpus
