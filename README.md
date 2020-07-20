# Widgets for springrts

## Purpose of cmd_middle_mouse_button.lua:
This widget should avoid camera blocked with only few capacity to move when middle mouse button is clicked with overhead camera mode or fps camera mode or rot overhead camera mode, and if middle mouse button is not holded. But by enabling this widget, it should disable for you the possibility, at least in overhead camera mode, to navigate on map by holding middle mouse button.
(This behaviour of "blocked camera" could occur with overhead camera mode or fps camera mode or rot overhead camera mode, and if middle mouse button is not holded.)

## Purpose of cmd_selfd_mines_for_some_units.lua:
Should resolve mines that sometimes which sometimes don't explode with BA 9 (from years). This widget give a self-d command for mines when an enemy is near, except if enemy speed > 120, (for example the jeffys or fleas or planes) or if the mine is put on wait
Widget not needed to fix mines for BA 10.24 or BA test cause it seemed the mines were already fixed for ba10.24. And I didn't saw an option to put mines hold fire for BA 10.24, so this widget should not work for BA 10.24.

## Installation:
For made theses widgets to works, 
- if you are under windows, you should put them in C:\Users\your_current_account_name\Documents\My Games\Spring\LuaUI\Widgets.
- if you are under linux, I'm unsure, but I think you should put it in ~./spring/LuaUI/Widgets

You should see the widgets ingame in the list after pressed the F11 key.
Widget should appears after the widgets wrote with an asterisk at the end.
