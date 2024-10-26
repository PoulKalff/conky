config = {
  bg_color = 0xffffff,
  bg_alpha = 0.5,
  fg_color_override = nil,
  fg_alpha = 0.8,
  network_ethernet = 'enp7s0'
}

groups = {
  {
    fg_color = 0xc56277,
    rings = {
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
}

require 'cairo'

function angle(position, max)
  return position / max * math.pi * 1.5 - math.pi
end


function evaluate(command, log)
  local value = conky_parse(string.format('${%s}', command)):gsub('%%', '')
  value = tonumber(value)
  if value == nil then
    return
  elseif log then
    return math.log(value + 1)
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
  cairo_set_source_rgba(cairo, rgba(fg_color, config.fg_alpha))
  cairo_move_to(cairo, fromX, fromY)
  cairo_line_to(cairo, toX, toY)
  cairo_stroke(cairo)
end


function draw_ring(cairo, x, y, radius, breakpoints, max, ringIndex)
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
      cairo_set_line_width(cairo, (#breakpoints - breakpoint_index) * 2 + 6)
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
    cairo_set_line_width(cairo, 6)
    cairo_set_source_rgba(cairo, rgba(ring_color, config.bg_alpha))
    cairo_arc(cairo, x, y, radius, previous_angle, breakpoint_angle) -- draw rest of circle
    cairo_stroke(cairo)
  end
end


function conky_rings()
  if conky_window == nil then
    return
  end
  local cairo = cairo_create(cairo_xlib_surface_create(
    conky_window.display,
    conky_window.drawable,
    conky_window.visual,
    conky_window.width,
    conky_window.height
  ))
  centerScreen = {math.floor( conky_window.width / 2 ), math.floor( conky_window.height / 2 )}
  for group_index in pairs(groups) do
    local group = groups[group_index]
    local y = group_index * 160 - 80
    local breakpoint_count = 0
    local fg_color = group.fg_color
    if config.fg_color_override ~= nil then
      fg_color = config.fg_color_override
    end
    for ring_index in pairs(group.rings) do
      local breakpoints = {}
      local ring = group.rings[ring_index]
      local value = evaluate(ring.command, ring.log)
      if ring.breakpoints ~= nil then
        local position = 0
        for breakpoint_index in pairs(ring.breakpoints) do
          local value = evaluate(ring.breakpoints[breakpoint_index], ring.log)
          if value == nil then
            break
          end
          position = position + value
          table.insert(breakpoints, position)
        end
      end
      if value ~= nil then
        table.insert(breakpoints, value)
      end
      breakpoint_count = math.max(breakpoint_count, #breakpoints)
      if #breakpoints ~= 0 then
        draw_ring(
          cairo,
          centerScreen[1],
          centerScreen[2] - 50,
          168 - ring_index * 8,
          breakpoints,
          ring.max,
          ring_index
        )
      end
    end
      cairo_select_font_face (cairo, "Abaddon™", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_REGULAR);
--      cairo_select_font_face (cairo, "Serif", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_BOLD);
      cairo_set_source_rgba(cairo, rgba(0xffffff, config.bg_alpha))
      cairo_set_font_size(cairo, 70)
      cairo_move_to(cairo, centerScreen[1] - 70, centerScreen[2] - 25)
      cairo_show_text(cairo, "CPU")
  end
end
