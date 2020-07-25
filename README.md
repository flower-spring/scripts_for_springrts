# 3 widgets for springrts

## Purpose of cmd_middle_mouse_button.lua:
This widget should avoid camera blocked with only few capacity to move when middle mouse button is clicked with overhead camera mode or fps camera mode or rot overhead camera mode, and if middle mouse button is not holded. But by enabling this widget, it should disable for you the possibility, at least in overhead camera mode, to navigate on map by holding middle mouse button.
(This behaviour of "blocked camera" could occur with overhead camera mode or fps camera mode or rot overhead camera mode, and if middle mouse button is not holded.)

## Purpose of cmd_selfd_mines_for_some_units.lua:
It should resolve mines which sometimes didn't explode with BA 9 (from years). This widget give a self-d command for mines when an enemy is near, except if enemy speed > 120, (for example the jeffys or fleas or planes) or if the mine is put on wait.

Widget not really needed to fix mines for BA 10.24 or BA test cause it seemed the mines were already fixed for ba10.24. And I didn't saw an option to put mines on wait for BA 10.24 (while it was possible for ba 9* or 11), so this widget should not completly work for BA 10.24. 

I tested impact of this widget for fps and didn't saw significative impact. And with widget profiler, percent was about 0 for total percentage of running time spent in luaui callins, and about 1kB/s for 300 armmine3 total rate of mem allocation by luaui callins.  
  
  
  

## Purpose of cmd_set_specific_targets_for_mercuries_and_screamers.lua:
Auto set target for mercuries and screamers to certains planes hierarchically (to better avoid a liche attack for example).
By order :
1.liches/krows\
2.bombers/seabombers, torpedo bombers  
3.radars t2 planes  
4.brawlers  
5.construction aircraft  
  
    

# Installation of these widgets under windows / linux:
For made theses widgets to works, 
- if you are under windows, you should put them in C:\Users\your_current_account_name\Documents\My Games\Spring\LuaUI\Widgets.
- if you are under linux, I'm unsure, but I think you should put it in ~./spring/LuaUI/Widgets

You should see the widgets ingame in the list after pressed the F11 key.
New widget(s) should appear(s) after the widgets wrote with an asterisk at the end.
