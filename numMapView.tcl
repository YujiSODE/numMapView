#numMapView
#numMapView.tcl
##===================================================================
#	Copyright (c) 2020 Yuji SODE <yuji.sode@gmail.com>
#
#	This software is released under the MIT License.
#	See LICENSE or http://opensource.org/licenses/mit-license.php
##===================================================================
#Numerical map viewer
#
#=== Synopsis ===
# - `::numMV::load map width;`
# 	procedure that loads a numerical map and returns information of the given map
# 	- $map: a numerical list
# 	- $width: a positive integer value ($width > 1) that is set as width of map
#
# - `::numMV::setResolution res;`
# 	procedure to set resolution
# 	- $res: a positive integer value ($res > 2) that is set as resolution of map
#
# - `::numMV::getMapPoint x y ?void?;`
# 	procedure that returns a value of a point in numerical map using integer coordinates
# 	- $x and $y: integer coordinates
# 	- $void: an optional value to replace voids in map, which has a default value of 0
#
# - `::numMV::atan_0pi x0 y0 x1 y1 ?void? ?z0?;`
# 	procedure that returns a modified value of arc tangent in radians
# 	returned value is in [0,pi]
# 	- $x0, $y0, $x1 and $y1: integer coordinates for different points (x0,y0) and (x1,y1)
# 	- $void: an optional value to replace voids in map, which has a default value of 0
# 	- $z0: an optional value to replace value of a point (x0,y0)
#
# - `::numMV::indexedElevation x0 y0 x1 y1 ?void? ?z0?;`
# 	procedure that returns an indexed elevation angle
# 	returned value is reversed index (index for "the largest value" is 0)
# 	- $x0, $y0, $x1 and $y1: integer coordinates for different points (x0,y0) and (x1,y1)
# 	- $void: an optional value to replace voids in map, which has a default value of 0
# 	- $z0: an optional value to replace value of a point (x0,y0)
#
# - `::numMV::window 2dList;`
# 	procedure that returns view composed of 0, 1 and newline character (Unicode U+00000A)
# 	- $2dList: a two-dimensional numerical list that is composed of indexed elevation angles (integers not less than 0)
#
##===================================================================
#
set auto_noexec 1;
package require Tcl 8.6;
#
#*** <namespace ::tcl::mathfunc> ***
#=== lSum.tcl (Yuji SODE, 2018): https://gist.github.com/YujiSODE/1f9a4e2729212691972b196a76ba9bd0 ===
#Additional mathematical functions for Tcl expressions
# [References]
# - Iri, M., and Fujino., Y. 1985. Suchi keisan no joshiki (in Japanese). Kyoritsu Shuppan Co., Ltd.; ISBN 978-4-320-01343-8
proc ::tcl::mathfunc::lSum {list} {namespace path {::tcl::mathop};set S 0.0;set R 0.0;set T 0.0;foreach e $list {set R [+ $R [expr double($e)]];set T $S;set S [+ $S $R];set T [+ $S [expr {-$T}]];set R [+ $R [expr {-$T}]];};return $S;};
#
#*** <namespace: ::numMV> ***
namespace eval ::numMV {
	#=== variables ===
	#
	#map data
	variable MAP {};
	#
	#map width and height
	#map height is estimated height from map and its width
	variable WIDTH 10;
	variable HEIGHT 10;
	#
	#map resolution
	variable RES 10;
	#
	#value of pi
	variable PI 3.14159265358979323846264338327950;
	#
	#an array of values which was estimated with value of pi and given resolution
	variable PI_VARS;
	array set PI_VARS {};
	#
	#rank format for indexed elevation
	######################################
	#[indexed elevation: idx1 < indx2   ]#
	#[not indexed value: value1 > value2]#
	######################################
	variable RANK {};
	#
	#half value of pi
	variable PI2 [expr {double($PI)/2.0}];
};
	#=== procedures ===
	#
	#procedure that loads a numerical map and returns information of the given map
	#$width is not less than 2
	proc ::numMV::load {map width} {
		# - $map: a numerical list
		# - $width: a positive integer value that is set as width of map
		variable ::numMV::MAP;variable ::numMV::WIDTH;variable ::numMV::HEIGHT 10;
		#$width is not less than 2
		set width [expr {$width<2?2:int($width)}];
		set ::numMV::WIDTH [expr {$width}];
		#
		set ::numMV::MAP $map;
		#
		#--- estimation of map height ---
		#map height is estimated height from map and its width
		set L [llength $map];
		set lMod [expr {$L%$width}];
		set ::numMV::HEIGHT [expr {$lMod>0?int(($L+$width-$lMod)/$width):int($L/$width)}];
		#
		unset lMod;
		return [list length $L width $::numMV::WIDTH height $::numMV::HEIGHT xMin 0 xMax [expr {$::numMV::WIDTH-1}] yMin 0 yMax [expr {$::numMV::HEIGHT-1}]];
	};
	#
	#procedure to set resolution
	#$res is not less than 3
	proc ::numMV::setResolution {res} {
		# - $res: a positive integer value that is set as resolution of map
		variable ::numMV::RES;variable ::numMV::PI;variable ::numMV::PI_VARS;variable ::numMV::RANk;
		#$res is not less than 3
		set res [expr {$res<3?3:$res}];
		#--- the upper limit for $res is set as 10**4 ---
		set res [expr {$res>10000?10000:$res}];
		#------------------------------------------------
		set ::numMV::RES [expr {int($res)}];
		#
		array unset ::numMV::PI_VARS;
		array set ::numMV::PI_VARS {};
		set i $RES;
		while {$i>0} {
			set ::numMV::PI_VARS([expr {$RES-$i}]) [expr {double($i)/double($RES)*double($PI)}];
			incr i -1;
		};
		#
		#--- rank format for indexed elevation ---
		set nRank [expr {$RES-1}];
		set j 1;
		#${_V} is numerical value that is undefined
		#+++ $j = 1 +++
		set ::numMV::RANK "\$\{_V\}>$PI_VARS(1)?0:(";
		set n 1;
		#+++ 1 < $j < $RES-1 +++
		#$j=2
		incr j 1;
		while {$j<$nRank} {
			append ::numMV::RANK "\$\{_V\}>$PI_VARS($j)?[expr {$j-1}]:(";
			incr n 1;
			incr j 1;
		};
		#+++ $j = $RES-1 +++
		append ::numMV::RANK "\$\{_V\}>$PI_VARS($j)?[expr {$j-1}]:$j";
		append ::numMV::RANK [string repeat \) $n];
		#set resolution value is returned
		return $::numMV::RES;
	};
	### initial activation ###
	::numMV::setResolution 10;
	##########################
	#
	#procedure that returns a value of a point in numerical map using integer coordinates
	proc ::numMV::getMapPoint {x y {void 0}} {
		# - $x and $y: integer coordinates
		# - $void: an optional value to replace voids in map, which has a default value of 0
		variable ::numMV::MAP;variable ::numMV::WIDTH;
		#when map is undefined
		if {![llength $::numMV::MAP]} {
			error "map data is undefined";
		};
		#
		set x [expr {int($x)}];
		set y [expr {int($y)}];
		#list index=x+width*y
		#$idxV is value at the given point in numerical map
		set idxV [lindex $::numMV::MAP [expr {$x+$::numMV::WIDTH*$y}]];
		return [expr {[llength $idxV]>0?$idxV:$void}];
	};
	#
	#procedure that returns a modified value of arc tangent in radians
	#returned value is in [0,pi]
	proc ::numMV::atan_0pi {x0 y0 x1 y1 {void 0} {z0 {}}} {
	#proc ::numMV::atan_0pi {x0 y0 x1 y1 {void 0}} {} 
		# - $x0, $y0, $x1 and $y1: integer coordinates for different points (x0,y0) and (x1,y1)
		# - $void: an optional value to replace voids in map, which has a default value of 0
		# - $z0: an optional value to replace value of a point (x0,y0)
		variable ::numMV::PI2;
		###
		set x0 [expr {double($x0)}];
		set y0 [expr {double($y0)}];
		set x1 [expr {double($x1)}];
		set y1 [expr {double($y1)}];
		set v0 [expr {[llength $z0]>0?double($z0):double([::numMV::getMapPoint $x0 $y0 $void])}];
		set v1 [expr {double([::numMV::getMapPoint $x1 $y1 $void])}];
		###
		set dL [expr {sqrt(($x1-$x0)**2+($y1-$y0)**2)}];
		set dV [expr {$v1-$v0}];
		###
		#when $dL is 0.0
		if {!($dL!=0)} {
			error "the same points are given for calculation";
		};
		set sumList [list $::numMV::PI2 [expr {atan($dV/$dL)}]];
		unset x0 y0 x1 y1 v0 v1 dL dV;
		###
		return [expr {lSum($sumList)}];
	};
	#
	#procedure that returns an indexed elevation angle
	#returned value is reversed index (index for "the largest value" is 0)
	#proc ::numMV::indexedElevation {x0 y0 x1 y1 {void 0}} {}
	proc ::numMV::indexedElevation {x0 y0 x1 y1 {void 0} {z0 {}}} {
		# - $x0, $y0, $x1 and $y1: integer coordinates for different points (x0,y0) and (x1,y1)
		# - $void: an optional value to replace voids in map, which has a default value of 0
		# - $z0: an optional value to replace value of a point (x0,y0)
		variable ::numMV::RANk;
		###
		#${_V} is variable that is used in $::numMV::RANK
		set {_V} [::numMV::atan_0pi $x0 $y0 $x1 $y1 $void $z0];
		return [expr $::numMV::RANK];
	};
	#
	#procedure that returns view composed of 0, 1 and newline character (Unicode U+00000A)
	proc ::numMV::window {2dList} {
		# - $2dList: a two-dimensional numerical list that is composed of indexed elevation angles (integers not less than 0)
		variable ::numMV::RES;
		###
		#--- variables ---
		#$view is view from the window with form of array
		array set view {};
		#$b is buffer with form of array
		array set b {};
		#
		#$w2d and $h2d are width and height of a given area
		set w2d [expr {int([llength [lindex $2dList 0]])}];
		set h2d [expr {int([llength $2dList])}];
		###
		set i 0;
		#each array element has a list that is filled with 0
		while {$i<$::numMV::RES} {
			set view($i) 0;
			append view($i) [string repeat "\t0" [expr {$w2d-1}]];
			incr i 1;
		};
		#
		set i 0;
		#buffer array
		while {$i<$w2d} {
			set b($i) 0;
			incr i 1;
		};
		#--- main script ---
		set res [expr {$::numMV::RES-1}];
		set i 0;
		while {$i<$h2d} {
			set j 0;
			while {$j<$w2d} {
				set e [expr {int([lindex $2dList $i $j])}];
				#=== if range error ===
				if {$e<0} {error "Range Error: ($j,$i) is less than 0";};
				if {$e>$res} {error "Range Error: ($j,$i) is greater than $res";};
				#
				if {$i<1} {
					#+++ $i = 0 +++
					lset view($e) $j 1;
					#buffer array
					set b($j) $e;
				} else {
					#+++ $i > 0 +++
					lset view($e) $j [expr {$e<$b($j)?1:[lindex $view($e) $j]}];
					#buffer array
					set b($j) [expr {$e<$b($j)?$e:$b($j)}];
				};
				incr j 1;
			};
			incr i 1;
		};
		#
		set i 1;
		set R [join $view(0) {}];
		while {$i<$::numMV::RES} {
			append R "\n[join $view($i) {}]";
			incr i 1;
		};
		#
		unset view w2d h2d res i j e b;
		return $R;
	};
	#
	#=======================================
	# positions of 4 directions and 4 points
	#	      N
	#	      ^
	#	    [a+b]
	#	W <-+ + +-> E
	#	    [d+c]
	#	      v
	#	      S
	# N:=ab, E:=bc, S:=cd and W:=da
	#=======================================
	#
	#
	#procedure that returns northern view
	proc ::numMV::N {x0 y0 {void 0} {z0 {}}} {
	};
#
################### test code ###############
puts stdout "\#=== test code outputs ===";
set map {\
{0 5 5 5 0 9}\
{5 5 4 2 8 9}\
{4 4 3 1 9 8}\
{3 8 2 9 3 9}\
{2 6 1 3 2 0}\
};
puts stdout "normal outputs:";
puts stdout [::numMV::window $map];
puts stdout "csv-form outputs:";
puts stdout [string map {\n ,} [::numMV::window $map]];
