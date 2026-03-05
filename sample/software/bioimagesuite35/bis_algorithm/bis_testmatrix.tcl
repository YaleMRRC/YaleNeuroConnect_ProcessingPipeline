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
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] main]

package require bis_algorithm 1.0
package require bis_viewer 1.0
package require pxitclcamera 1.0
package provide bis_testmatrix 1.0

#
# Operations involving multisubject average for testing ....
#

itcl::class bis_testmatrix {

    inherit bis_algorithm
    
    constructor { } {
	$this Initialize
    }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Test Matrix" }

}
# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_testmatrix::Initialize { } {

    PrintDebug "bis_testmatrix::Initialize" 

    #name,description,type,object,filename(if applicable),priority (optional)

    set outputs { 
	{ out_image "Saved Image" pxitclimage  ""    2000 }
    }

    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ matfile "Input matrix file name" "Matrix Filename:"  { filename readfile }  "" { "Matrix File" { *.mat* }} 1 }
	{ matname  "Matrix Name" "Matrix Name"  string "" { "" }  2 }
    }

    set defaultsuffix { "" }

    set scriptname bis_testmatrix
    set completionstatus ""
    #
    #document
    #
    set category "Utility"
    set description "This is a test script for the BioImage Suite Matrix code, primarily for regression testing"
    set description2 ""
    set backwardcompatibility ""
    set authors "xenophon.papademetris.yale.edu"

    $this AddDefaultOptions
}


itcl::body bis_testmatrix::Execute {  } {


    set matname [ $OptionsArray(matname) GetValue ]
    set matfile [ $OptionsArray(matfile) GetValue ]

    set mat [ vtkpxMatrix New ]
    set ok [ $mat ImportFromMatlab $matfile $matname  ]
    if { $ok == 0 } {
	set errormessage "Failed to read matrix $matfile ($matname)"
    }

    set img [ vtkImageData New ]
    set sz [ $mat GetSize ]
    $img SetDimensions [ lindex $sz 0 ] [ lindex $sz 1 ] 1
    $img SetScalarTypeToFloat
    $img AllocateScalars
    for { set i 0 } { $i < [ lindex $sz 0 ] } { incr i } {
	for { set j 0 } { $j < [ lindex $sz 1 ] } { incr j } {
	    $img SetScalarComponentFromDouble $i $j 0 0 [ $mat GetElement $i $j ]
	}
    }

    [ $this GetOutputObject out_image ] ShallowCopyImage $img
    $img Delete
    $mat Delete

    return $ok
}
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_testmatrix [pxvtable::vnewobj]]
    $alg MainFunction 
}

