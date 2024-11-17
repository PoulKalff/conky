
config = {
  bg_alpha = 0.5,
  network_ethernet = 'enp7s0'
}

disks_rings = {
  { command = 'mem',  max = 'memmax' },
  { command = 'swap', max = 'swapmax' }
}

ram_rings = {
  { command = 'mem',  max = 'memmax' },
  { command = 'swap', max = 'swapmax' }
}

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

require 'cairo'

function angle(position, max)
  return position / max * math.pi * 1.5 - math.pi
end


function toPercentage(command)
  local raw = conky_parse(string.format('${%s}', command))
  local category = string.sub(raw, -3)
  local value = string.sub(raw, 0, -4)
  if category == "GiB" then
    value = tonumber(value * 1000)
  else
    value = tonumber(value)
  end
  if value == nil then
    return
  else
    return value
  end
end


function evaluate(command)
  local value = conky_parse(string.format('${%s}', command)):gsub('%%', '')
  value = tonumber(value)
  if value == nil then
    return
  else
    return value
  end
end


function rgba(color, alpha)
  return color / 0x10000 % 0x100 / 255, color / 0x100 % 0x100 / 255,
      color % 0x100 / 255, alpha
end


function draw_line(cairo, fromX, fromY, toX, toY, fg_color)
  cairo_set_line_width(cairo, 2)
  cairo_set_source_rgba(cairo, rgba(fg_color, config.bg_alpha))
  cairo_move_to(cairo, fromX, fromY)
  cairo_line_to(cairo, toX, toY)
  cairo_stroke(cairo)
end


function draw_rectangle(cairo, fromX, fromY, width, height, fg_color)
  cairo_set_line_width (cairo, 2)
  cairo_set_source_rgba(cairo, rgba(fg_color, config.bg_alpha))
  cairo_rectangle(cairo, fromX, fromY, width, height)
  cairo_stroke(cairo)
end


function draw_ring(cairo, x, y, radius, breakpoints, max, ringIndex, ring_width)
  local previous_angle = angle(0, max)
  if (ringIndex % 2 == 0) then
    ring_color = 0xa6a6a6
  else
    ring_color = 0xffffff
  end
  cairo_set_source_rgba(cairo, rgba(0xff0000, config.bg_alpha))
  for breakpoint_index in pairs(breakpoints) do
    local breakpoint_angle = angle(breakpoints[breakpoint_index], max)
    if breakpoint_angle > previous_angle then
      cairo_set_line_width(cairo, (#breakpoints - breakpoint_index) * 2 + ring_width)
      cairo_arc(        -- draw usage as red
        cairo,
        x,
        y,
        radius + #breakpoints - breakpoint_index,
        previous_angle,
        breakpoint_angle
      )
      cairo_stroke(cairo)
      previous_angle = breakpoint_angle + math.pi / 135
    end
  end
  breakpoint_angle = angle(max, max)
  if breakpoint_angle > previous_angle then
    cairo_set_line_width(cairo, ring_width)
    cairo_set_source_rgba(cairo, rgba(ring_color, config.bg_alpha))
    cairo_arc(cairo, x, y, radius, previous_angle, breakpoint_angle) -- draw rest of circle
    cairo_stroke(cairo)
  end
end


function conky_main()			-- MAIN FUNCTION. Called by conky.conf, as "rings", since "conky_" is automatically added
  if conky_window == nil then
    return
  end
  cairo = cairo_create(cairo_xlib_surface_create(
    conky_window.display,
    conky_window.drawable,
    conky_window.visual,
    conky_window.width,
    conky_window.height
  ))
  xCenter = math.floor( (conky_window.width / 2) - 20 )
  yCenter = math.floor( conky_window.height / 2 )
  -- helper lines
--  draw_line(cairo, 0, 0, 1717, 1082, 0xffffff)
--  draw_line(cairo, 0, 982, 1567, 0, 0xffffff)
  draw_cpu(xCenter, yCenter)
  draw_ram(1160, 310)


  draw_disk(400, 800)



  -- infoBox border
  draw_rectangle(cairo, 200, 105, 430, 280, 0xffffff)
end


function draw_disk(x, y)
  displayTexts = {}
end


function draw_ram(x, y)
  displayTexts = {}
  for ring_index in pairs(ram_rings) do
    local breakpoints = {}
    local ring = ram_rings[ring_index]
    local value = toPercentage(ring.command)
    local max = toPercentage(ring.max)
    txt = conky_parse(string.format('${%s}', ring.command)) .. " / " ..  conky_parse(string.format('${%s}', ring.max))
    table.insert(displayTexts, txt)
    if value ~= nil then
      table.insert(breakpoints, value)
    end
    draw_ring(
      cairo,
      x,
      y - 53,
      100 - ring_index * 18,
      breakpoints,
      max,
      ring_index, 
      16
    )
  end
  -- Write text at center of rings
  cairo_select_font_face (cairo, "Serif", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_BOLD);
  cairo_set_font_size(cairo, 14)
  cairo_set_source_rgba(cairo, rgba(0xffffff, config.bg_alpha))
  cairo_move_to(cairo, x - 140, y - 38)
  cairo_show_text(cairo, "RAM " .. displayTexts[1])
  cairo_set_source_rgba(cairo, rgba(0xa6a6a6, config.bg_alpha))
  cairo_move_to(cairo, x - 140, y - 23)
  cairo_show_text(cairo, "SWAP " .. displayTexts[2])
  cairo_stroke(cairo)
end


function draw_cpu(x, y)
  for ring_index in pairs(cpu_rings) do
    local breakpoints = {}
    local ring = cpu_rings[ring_index]
    local value = evaluate(ring.command)
    if value ~= nil then
      table.insert(breakpoints, value)
    end
    draw_ring(
      cairo,
      x,
      y - 53,
      168 - ring_index * 8,
      breakpoints,
      ring.max,
      ring_index,
      6
    )
  end
  -- Write text at center of rings
  cairo_select_font_face (cairo, "Serif", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_BOLD);
  cairo_set_source_rgba(cairo, rgba(0xffffff, config.bg_alpha))
  cairo_set_font_size(cairo, 20)
  cairo_move_to(cairo, x - 220, y - 30)
  cairo_show_text(cairo, "AMD Ryzen 7 5800X 8-Core")
  cairo_stroke(cairo)
 -- ${goto 540} ${execi 1000 grep model /proc/cpuinfo | cut -d : -f2 | tail -1 | sed 's/\s//' | sed "s/\bProcessor\b//g"}
end




