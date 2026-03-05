#!/bin/sh
# the next line restarts using wish \
    exec vtk "$0" -- "$@"

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


lappend auto_path [ file dirname [ info script ]]
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] base]
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] apps]

package require bis_algorithm 1.0
package provide bis_headerinfo 1.0

#
# output headerinformation
#

itcl::class bis_headerinfo {

    inherit bis_algorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Image Info" }
    public method LoadObjects { }

}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_headerinfo::Initialize { } {

    PrintDebug "bis_headerinfo::Initialize" 

    set inputs { { input_image "Input Image List" { pxitclimage multiple } "" 0  } }
    set directinputs "input_image"

    set options {
	{ detail "description length for header" "Detail" {listofvalues radiobuttons}  short {short long full }  0 }
    }

    set defaultsuffix ""
    
    set scriptname bis_headerinfo

    #
    #document
    #
    
    set category "Utility"
    set description "prints NIFTI/Analyze image header."
    set description2 "Multiple number of input files can be specified."
    set backwardcompatibility "Reimplemented from pxmat_headerinfo.tcl. bis_headerdump.tcl can be integrated upon request."
    set authors "hirohito.okuda@yale.edu, xenophon.papademetris@yale.edu."

    $this AddDefaultOptions 1
}

itcl::body bis_headerinfo::LoadObjects { } {

    set old  $::pxitclimage::forcebioimagesuitecoordinates 
    set ::pxitclimage::forcebioimagesuitecoordinates 0
    set out [  bis_basealgorithm::LoadObjects ]
    set ::pxitclimage::forcebioimagesuitecoordinates $old
    return $out
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_headerinfo::Execute {  } {

    PrintDebug "bis_headerinfo::Execute"
    
    set dogui [ $OptionsArray(dogui) GetValue ]
    set inplist [ $InputsArray($directinputs) GetAllObjects ]
    set numfiles [ llength $inplist ]


    set fullmode 0
    switch [ $OptionsArray(detail) GetValue ] {
	"short" { 	set fullmode -1 }
	"full"  {      set fullmode 2 }
	"long"  {      set fullmode 1 }
    }


    if { $dogui > 0 } {
	pxtkconsole
    }
    for { set i 0 } { $i < $numfiles } { incr i } {
	set ana [ [ lindex $inplist $i ]  GetImageHeader ]
	set name [ [ lindex $inplist $i ] cget -filename ]
	if { $dogui > 0 } {
	    pxtkprint "\n$name:\n [ $ana GetHeaderDescription $fullmode ]\n\n"
	} else {
	    puts stdout "\n$name:\n [ $ana GetHeaderDescription $fullmode ]\n"
	}
    }

    return 1
}


# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_headerinfo.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_headerinfo [pxvtable::vnewobj]]
    $alg MainFunction 
}

