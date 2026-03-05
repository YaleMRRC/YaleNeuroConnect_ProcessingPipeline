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

package provide bis_surfaceinfo 1.0

#
# output surface information
#

itcl::class bis_surfaceinfo {

    inherit bis_algorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Surface Info" }

}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_surfaceinfo::Initialize { } {

    PrintDebug "bis_surfaceinfo::Initialize" 

    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ detail "description length for header" "Detail" {listofvalues radiobuttons}  short {short long  }  0 }
    }

    set outputs ""
    set inputs { { input_surface "Input Surface List" { pxitclsurface multiple } "" 0  } }
    set directinputs "input_surface"



    set defaultsuffix { "" }
    
    set scriptname bis_surfaceinfo

    #
    #document
    #

    set category "Utility"
    set description "prints information about .vtk surface files."
    set description2 ""
    set backwardcompatibility "Reimplemented from pxmat_surfaceinfo.tcl"
    set authors "hirohito.okuda@yale.edu,xenophon.papademetris.yale.edu"

    $this AddDefaultOptions

}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_surfaceinfo::Execute {  } {

    PrintDebug "bis_headerinfo::Execute"

    set dogui [ $OptionsArray(dogui) GetValue ]
    set fullmode 0
    switch [ $OptionsArray(detail) GetValue ] {
	"long"  {      set fullmode 1 }
    }


    set inplist [ $InputsArray($directinputs) GetAllObjects ]
    set numfiles [ llength $inplist ]

    for { set i 0 } { $i < $numfiles } { incr i } {
	if { $dogui > 0 } {
	    pxtkconsole
	}
	for { set i 0 } { $i < $numfiles } { incr i } {
	    set sur [ [ lindex $inplist $i ] GetSurface ]
	    set name [ [ lindex $inplist $i ] cget -filename ]

	    set np [ $sur GetNumberOfPoints ]
	    set nc [ $sur GetNumberOfCells  ]
	    set bd [ $sur GetBounds ]
	    
	    set scalardata "no point scalars"
	    set celldata   "no cell  scalars"
	    set testscal 0
	    
	    catch {
		set scal [ [  $sur GetPointData ] GetScalars ]
		set ns [ $scal GetNumberOfTuples ]
		set nc [ $scal GetNumberOfComponents ]
		set range [ $scal GetRange ]
		set scalardata  "$ns point-scalars ($nc components) range=[lindex $range 0 ]:[lindex $range 1 ]"
		set testscal 1
	    }
	    
	    catch {
		set scal [ [  $sur GetCellData ] GetScalars ]
		set ns [ $scal GetNumberOfTuples ]
		set nc [ $scal GetNumberOfComponents ]
		set range [ $scal GetRange ]
		set celldata  "$ns cell-scalars ($nc components) range=[lindex $range 0 ]:[lindex $range 1 ]"
		set testscal 0
	    }
	    
	    set outline " $np points $nc cells (bounds=$bd) ($scalardata,$celldata)"
	    
	    if { $fullmode == 1 } {
		set histline ""
		if { $testscal > 0 } {
		    set thrFilter [ vtkThresholdPoints [ pxvtable::vnewobj ]]
		    for { set j [ lindex $range 0 ] } { $j <= [ lindex $range 1 ]} { incr j } {
			$thrFilter SetInput $sur
			$thrFilter ThresholdBetween [ expr $j-0.1 ] [ expr $j+0.1 ]
			$thrFilter Update
			set histline "$histline \t $j \t [ [ $thrFilter GetOutput ] GetNumberOfPoints ]\n"
		    }
		    $thrFilter Delete 
		    set outline "$outline\n $histline"
		}
	    }
	    
	    if { $dogui > 0 } {
		pxtkprint "\n$name:\n $outline\n"
	    } else {
		puts stdout "\n$name:\n $outline"
	    }
	}
    }
    return 1
}
# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_surfaceinfo.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_surfaceinfo [pxvtable::vnewobj]]
    $alg MainFunction 
}

