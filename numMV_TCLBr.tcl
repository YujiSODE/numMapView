#numMapView
#numMV_TCLBr.tcl
##===================================================================
#	Copyright (c) 2020 Yuji SODE <yuji.sode@gmail.com>
#
#	This software is released under the MIT License.
#	See LICENSE or http://opensource.org/licenses/mit-license.php
##===================================================================
#Tcl file output interface for "numMapView.tcl" using Braille Pattern
#
#=== Synopsis ===
# - `numMV_TCLBr map width res command ?name?;`
# 	procedure that returns map view as Tcl file using Braille Pattern
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
# 	output tcl file has two procedures: "var_numMV" and "preview_numMV"
# 	- `var_numMV`: procedure returns a list of views
# 	- `preview_numMV ?delay`: procedure shows simulation views
# 	 	- $delay: delay in milliseconds with default value of 250
#
##===================================================================
#
set auto_noexec 1;
package require Tcl 8.6;
#
source -encoding utf-8 numMapView.tcl;
source -encoding utf-8 numMV_brMap.tcl;
#
#procedure that returns map view as Tcl file using Braille Pattern
proc numMV_TCLBr {map width res command {name {}}} {
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
	#results
	set R {};
	set results "\#$::numMV::INFO\n\#$command";
	#
	#list of function results
	foreach e [split $command >] {
		lappend R [::brmap::brMap [expr $e]];
	};
	#
	#--- script for proc var_numMV ---
	append results "\n\#procedure returns a list of views";
	append results "\nproc var_numMV \{\} \{return \[list $R\];\}\;";
	#
	#--- script for proc preview_numMV ---
	#it shows simulation views
	proc numMV_PREVIEW {{delay 250}} {
		# - $delay: delay in milliseconds with default value of 250
		set delay [expr {int($delay)}];
		#Clearing display
		puts stdout "\u1b\[2J";
		foreach e [var_numMV] {puts -nonewline stderr "\u1b\[1;1H$e";after $delay;};
		puts stdout "\n\#===";
	};
	#
	append results "\n\#procedure shows simulation views";
	append results "\n\#\$delay is delay in milliseconds with default value of 250";
	append results "\nproc preview_numMV \{\{delay 250\}\} \{[info body numMV_PREVIEW]\}\;";
	#
	#Tcl file is output when output file name is given
	if {[llength $name]>0} {
		set C [open $name w];
		fconfigure $C -encoding utf-8;
		puts -nonewline $C $results;
		close $C;
		unset C;
	};
	#
	return $R;
};
######## test code #########
#sample map: imaginaryLandform_20180601.tcl (Yuji SODE, 2018; https://gist.github.com/YujiSODE/04348f5f81ae4276118179143ec56ffd)
#source imaginaryLandform_20180601.tcl;
#
#set y 8;
#set i 1;set cmd "E(0,$y)";
#while {$i<18} {append cmd ">E($i,$y)";incr i 1;};
#
### error sample ###
#set cmd "n(1,3)>S(5,0)>E(3,4)";
###
#run test code
#numMV_TCLBr $V 19 20 $cmd sample.tcl;
#source -encoding utf-8 sample.tcl;
#preview_numMV 500;
