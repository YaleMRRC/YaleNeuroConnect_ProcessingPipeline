#BIOIMAGESUITE_LICENSE  ---------------------------------------------------------------------------------
#BIOIMAGESUITE_LICENSE  This file is part of the BioImage Suite Software Package.
#BIOIMAGESUITE_LICENSE  
#BIOIMAGESUITE_LICENSE  X. Papademetris, M. Jackowski, N. Rajeevan, H. Okuda, R.T. Constable, and L.H
#BIOIMAGESUITE_LICENSE  Staib. BioImage Suite: An integrated medical image analysis suite, Section
#BIOIMAGESUITE_LICENSE  of Bioimaging Sciences, Dept. of Diagnostic Radiology, Yale School of
#BIOIMAGESUITE_LICENSE  Medicine, http:#www.bioimagesuite.org.
#BIOIMAGESUITE_LICENSE  
#BIOIMAGESUITE_LICENSE  This program is free software; you can redistribute it and/or
#BIOIMAGESUITE_LICENSE  modify it under the terms of the GNU General Public License version 2
#BIOIMAGESUITE_LICENSE  as published by the Free Software Foundation.
#BIOIMAGESUITE_LICENSE  
#BIOIMAGESUITE_LICENSE  This program is distributed in the hope that it will be useful,
#BIOIMAGESUITE_LICENSE  but WITHOUT ANY WARRANTY; without even the implied warranty of
#BIOIMAGESUITE_LICENSE  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#BIOIMAGESUITE_LICENSE  GNU General Public License for more details.
#BIOIMAGESUITE_LICENSE  
#BIOIMAGESUITE_LICENSE  You should have received a copy of the GNU General Public License
#BIOIMAGESUITE_LICENSE  along with this program; if not, write to the Free Software
#BIOIMAGESUITE_LICENSE  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#BIOIMAGESUITE_LICENSE  See also  http:#www.gnu.org/licenses/gpl.html
#BIOIMAGESUITE_LICENSE  
#BIOIMAGESUITE_LICENSE  If this software is modified please retain this statement and add a notice
#BIOIMAGESUITE_LICENSE  that it had been modified (and by whom).  
#BIOIMAGESUITE_LICENSE 
#BIOIMAGESUITE_LICENSE  -----------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------
# vtable packages a simple oop extension for tcl
# 






# provides commands
#
# to define a new class
#
#
#
#  namespace eval classname {
#    
#      pxvtable::initvlist
#      ... this also defines a procedure called init which returns a unique object name
#
#      ... then define all procedures using pxvtable::vproc instead of proc
#      ... in all procedures
#      ... classname = package name
#      ... if first argument == this then non static else static
#      ...    thisparam is a special array of class parameters
#      ...    thisname  is the reference to array for -variable, -textvariable situations
#      ...                   i.e. entry -textvariable ${thisname}(text)
#      ...
#      ... at end if this is a derived class
#      ...
#      ...  pxvtable::appendvlist parentclassname
#  }
#
#  Xenios Papademetris papad@noodle.med.yale.edu August  2001
#
# --------------------------------------------------------------------------------------
package provide pxvtable 1.0

# 	$Id: pxvtable.tcl,v 1.1 2002/02/20 18:07:50 Xenios Exp $	


namespace eval pxvtable {


    namespace export listvpackage getvariable getvariablename setvariable vproc vnewobj

    variable counter

    set counter 0


    proc vnewobj { } {
	variable counter
	incr counter
	return "pxtclobj$counter"
    }

    
    proc vproc  { name arguments  args } {

	set classname [ uplevel namespace current ]
	uplevel lappend vlist $name
	uplevel lappend vlist $classname
	uplevel lappend vlist [ llength $arguments ]


	if { [ lindex $arguments 0 ] == "this" } {
	    set addition " set thisname \[::pxvtable::getthisname \$this pxtclobj \]; upvar #0 \$thisname thisparam; set classname $classname \n"
	} else {
	    set addition " set classname $classname\n"
	}
	set len [ string length $args ]
	set oldbody  [ string range $args 1 [ expr $len -2 ] ]
	set newbody "$addition  $oldbody"

	uplevel proc $name [ list $arguments ] [ list $newbody ]
    }

    proc getthisname {widget varName} {
	regsub -all {\.} $widget "_" base
	
	return "$varName$base"
    }

    proc initvlist {  } {
	uplevel set vlist [ list "" ]
	set realclassname [ uplevel namespace current ]
	set realobj       [ uplevel pxvtable::vnewobj  ]
	
	#uplevel pxvtable::vproc init [ list [] ] [ list "return \[ pxvtable::vnewobj \]" ]

	set add2 " set this \[ pxvtable::vnewobj \];"
	set add3 " set thisname \[::pxvtable::getthisname \$this pxtclobj \]; upvar #0 \$thisname thisparam; set thisparam(realclassname) $realclassname;"
	set add4 ""
	#" puts stdout \" New \$thisparam(realclassname) object \$this \"; "
	set add5 " return \$this "
	set addition "$add2 $add3 $add4 $add5"
	#puts stdout "Addition for $realclassname\n\t $addition\n"
	uplevel pxvtable::vproc init [ list [] ] [ list $addition ]
    }

    proc listvpackage { packname } {
	
	upvar #0 ${packname}::vlist vlist
	printvlist $vlist $packname
    }

    proc printvtable { } {
	set basename [ uplevel namespace current ]
	upvar  ${basename}::vlist vlist
	printvlist $vlist $basename
    }

    proc printvlist { vlist basename } {

	puts stdout "\nVirtual Table List for $basename "
	puts stdout "-----------------------------------"
	
	set len [ llength $vlist ]
	for { set k 0 } { $k < $len } { set k [ expr $k +3 ]} {
	    set name [ lindex $vlist [ expr $k  ] ]
	    set par  [  lindex $vlist [ expr $k + 1 ] ]
	    set num  [  lindex $vlist [ expr $k + 2 ] ]
	    puts stdout "${par}::${name} num=$num"
	}
	puts stdout "-----------------------------------\n";
    }

    proc appendvlist { other } {
	
	set basename [ uplevel namespace current ]
	upvar  ${basename}::vlist vlist
	upvar  ${other}::vlist otherlist

	set len [ llength $otherlist ]
	for {set k 0 } { $k < $len } { set k [ expr $k +3 ] } {
	    set name [ lindex $otherlist $k ] 
	    set index [ lsearch -exact $vlist $name ]
	    if { $index == -1 } {
		set par  [ lindex $otherlist [expr 1+$k]  ]
		set num  [ lindex $otherlist [expr 2+$k] ]
		lappend vlist $name
		lappend vlist $par
		lappend vlist $num
		set oldarg [ oldarglist $num ]
		set newarg [ newbody $name $par $num ]
		uplevel proc $name [ list $oldarg ]   [list $newarg ]
	    }
	}
    }
    
    proc oldarglist {  numargs } {
	
	set oldlist " "

	for { set k 0 } { $k < $numargs } { incr k } {
	    set oldlist "${oldlist}a$k "
	}
	
	return  $oldlist 
    }

    proc newbody { name par numargs } {
	
	set oldlist " "

	for { set k 0 } { $k < $numargs } { incr k } {
	    set oldlist "${oldlist}\$a$k "
	}
	
	return "return \[ ${par}::${name} $oldlist \] "
    }

    proc setvariable { object name value } {
	set thisname [::pxvtable::getthisname $object pxtclobj ]; 
	upvar #0 $thisname thisparam;
	set thisparam($name) $value
    }

    proc getvariable { object name } {
	set thisname [::pxvtable::getthisname $object pxtclobj ]; 
	upvar #0 $thisname thisparam;
	return $thisparam($name)
	
    }

    proc getvariablename { object name } {
	set thisname [::pxvtable::getthisname $object pxtclobj ]; 
	return ${thisname}($name)
	
    }

    proc vdeleteobj { object } {
	
	set thisname [::pxvtable::getthisname $object pxtclobj ]; 
	upvar #0 $thisname thisparam;
	array unset thisparam 
    }
}


