require 'variables'
require 'cairo'
require 'cairo_xlib'

function angle(position, max)
  if max == nil then
    return 0
  else
    return position / max * math.pi * 1.5 - math.pi
  end
end


function toPercentage(command)
  local raw = conky_parse(string.format('${%s}', command))
  local category = string.sub(raw, -3)
  local value = string.sub(raw, 0, -4)
  if category == "TiB" then
    value = tonumber(value * 1000000)
  elseif category == "GiB" then
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
  cairo_set_source_rgba(cairo, rgba(fg_color, variables.bg_alpha))
  cairo_move_to(cairo, fromX, fromY)
  cairo_line_to(cairo, toX, toY)
  cairo_stroke(cairo)
end


function draw_rectangle(cairo, fromX, fromY, width, height, fg_color)
  cairo_set_line_width (cairo, 2)
  cairo_set_source_rgba(cairo, rgba(fg_color, variables.bg_alpha))
  cairo_rectangle(cairo, fromX, fromY, width, height)
  cairo_stroke(cairo)
end


function draw_ring(cairo, x, y, radius, breakpoints, max, ringIndex, ring_width, color)
  local previous_angle = angle(0, max)
  if (ringIndex % 2 == 0) then
    ring_color = 0xa6a6a6
  else
    ring_color = 0xffffff
  end
  cairo_set_source_rgba(cairo, rgba(color, variables.bg_alpha))
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
    cairo_set_source_rgba(cairo, rgba(ring_color, variables.bg_alpha))
    cairo_arc(cairo, x, y, radius, previous_angle, breakpoint_angle) -- draw rest of circle
    cairo_stroke(cairo)
  end
end

function conky_main()                   -- MAIN FUNCTION. Called by conky.conf, as "rings", since "conky_" is automatically added
  if conky_window == nil then
    return
  end
  cairo = cairo_create(
    cairo_xlib_surface_create(
      conky_window.display,
      conky_window.drawable,
      conky_window.visual,
      conky_window.width,
      conky_window.height    )
  )

  local centerX = conky_window.width / 2
  local centerY = conky_window.height / 2 + 40

  draw_cpu(centerX, centerY)
  draw_ram(centerX - 400, centerY)
  draw_disk(centerX + 400, centerY)
--  draw_rectangle(cairo, 0, 0, conky_window.width - 7, conky_window.height - 1, 0x0000ff) -- rect (blue) to show LUA area, for testing. no idea why it has to be -7?
end


function draw_disk(x, y)
    local displayTexts = {}

    -- Draw disk rings and collect text to display
    for ring_index, ring in ipairs(variables.disk_rings) do
        local breakpoints = {}

        local value = toPercentage(ring.command)
        local max = toPercentage(ring.max)

        local str1 = string.sub(ring.command, 9)
        local str2 = conky_parse(string.format('${%s}', ring.max))

        table.insert(displayTexts, {str1, str2})

        if value ~= nil then
            table.insert(breakpoints, value)
        end

        draw_ring(
            cairo,
            x,
            y - 53,
            140 - ring_index * 12,
            breakpoints,
            max,
            ring_index,
            10,
            0x0000aa
        )
    end

    -- Write title at center of rings
    cairo_select_font_face(
        cairo,
        "Serif",
        CAIRO_FONT_SLANT_NORMAL,
        CAIRO_FONT_WEIGHT_BOLD
    )

    cairo_set_source_rgba(
        cairo,
        rgba(0xffffff, variables.bg_alpha)
    )

    cairo_set_font_size(cairo, 40)
    cairo_move_to(cairo, x - 50, y - 65)
    cairo_show_text(cairo, "DISK")

    -- Write disk labels and sizes
    cairo_set_font_size(cairo, 16)

    local yOffset = -37
    local lineSpacing = 15

    for index, text in ipairs(displayTexts) do

        if index % 2 == 0 then
            cairo_set_source_rgba(
                cairo,
                rgba(0xc6c6c6, variables.bg_alpha)
            )
        else
            cairo_set_source_rgba(
                cairo,
                rgba(0xffffff, variables.bg_alpha)
            )
        end

        local yPos = y + yOffset

        cairo_move_to(cairo, x - 180, yPos)
        cairo_show_text(cairo, text[1])

        cairo_move_to(cairo, x - 70, yPos)
        cairo_show_text(cairo, text[2])

        yOffset = yOffset + lineSpacing
    end

    cairo_stroke(cairo)
end


function draw_ram(x, y)
  local displayTexts = {}
  for ring_index in pairs(variables.ram_rings) do
    local breakpoints = {}
    local ring = variables.ram_rings[ring_index]
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
      16,
      0x00aa00
    )
  end
  -- Write text at center of rings
  cairo_select_font_face (cairo, "Serif", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_BOLD);
  cairo_set_source_rgba(cairo, rgba(0xffffff, variables.bg_alpha))
  cairo_set_font_size(cairo, 30)
  cairo_move_to(cairo, x - 40, y - 65)
  cairo_show_text(cairo, "MEM")
  cairo_set_font_size(cairo, 14)
  cairo_move_to(cairo, x - 140, y - 38)
  cairo_show_text(cairo, "RAM " .. displayTexts[1])
  cairo_set_source_rgba(cairo, rgba(0xc6c6c6, variables.bg_alpha))
  cairo_move_to(cairo, x - 140, y - 23)
  cairo_show_text(cairo, "SWAP " .. displayTexts[2])
  cairo_stroke(cairo)
end


function draw_cpu(x, y)
  for ring_index in pairs(variables.cpu_rings) do
    local breakpoints = {}
    local ring = variables.cpu_rings[ring_index]
    local value = evaluate(ring.command)
    if value ~= nil then
      table.insert(breakpoints, value)
    end
    draw_ring(
      cairo,
      x,
      y - 53,
      168 - ring_index * 10,
      breakpoints,
      ring.max,
      ring_index,
      8,
      0xaa0000
    )
  end
  -- Write text at center of rings
  cairo_select_font_face (cairo, "Serif", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_BOLD);
  cairo_set_source_rgba(cairo, rgba(0xffffff, variables.bg_alpha))
  cairo_set_font_size(cairo, 40)
  cairo_move_to(cairo, x - 43, y - 50)
  cairo_show_text(cairo, "CPU")
  cairo_set_font_size(cairo, 20)
  cairo_move_to(cairo, x - 230, y - 30)
  cairo_show_text(cairo, "AMD Ryzen 7 5800X 8-Core")
  cairo_stroke(cairo)
 -- ${goto 540} ${execi 1000 grep model /proc/cpuinfo | cut -d : -f2 | tail -1 | sed 's/\s//' | sed "s/\bProcessor\b//g"}
end





