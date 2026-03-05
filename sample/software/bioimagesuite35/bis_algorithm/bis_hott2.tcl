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

package provide  bis_hott2  1.0
package require bis_dualimagealgorithm 1.0
package require bis_imagemathoperations 1.0

itcl::class bis_hott2 {

    inherit bis_dualimagealgorithm

     constructor { } {	 $this Initialize  }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Hotelling T^2" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_hott2::Initialize { } {

    PrintDebug " bis_hott2::Initialize" 
	
    set options {
	{ nummeasures "Number of measuremenats per subject" "# measurements"  { integer default }    1 { 0 1000 }  0 }
	{ numsubjects "Number of subject" "# subjects"  { integer default }    1 { 0 1000 }  1 }
    }

    set defaultsuffix { "_tsquared" }
    
    set scriptname bis_hott2 
    set completionstatus "Done"
    
    #
    #document
    #
    
    $this InitializeDualImageAlgorithm

}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_hott2::Execute {  } {

    PrintDebug "bis_hott2::Execute"
	
    set image1 [ $this GetInput ]
    set image2 [ $this GetInputObject second_image ] 
    
    set nums   [ $OptionsArray(numsubjects) GetValue ]
    set numm   [ $OptionsArray(nummeasures) GetValue ]

    set math_alg [bis_imagemathoperations [pxvtable::vnewobj]]
    $math_alg InitializeFromContainer $this
    $math_alg SetInput $image1
    $math_alg SetSecondInput $image2
    $math_alg SetOptionValue mathoperation Subtract
    $math_alg Execute

    set fit [ vtkbisHotellingTSquared [ pxvtable::vnewobj ]  ] 

    $fit SetNumberOfSubjects $nums
    $fit SetNumberOfMeasurements $numm
    $fit SetInput [ [ $math_alg GetOutput ] GetImage ]
    $fit Update

    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage ShallowCopyImage [ $fit GetOutput ]
    $outimage CopyImageHeader [ $image1 GetImageHeader ]
 
    $fit Delete
    itcl::delete obj $math_alg

    return 1
}


# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_Hott2.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_hott2 [pxvtable::vnewobj]]
    $alg MainFunction 
}



