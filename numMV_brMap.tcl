#numMapView
#numMV_brMap.tcl
##===================================================================
#	Copyright (c) 2019 Yuji SODE <yuji.sode@gmail.com>
#
#	This software is released under the MIT License.
#	See LICENSE or http://opensource.org/licenses/mit-license.php
##===================================================================
#Tool that shows mapping data using Braille Pattern.
#
#this program is originally derived from:
#	brMap-0.1/brMap.tcl (Yuji SODE, 2019; https://github.com/YujiSODE/brMap)
#
#=== Synopsis ===
#`::brmap::brMap map;`
#
#--- Parameters ---
# - $map: text map that is composed of 0, 1 and newline character (Unicode U+00000A)
##===================================================================
#
set auto_noexec 1;
package require Tcl 8.6;
#=== <namespace: brmap> ===
namespace eval ::brmap {
	#=== map data ===
	variable MAP {};
	#
	#=== brailleGen/brailleGen_min.tcl (Yuji SODE, 2018-2019); the MIT License: https://gist.github.com/YujiSODE/e3453d43e9733e933c64c52eca45bcfe ===
	#procedure that generates Braille Pattern using a list of Braille dot numbering
	proc brailleGen {list} {set n [llength $list];if {$n<1||$n>8} {return -code error "ERROR: invalid list size";};set idx [list 0 1 2 4 8 16 32 64 128];set s 10240;foreach e [lsort -unique $list] {if {$e<0||$e>8} {return -code error "ERROR: invalid element in list";};set e [expr {int($e)}];set s [expr {$s+[lindex $idx $e]}];};return [subst "\\u[format %x $s]"];};
	#
	#procedure that loads given text map
	proc setMap {txtMap} {
		# - $txtMap: text map that is composed of 0, 1 and newline character (Unicode U+00000A)
		variable ::brmap::MAP;
		set MAP [lmap e [split $txtMap \n] {split $e {};}];
	};
	#
	#procedure that reads using 4x2 cells and returns a unicode Braille character
	#4x2 cell is determined using topleft cell of (x0, y0)
	proc cell {x0 y0} {
		# - $x0 and $y0: cell indices
		variable ::brmap::MAP;
		set c {};
		set c0 0;
		set x0 [expr {int($x0)}];
		set y0 [expr {int($y0)}];
		#
		#+++ 4x2 cells +++
		#--- c1 ---
		set c0 [lindex $MAP [list $y0 $x0]];
		#replacing 0 for empty
		set c0 [expr {[llength $c0]>0?$c0:0}];
		lappend c [expr {int($c0)>0?1:0}];
		#
		#--- c2 ---
		set c0 [lindex $MAP [list [expr {$y0+1}] $x0]];
		#replacing 0 for empty
		set c0 [expr {[llength $c0]>0?$c0:0}];
		lappend c [expr {int($c0)>0?2:0}];
		#
		#--- c3 ---
		set c0 [lindex $MAP [list [expr {$y0+2}] $x0]];
		#replacing 0 for empty
		set c0 [expr {[llength $c0]>0?$c0:0}];
		lappend c [expr {int($c0)>0?3:0}];
		#
		#--- c4 ---
		set c0 [lindex $MAP [list $y0 [expr {$x0+1}]]];
		#replacing 0 for empty
		set c0 [expr {[llength $c0]>0?$c0:0}];
		lappend c [expr {int($c0)>0?4:0}];
		#
		#--- c5 ---
		set c0 [lindex $MAP [list [expr {$y0+1}] [expr {$x0+1}]]];
		#replacing 0 for empty
		set c0 [expr {[llength $c0]>0?$c0:0}];
		lappend c [expr {int($c0)>0?5:0}];
		#
		#--- c6 ---
		set c0 [lindex $MAP [list [expr {$y0+2}] [expr {$x0+1}]]];
		#replacing 0 for empty
		set c0 [expr {[llength $c0]>0?$c0:0}];
		lappend c [expr {int($c0)>0?6:0}];
		#
		#--- c7 ---
		set c0 [lindex $MAP [list [expr {$y0+3}] $x0]];
		#replacing 0 for empty
		set c0 [expr {[llength $c0]>0?$c0:0}];
		lappend c [expr {int($c0)>0?7:0}];
		#
		#--- c8 ---
		set c0 [lindex $MAP [list [expr {$y0+3}] [expr {$x0+1}]]];
		#replacing 0 for empty
		set c0 [expr {[llength $c0]>0?$c0:0}];
		lappend c [expr {int($c0)>0?8:0}];
		#+++++++++++++++++
		return [::brmap::brailleGen $c];
	};
	#
	###############
	# MAIN SCRIPT #
	###############
	proc brMap {txtMap} {
		# - $txtMap: text map that is composed of 0, 1 and newline character (Unicode U+00000A)
		variable ::brmap::MAP;
		set i 0;set j 0;
		set map {};
		#--- load map data ---
		::brmap::setMap $txtMap;
		#W and H are map width and height to scan
		set W [llength [lindex $MAP 0]];
		set H [llength $MAP];
		#--- scanning map data ---
		while {$j<$H} {
			append map [expr {$j>0?"\n":{}}];
			set i 0;
			while {$i<$W} {
				append map [::brmap::cell $i $j];
				incr i 2;
			};
			incr j 4;
		};
		return $map;
	};
};
