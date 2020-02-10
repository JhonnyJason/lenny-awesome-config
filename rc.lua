-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")

-- does not reside inside the default awesome 4.0 config rc.lua
-- awful.rules = require("awful.rules")

-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup").widget


-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init("~/.config/awesome/lenny-theme/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "lxterminal"
editor = "code"
editor_cmd = editor

screenAdjust = "~/.config/awesome/lenny-theme/screen-adjust.sh"
editAwesomeConfig = "code -n .config/awesome/" -- obviously cwd is ~ when spawning ;-)

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts =
{
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.floating
}

menubar.utils.terminal = terminal -- Set the terminal for applications that require it

awful.spawn(terminal)
awful.spawn(terminal)
awful.spawn.with_shell(screenAdjust)






screenSpawningRule = { 
    rule = { }, 
    properties = { 
        maximized = false,
        screen = 1,
        floating = false,
        focus = true
    } 
}

local function adjustScreenSpawningRule(screenIndex)
    if type(screenIndex) ~= "number" then
        -- naughty.notify({ preset = naughty.config.presets.normal,
        -- title = "FYI",
        -- text = "We noticed this is not a number!"})
        return
    end
    -- naughty.notify({ preset = naughty.config.presets.normal,
    -- title = "FYI",
    -- text = "I set the screenSpawningRule to have screen: " .. tostring(screenIndex)})

    screenSpawningRule.properties.screen = screenIndex
end

local function assertMouseIsInFocusedScreen(c)

    -- naughty.notify({ preset = naughty.config.presets.normal,
    -- title = "FYI",
    -- text = "mouse is in: " .. mouse.screen.index .. " and focus is on: " .. c.screen.index})

    if mouse.screen.index == c.screen.index then return end

    -- naughty.notify({ preset = naughty.config.presets.normal,
    -- title = "FYI",
    -- text = "We should use the force!"})

    -- use the force sloppily to make mouse move on that screen
    awful.screen.focus(c.screen)
end

-- {{{ All Wiboxes
---------------------------------------------------------------------------------------------

-- Wallpaper
local function init_screen(s)
    -- hide all panels
    if s.screenToppanel then s.screenToppanel.visible = false end
    if s.screenLeftpanel then s.screenLeftpanel.visible	 = false end
    if s.screenBottompanel then s.screenBottompanel.visible = false end

    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

screen.connect_signal("property::geometry", init_screen)

-- Create a textclock widget as global widget because it is the same for each screen
mytextclock = awful.widget.textclock()

--mytaglist.buttons = awful.util.table.join(
local taglist_buttons = awful.util.table.join(
                    awful.button({ }, 1, function(t) t:view_only() end),
                    awful.button({ modkey }, 1, 
                                          function(t)
                                              if client.focus then
                                                  client.focus:move_to_tag(t)
                                              end
                                          end),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, 
                                          function(t)
                                            if client.focus then
                                              client.focus:toggle_tag(t)
                                            end
                                          end),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
                    )

--mytasklist = {}
--mytasklist.buttons = awful.util.table.join(
local tasklist_buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() and c.first_tag then
                                                      c.first_tag:view_only()
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              -- showing the menu? / not for me :-)
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))


-- set up all the screens, by attaching

awful.screen.connect_for_each_screen(
  function(s) 
    --give every screen it's own tag "table"
    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])
    
    --layoutbox every screen has it's own current layout - layoutbox is indicating the current layout
    s.screenLayoutbox = awful.widget.layoutbox(s)
    s.screenLayoutbox:buttons(
        awful.util.table.join(
            awful.button({ }, 1, function () awful.layout.inc( 1) end),
            awful.button({ }, 3, function () awful.layout.inc(-1) end),
            awful.button({ }, 4, function () awful.layout.inc( 1) end),
            awful.button({ }, 5, function () awful.layout.inc(-1) end)
          )
      )

    --create taglist widget
    s.screenTaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, taglist_buttons)

    --create tasklist widget
    s.screenTasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, tasklist_buttons)

    --create the panels 
    s.screenBottompanel = awful.wibar({ position = "bottom", screen = s })
    s.screenLeftpanel = awful.wibar({ position = "left", screen = s })
    s.screenToppanel = awful.wibar({ position = "top", screen = s })

    -- the leftpanel
    -- not yet any entries here...
    s.screenLeftpanel:setup {
      layout = wibox.layout.fixed.vertical,
      {
          layout = wibox.layout.fixed.horizontal,
          wibox.widget{
            markup = tostring(s.index),
            align  = 'center',
            valign = 'center',
            widget = wibox.widget.textbox
        }
      },
    --   nil,
      nil,
      nil
    }

    -- the bottompanel
    s.screenBottompanel:setup {
      layout = wibox.layout.align.horizontal,
      { -- Left widgets^^
          layout = wibox.layout.fixed.horizontal,
          s.screenLayoutbox,
          s.screenTaglist
      },
      nil, -- Middle widget
      { -- Right widgets
          layout = wibox.layout.fixed.horizontal,
          mytextclock
      }
    }

    -- the toppanel
    s.screenToppanel:setup {
      layout = wibox.layout.align.horizontal,
      { -- Left widgets
          layout = wibox.layout.fixed.horizontal,
          s.screenTasklist
      },
      nil, -- Middle widget
      nil -- Right widget
    }
    init_screen(s)

  end
)


-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),

    -- navigation
	awful.key({ modkey,           }, "w",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "s",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,			  }, "a", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey,			  }, "d", function () awful.screen.focus_relative(-1) end),
    
    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    
    -- Standard program
    awful.key({ modkey,           }, "t", 
      function ()
        adjustScreenSpawningRule(mouse.screen.index)
        awful.spawn(terminal) 
      end
    ),
    awful.key({ modkey,           }, "´", 
      function () 
        -- TODO write this functionality on another key...^^
        -- naughty.notify({ preset = naughty.config.presets.normal,
        --                  title = "FYI",
        --                  text = "Pause key did work!" })
        awful.spawn.with_shell(screenAdjust) 
      end
    ),
    awful.key({ modkey,           }, "#", 
      function ()
        adjustScreenSpawningRule(mouse.screen.index)
        awful.spawn.with_shell(editAwesomeConfig) 
      end
    ),
    awful.key({ modkey, "Shift"   }, "^", awesome.restart),
    awful.key({ modkey, "Shift"   }, "Escape", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "Up", function () awful.layout.inc( 1) end),
    awful.key({ modkey,           }, "Down", function () awful.layout.inc(-1) end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- Menubar
    awful.key({ modkey }, "p", 
        function() 
            adjustScreenSpawningRule(mouse.screen.index)
            menubar.show() 
        end),
	
  	-- show/hide all wiboxes
  	awful.key({ modkey}, "v",
       function ()
        --check how much boxes are visible
    		local mostly_seen = 0
        if mouse.screen.screenToppanel.visible then mostly_seen = mostly_seen + 1 end
    		if mouse.screen.screenLeftpanel.visible then mostly_seen = mostly_seen + 1 end	  
    	  if mouse.screen.screenBottompanel.visible then mostly_seen = mostly_seen + 1 end
    		
        --when more then the half of them is visible hide othervise show them all
    		if mostly_seen >= 2 then
    			mouse.screen.screenToppanel.visible = false
    			mouse.screen.screenLeftpanel.visible	 = false
    			mouse.screen.screenBottompanel.visible = false
    		else
    			mouse.screen.screenToppanel.visible = true
    			mouse.screen.screenLeftpanel.visible	 = true
    			mouse.screen.screenBottompanel.visible = true
    		end
      end
    ),
  	 
    -- selective show/hide
    awful.key({ modkey}, "b",
      function ()
    		mouse.screen.screenBottompanel.visible = not mouse.screen.screenBottompanel.visible
    	end
    ),

    awful.key({ modkey}, "c",
      function ()
    		mouse.screen.screenLeftpanel.visible = not mouse.screen.screenLeftpanel.visible
    	end
    ),
    	 
    awful.key({ modkey}, "g",
      function ()
    		mouse.screen.screenToppanel.visible = not mouse.screen.screenToppanel.visible
    	end
    )
  )

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Return",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey,		      }, "Delete",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey,           }, "-",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end)--, 
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        local tag = awful.tag.gettags(screen)[i]
                        if tag then
                           awful.tag.viewonly(tag)
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      local tag = awful.tag.gettags(screen)[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.movetotag(tag)
                          end
                     end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.toggletag(tag)
                          end
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize)
)

-- Set keys
root.keys(globalkeys)
-- }}}


-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     keys = clientkeys,
                     buttons = clientbuttons } },
      screenSpawningRule    
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- Enable sloppy focus
    --c:connect_signal("mouse::enter", function(c)
    --    if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
    --        and awful.client.focus.filter(c) then
    --        client.focus = c
    --    end
    --end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end

    local titlebars_enabled = false
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
        -- buttons for the titlebar
        local buttons = awful.util.table.join(
                awful.button({ }, 1, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.move(c)
                end),
                awful.button({ }, 3, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.resize(c)
                end)
                )

        -- Widgets that are aligned to the left
        local left_layout = wibox.layout.fixed.horizontal()
        left_layout:add(awful.titlebar.widget.iconwidget(c))
        left_layout:buttons(buttons)

        -- Widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        -- The title goes in the middle
        local middle_layout = wibox.layout.flex.horizontal()
        local title = awful.titlebar.widget.titlewidget(c)
        title:set_align("center")
        middle_layout:add(title)
        middle_layout:buttons(buttons)

        -- Now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_left(left_layout)
        layout:set_right(right_layout)
        layout:set_middle(middle_layout)

        awful.titlebar(c):set_widget(layout)
    end
end)

-- awful.tag.connect_signal("request::select", function(s)

--     naughty.notify({ preset = naughty.config.presets.normal,
--     title = "FYI",
--     text = "I have been called"})

-- end)

-- client.connect_signal("property::screen", function(s)

--     naughty.notify({ preset = naughty.config.presets.normal,
--     title = "FYI",
--     text = "I have been called, screen property fo client Changed!"})

-- end)

-- screen.connect_signal("focus", function(s)

--     naughty.notify({ preset = naughty.config.presets.normal,
--     title = "FYI",
--     text = "I have been called - screen focus signal!"})

-- end)
-- client.connect_signal("mouse::enter", function(c) adjustScreenSpawningRule(c.screen.index); end)
client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus; adjustScreenSpawningRule(c.screen.index); assertMouseIsInFocusedScreen(c) end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}


-- monkey path to do some magic ;-)
local original_focus = awful.screen.focus
awful.screen.focus = function(leScreen)
    
    original_focus(leScreen)
    
    adjustScreenSpawningRule(leScreen)
    
    -- naughty.notify({ preset = naughty.config.presets.normal,
    -- title = "FYI",
    -- text = "We used the monkey magic!"})

    -- unfocus the the client when he is not in the current screen.
    -- todo    

end