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

package require bis_dualimagealgorithm 1.0
package require bis_resliceimage 1.0
package provide bis_image4dnormalize 1.0

#
# blend image
#

itcl::class bis_image4dnormalize {

    inherit bis_dualimagealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Normalize 4D Image"}

    protected method PackOptionsGUIInterface { lst }

}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_image4dnormalize::Initialize { } {

    PrintDebug "bis_image4dnormalize::Initialize" 

    set inputs { 
	{ mask_image   "Mask Image" pxitclimage  ""  102 }   
    }

    set defaultsuffix { "_4dnorm" }
    
    set scriptname bis_image4dnormalize
    set completionstatus "Done"
    #
    #document
    #

    set category "Image Processing Dual"
    set description "Normalize a 4D image by comparing it to a reference"
    set description2 ""
    set backwardcompatibility " "
    set authors "xenophon.papademetris@yale.edu."

    $this InitializeDualImageAlgorithm
    
    $this RenameInput 0 "Reference Image"
    $this RenameInput 1 "Input Image"
}

# -----------------------------------------------------------------------------------------# Execute
# ----------------------------------------------------------------------------------------
itcl::body bis_image4dnormalize::Execute {  } {

    PrintDebug "bis_image4dnormalize::Execute"

    set img1 [ [ $this GetInput ] GetImage ]
    set img2 [ [ $this GetSecondInput ]  GetImage ]
    set mask [ [ $this GetInputObject mask_image ] GetImage ]

    set l [ list $img1 $img2 $mask ]
    for { set i 0 } { $i < [ llength $l ] } { incr i } {
	puts stderr "Dimensions = [ [ lindex $l $i ] GetDimensions ]"
    }

    if { [ $img1 GetNumberOfPoints ] != [ $img2 GetNumberOfPoints ] || 
	 [ $img1 GetNumberOfPoints ] != [ $mask GetNumberOfPoints ] 
     } {
	set errormessage  "Unequal Image Sizes\n Cannot Perform 4d normalize"
	return 0
    }

    

    set comp [ vtkbisImagePatchCorrelation New ]
    set outimg [ $comp Normalize4DImages $img1 $mask $img2 1 ]

    set outimage [ $this GetOutput ] 
    $outimage ShallowCopyImage $outimg
#    puts stderr " Results Range: [ [ [ [ $outimage GetImage ] GetPointData ] GetScalars ] GetRange ]"

    set pimage   [ $this GetSecondInput ] 
    $outimage CopyImageHeader [ $pimage GetImageHeader ]

    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0

    $comp Delete
    $outimg Delete

    return 1
}


# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_image4dnormalize.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function
 

    set alg [bis_image4dnormalize [pxvtable::vnewobj]]
    $alg MainFunction 
}

