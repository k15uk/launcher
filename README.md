launcher for awesomewm
=====================

This plugin is provides awesome window manager. with the ability to integrate a tasklist, tagbar, and quick launch list.

Welcome submissions to ISSUE, including questions and suggestions for improvement.

## USAGE

1. require

  ``` lua
  local launcher = require( 'launcher' )
  ```

1. add a quick launch list

  ``` lua
  launcher:create( {
    { 'Chromium'           , 'chromium'       , '/usr/share/icons/hicolor/48x48/apps/chromium.png'         , false } ,
    { 'Mysql-workbench-bin', 'mysql-workbench', '/usr/share/icons/hicolor/48x48/apps/mysql-workbench.png'  , false } ,
    { 'Gimp'               , 'gimp'           , '/usr/share/icons/hicolor/48x48/apps/gimp.png'             , false } ,
    { 'LibreOffice'        , 'libreoffice'    , '/usr/share/icons/hicolor/48x48/apps/libreoffice-calc.png' , false } ,
    { 'Evolution'          , 'evolution'      , '/usr/share/icons/hicolor/48x48/apps/evolution-mail.png'   , false } ,
  } ),
  ```

1. set verical margin ( optional )

  ``` lua
  launcher:set_vertical_margin( 5 )
  ```

  default is 2px. example is 5px.

1. set tag groups ( optional )

  Applicarions in the list create individual tags at startup.

 ``` lua
  local tag_groups = {
    "Gimp" , "Inkscape" ,
    "Mysql-workbench-bin" ,
    "Rhythmbox" , "Easytag" ,
    "Evolution" ,
    "LibreOffice",
  }

  launcher:set_tag_groups( tag_groups )
  ```

5. set wibox ( example )

  ``` lua
  s.mywibox:setup {
      layout = wibox.layout.align.horizontal,
      { -- Left widgets
          layout = wibox.layout.fixed.horizontal,
          mylauncher,
          s.mypromptbox,
      },
      launcer,
      { -- Right widgets
          layout = wibox.layout.fixed.horizontal,
          mykeyboardlayout,
          wibox.widget.systray(),
          mytextclock,
          s.mylayoutbox,
      },
  }
  ```

6. set keybind

  ``` lua
  awful.key( { sup , shift } , "Escape" , function () launcher:tag_previous() end ),
  awful.key( { sup         } , "Escape" , function () launcher:tag_next() end ),
  awful.key( { alt , shift } , "Escape" , function () launcher:move_to_previous_tag() end ),
  awful.key( { alt         } , "Escape" , function () launcher:move_to_next_tag() end ),
  awful.key( { sup         } , "space"  , function () launcher:move_to_new_tag() end ),

  for i = 1,9 do
    awful.key( { sup } ,  "#" .. i + 9 , function () launcher:launch( i ) end )
  end
  ```

* tag_previous()/tag_next()

  switch the tag. prev/next.

* move_to_previous/next_tag()

  move the tag. prev/next.

* move_to_new_tag()

  move the tag, after create new tag.

* launch( <number> )

  launch application.
  <number> is quick launch list's index.
