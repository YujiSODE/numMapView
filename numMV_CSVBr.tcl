#numMapView
#numMV_CSVBr.tcl
##===================================================================
#	Copyright (c) 2020 Yuji SODE <yuji.sode@gmail.com>
#
#	This software is released under the MIT License.
#	See LICENSE or http://opensource.org/licenses/mit-license.php
##===================================================================
#Numerical map viewer
#CSV-formatted file output interface for "numMapView.tcl" using Braille Pattern
#
#=== Synopsis ===
# - `numMV_CSVBr map width res command ?name?;`
#  	procedure that returns map view in CSV format using Braille Pattern
# 	- $map: a numerical list or CSV formatted values
# 	- $width: a positive integer value ($width > 1) that is set as width of map
# 	- $res: a positive integer value ($res > 2) that is set as resolution of map
# 	- $command: text that is composed of separator ">" and four functions N, S, E and W e.g., "N(1,2)>S(1,2,30)>W(1,2,10,-1)"
# 	- $name: an optional name of file to output
#
#  	**functions in $command**
# 	- `N(x,y?,z?,void??)`: the northern view
# 	- `S(x,y?,z?,void??)`: the southern view
# 	- `E(x,y?,z?,void??)`: the eastern view
# 	- `W(x,y?,z?,void??)`: the western view
#
# 		- $x and $y: integer coordinates of the current points (x,y)
# 		- $z: an optional value to replace value of a point (x,y)
# 		- $void: an optional value to replace voids in map, which has a default value of 0
#
##===================================================================
#
set auto_noexec 1;
package require Tcl 8.6;
#
source -encoding utf-8 numMapView.tcl;
source -encoding utf-8 numMV_brMap.tcl;
#
#procedure that returns map view in CSV format using Braille Pattern
proc numMV_CSVBr {map width res command {name {}}} {
	# - $map: a numerical list or CSV formatted values
	# - $width: a positive integer value ($width > 1) that is set as width of map
	# - $res: a positive integer value ($res > 2) that is set as resolution of map
	# - $command: text that is composed of separator ">" and four functions N, S, E and W e.g., "N(1,2)>S(1,2,30)>W(1,2,10,-1)"
	# - $name: an optional name of file to output
	#
	#**functions in $command**
	# - `N(x,y?,z?,void??)`: the northern view
	# - `S(x,y?,z?,void??)`: the southern view
	# - `E(x,y?,z?,void??)`: the eastern view
	# - `W(x,y?,z?,void??)`: the western view
	#
	#   - $x and $y: integer coordinates of the current points (x,y)
	#   - $z: an optional value to replace value of a point (x,y)
	#   - $void: an optional value to replace voids in map, which has a default value of 0
	###
	#
	#loading map data
	::numMV::load $map $width;
	#resolution setting
	::numMV::setResolution $res;
	#adding four functions which return view into Tcl expressions
	::numMV::setExpression;
	#
	#--- Syntax error is returned when $command has unavailable characters ---
	if {[regexp {[^0-9NSEWe.,()>+-]} $command]} {error "Error: syntax error in \"$command\"";};
	###
	#list for results
	set results {};
	#
	lappend results "\"$::numMV::INFO\"";
	lappend results "\"$command\"";
	#list of functions
	#
	foreach e [split $command >] {
		lappend results "\"[::brmap::brMap [expr $e]]\"";
	};
	set results [join $results ,];
	#
	#CSV formatted file is output when output file name is given
	if {[llength $name]>0} {
		set C [open $name w];
		fconfigure $C -encoding utf-8;
		puts -nonewline $C $results;
		close $C;
		unset C;
	};
	#
	return $results;
};
######## test code #########
#sample map: imaginaryLandform_20180601.tcl (Yuji SODE, 2018; https://gist.github.com/YujiSODE/04348f5f81ae4276118179143ec56ffd)
#source imaginaryLandform_20180601.tcl;
#set cmd "N(1,3)>S(5,0)>E(3,4)";
#numMV_CSV $V 19 15 $cmd csvSample.csv;
#
#=== error sample ===
#set cmd "n(1,3)>S(5,0)>E(3,4)";
