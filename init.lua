local awful = require( "awful" )
local wibox = require( "wibox" )
local beautiful = require("beautiful")
local gears = require( "gears" )

local capi = {
  client = client
  , mouse = mouse
  , root = root
}

local launcher = {}
local launcher_item = nil
local apps = nil
local list_launch = {}
local tag_groups = {}
local focus_color

function set_focus_color()
  local hex_color_match = "[a-fA-F0-9][a-fA-F0-9]"
  local channels1 = beautiful.fg_focus:gmatch(hex_color_match)
  local channels2 = beautiful.bg_focus:gmatch(hex_color_match)
  local ratio = 0.5
  local result = "#"
  for _ = 1,3 do
      local bg_numeric_value = math.ceil(
        tonumber("0x"..channels1())*ratio +
        tonumber("0x"..channels2())*(1-ratio)
      )
      if bg_numeric_value < 0 then bg_numeric_value = 0 end
      if bg_numeric_value > 255 then bg_numeric_value = 255 end
      result = result .. string.format("%02x", bg_numeric_value)
  end
  focus_color = result
end

function launcher:set_tag_groups( tbl )
  awful.screen.focused().selected_tag.name = tbl[1]
  tag_groups = tbl
end

local function check_list_item(c)
  for pos = 1 , #apps do
    if string.match( c.class , apps[ pos ][ 1 ] ) or string.match( c.name , apps[ pos ][ 1 ] ) then
      return pos
    end
  end
  return 0
end

local function get_cnt( class )
  local cnt = 0
  for _, cl in ipairs ( capi.client.get() ) do
    if ( cl.class == class ) then
      cnt = cnt + 1
    end
  end
  return cnt
end

local function set_launcher_item( image, pos )
  local child = nil

  if launcher_item.children[ pos ] then
    child = launcher_item.children[ pos ]
  else
    layout = wibox.layout.fixed.horizontal()
    layout:add( image )
    local margin = wibox.container.margin( layout)
    child = wibox.container.background( margin )
    launcher_item:add( child )
  end

  child.children[1].left = 4
  child.children[1].right = 4

  child.bg = beautiful.bg_normal

  child.children[1].children[1].children[1]:buttons(
    awful.util.table.join( awful.button( { } , 1 , function()
      awful.spawn.with_shell( apps[ pos ][ 2 ] )
    end ) )
  )
end

function launcher:create ( arg_apps )
  set_focus_color()
  apps = arg_apps
  launcher_item = wibox.widget{
    layout = wibox.layout.fixed.horizontal
  }
  for pos = 1 , #apps do
    set_launcher_item( wibox.widget.imagebox( apps[ pos ][3]), pos )
  end

  return launcher_item
end

local function set_decoration( class, flg )
  local button = launcher_item.children[ list_launch[ class ] ]
  if button == nil then return end

  if flg == 0 then
    button.bg = focus_color
  elseif flg == 1 then
    button.bg = beautiful.bg_focus
  elseif flg == 2 then
    button.bg = beautiful.bg_urgent
  elseif flg == 3 then
    button.bg = beautiful.bg_minimize
  end

end

local function set_button( c, icon )
  icon:buttons( awful.util.table.join(
    awful.button( { } , 1 , function()

      if capi.client.focus == c then
        c.minimized = true
      else
        capi.client.focus = c
        local tag = client.focus.first_tag.index
        capi.mouse.screen.tags[ tag ]:view_only()
      end
    end ) ) )
end

local function set_cnt( class )
  local button = launcher_item.children[ list_launch[ class ] ].children[1].children[1]
  if #button.children > 1 then
    button:remove( 2 )
  end

  local cnt = get_cnt( class )
  if cnt > 1 then
    button:add( wibox.widget.textbox() )
    button.children[2]:set_text( cnt )
  end
end

local function mouse_event( class, button, proc )
  while #button.children > 1 do
    button:remove( 2 )
  end

  local clients = capi.client.get()
  table.sort( clients, function( a, b ) return a.window < b.window end )

  local flg_disable_first = false

  for _, cl in ipairs ( clients ) do
    if ( cl.class == class ) then
      if flg_disable_first then
        local pos = check_list_item( cl )
        if pos == 0 and cl.icon then
          button:add( wibox.widget.imagebox( cl.icon ) )
        elseif pos == 0 then
          button:add( wibox.widget.imagebox( beautiful.awesome_icon ))
        else
          button:add( wibox.widget.imagebox( apps[ pos ][3] ))
        end
      end
      set_button( cl, button.children[ #button.children ] )

      if proc == false then
        break
      end
      flg_disable_first = true
    end
  end
  if proc == false then
    set_cnt( class )
  end
end

local function set_mouse_event( class )
  local button = launcher_item.children[ list_launch[ class ] ].children[1].children[1]

  button:connect_signal( "mouse::enter" , function()
    mouse_event( class, button , true )
  end)
  button:connect_signal( "mouse::leave" , function()
    mouse_event( class, button , false )
  end)
end

local function unmanage_tag()
  for _,t in pairs( awful.screen.focused().selected_tags ) do
    if #t:clients() == 0 then
      t:delete()
    end
  end
end

local function manage_tag(c)
  for _,t in pairs( capi.root.tags() ) do
    if c.class == t.name or c.name == t.name then
      c:tags({t})
      return
    end
  end
  for _,g in pairs( tag_groups ) do
    if string.match( c.class , g ) or string.match( c.name , g ) then
      local t = awful.tag.add(c.class,{
        layout = awful.layout.suit.tile,
        screen = c.screen
      })
      c:tags({t})
    end
  end
end

local function manage(c)

  if list_launch[ c.class ] == nil then
    local pos = check_list_item(c)
    if pos == 0 then
      if c.icon then
        set_launcher_item( wibox.widget.imagebox( c.icon ), pos )
      else
        set_launcher_item( wibox.widget.imagebox( beautiful.awesome_icon ), pos )
      end
      list_launch[ c.class ] = #launcher_item.children
    else
      list_launch[ c.class ] = pos
    end
  end

  if capi.client.focus == c then
    set_decoration( c.class, 0 )
  else
    set_decoration( c.class, 1 )
  end

  if get_cnt( c.class ) == 1 then
    set_button( c, launcher_item.children[ list_launch[ c.class ] ].children[1].children[1].children[1] )
    set_mouse_event( c.class )
    manage_tag(c)
  else
    set_cnt( c.class )
  end
end

local function unmanage(c)
  local pos = check_list_item(c)
  if get_cnt( c.class ) == 0 and pos == 0 then
    launcher_item:remove( list_launch[ c.class ] )
    list_launch[ c.class ] = nil
  elseif get_cnt( c.class ) == 0 and pos > 0 then
    set_launcher_item( wibox.widget.imagebox( apps[ pos ][3]), pos )
  else
    set_cnt( c.class )
  end
  unmanage_tag()
end

local function unfocus(c)
  set_decoration( c.class, 1 )
  if c.floating then
    c.ontop = false
  end
end

local function focus(c)
  set_decoration( c.class, 0 )
  if c.floating then
    c.ontop = true
  end
end

local function urgent(c)
  set_decoration( c.class, 2 )
end

local function get_next_tag( flg )
  local current_tag = capi.client.focus.first_tag.index
  local clients = capi.client.get()

  local tags = {}

  local fnd = false
  for _,c in ipairs( clients ) do
    table.insert(tags, c.first_tag.index)
  end

  if flg then
    table.sort(tags, function(a, b) return a < b end)
  else
    table.sort(tags, function(a, b) return a > b end)
  end

  local found = false
  local result = 0
  for _,t in ipairs( tags ) do
    if result == 0 and t ~= current_tag then
      result = t
    end
    if found == false and t == current_tag then
      found = true
    elseif found == true and t ~= current_tag then
      result = t
      break
    end
  end
  return result
end

local function tag_rotate( flg )
  local next_tag = get_next_tag( flg )
  capi.mouse.screen.tags[ next_tag ]:view_only()
end

function launcher:tag_next ()
  tag_rotate( true )
end

function launcher:tag_previous()
  tag_rotate( false )
end

function launcher:tag_change( i )
  for _, c in ipairs ( capi.client.get() ) do
    if c.class == apps[ i ][ 1 ] then
      capi.mouse.screen.tags[ c.first_tag.index ]:view_only()
      return
    end
  end
  awful.spawn.with_shell( apps[ i ][ 2 ] )
end

local function move_to_tag( flg )
  local next_tag = get_next_tag( flg )
  local tag = capi.client.focus.screen.tags[ next_tag ]
  capi.client.focus:move_to_tag( tag )
  tag:view_only()
  unmanage_tag()
end

function launcher:move_to_next_tag ()
  move_to_tag( true )
end

function launcher:move_to_previous_tag()
  move_to_tag( false )
end

function launcher:move_to_new_tag ()
  local c = capi.client.focus
  local t = awful.tag.add(c.class,{
    layout = awful.layout.suit.tile,
    screen = c.screen
  })
  c:tags({t})
  t:view_only()
end

function launcher:launch ( i )
    awful.spawn.with_shell( apps[ i ][ 2 ] )
end

local function set_shape( c )
  local button = launcher_item.children[ list_launch[ c.class ] ]

  if button == nil then return end

  if c.floating or c.ontop or c.maximized then
    button.shape = gears.shape.rectangle
  elseif button.shape then
    button.shape = nil
  end
  button.shape_border_width = 2

  if c.floating and c.ontop and c.maximized then
    button.shape_border_color = beautiful.fg_normal

  elseif c.floating and c.ontop then
    button.shape_border_color = beautiful.bg_normal

  elseif c.floating and c.maximized then
    button.shape_border_color = beautiful.bg_urgent

  elseif c.ontop and c.maximized then
    button.shape_border_color = beautiful.fg_normal

  elseif c.floating then
    button.shape_border_color = beautiful.border_marked

  elseif c.ontop then
    button.shape_border_color = beautiful.fg_normal

  elseif c.maximized then
    button.shape_border_color = beautiful.bg_urgent
  end

end

function ontop(c)
  set_shape( c )
end
function floating(c)
  set_shape( c )
end
function maximized(c)
  set_shape( c )
end
function minimized(c)
  if c.minimized then
    set_decoration( c.class, 3 )
  else
    set_decoration( c.class, 0 )
  end
end

capi.client.connect_signal( "manage"             , function(c) manage(c)    end)
capi.client.connect_signal( "unmanage"           , function(c) unmanage(c)  end)
capi.client.connect_signal( "unfocus"            , function(c) unfocus(c)   end)
capi.client.connect_signal( "focus"              , function(c) focus(c)     end)
capi.client.connect_signal( "property::urgent"   , function(c) urgent(c)    end)
capi.client.connect_signal( "property::ontop"    , function(c) ontop(c)     end)
capi.client.connect_signal( "property::floating" , function(c) floating(c)  end)
capi.client.connect_signal( "property::maximized", function(c) maximized(c) end)
capi.client.connect_signal( "property::minimized", function(c) minimized(c) end)

return launcher
