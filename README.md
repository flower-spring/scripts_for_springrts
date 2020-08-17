# 3 widgets for springrts

## Purpose of cmd_middle_mouse_button.lua:
This widget should avoid camera blocked with only few capacity to move when middle mouse button is clicked with overhead camera mode or fps camera mode or rot overhead camera mode, and if middle mouse button is not holded. But by enabling this widget, it should disable for you the possibility, at least in overhead camera mode, to navigate on map by holding middle mouse button.
(This behaviour of "blocked camera" could occur with overhead camera mode or fps camera mode or rot overhead camera mode, and if middle mouse button is not holded.)
&nbsp;  

## Purpose of cmd_selfd_mines_for_some_units.lua:
For months, or rather years I saw some mines sometimes did not explode with BA 9* (or 11). This widget should resolve this.

This widget give a self-d command for the mines when an enemy is near a mine, except if enemy speed > 120, (for example the jeffys, fleas or planes have speed > 120) or except if enemy speed <120 and the mine has a wait command.

The mine should still explode if :
-an enemy is just upon the mine, the mine uncloack and the enemy fire on the mine. 
-an enemy is really near the mine, the mine uncloak and the enemy fire on the mine.
-something fire on the mine whether the mine was uncloacked or not
(If an enemy has an hold fire command and this enemy is just above an allie uncloked mine, and nothing fire on the mine, the mine should not explode)

Widget not really needed to fix mines for BA 10.24 or BA test (BA test = beyond all reason mod) cause it seemed the mines were already fixed for ba10.24 and byar. And I didn't saw an option to put mines on wait for BA 10.24 (while it was possible for ba 9* or 11), so this widget should not completly work for BA 10.24. 

Widget tested for a few weeks. No bug found.

(A link to springrts forum topic about mines bug : https://springrts.com/phpbb/viewtopic.php?f=44&t=41088&p=593857#p593857 )

(I tested impact of this widget for fps and didn't saw significative impact. According to widget profiler widget, percent was about 0 for total percentage of running time spent in luaui callins, and about 1kB/s for 300 armmine3 total rate of mem allocation by luaui callins. Defense range was something like 300kB/s at start.)
&nbsp;  

## Purpose of cmd_set_specific_targets_for_mercuries_and_screamers.lua:
Auto set target for mercuries and screamers to certains planes hierarchically (to better avoid a liche attack for example).
By order :
1.liches/krows\
2.bombers/seabombers, torpedo bombers  
3.radars t2 planes  
4.brawlers  
5.construction aircraft  
&nbsp;  

# Installation of these widgets under windows / linux:
For made theses widgets to works, 
- if you are under windows, you should put them in C:\Users\your_current_account_name\Documents\My Games\Spring\LuaUI\Widgets.
- if you are under linux, I'm unsure, but I think you should put it in ~./spring/LuaUI/Widgets

You should see the widgets ingame in the list after pressed the F11 key.
New widget(s) should appear(s) after the widgets wrote with an asterisk at the end.
