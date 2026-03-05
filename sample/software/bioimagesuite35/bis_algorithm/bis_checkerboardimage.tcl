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

package require bis_dualimagereslicetransformationalgorithm 1.0
package provide bis_checkerboardimage 1.0

#
# blend image
#

itcl::class bis_checkerboardimage {

    inherit bis_dualimagereslicetransformationalgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "CheckerBoard"}


}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_checkerboardimage::Initialize { } {

    PrintDebug "bis_checkerboardimage::Initialize" 

    set options {
		{ interp        "Interpolation Mode that is used when reslicing the image" "Interpolation Mode"  listofvalues Linear { "NearestNeighbor" "Linear" "Cubic" }  0 }
		{ spacing      "Checkerboard spacing" "Checkerboard spacing"  listofvalues 12 { 2 5 8 10 11 16 23 32 }  0 }
		{ background  "Background Level used to fill voxels outside of mapped area" "Background Value"  real 0.0 { -100000 100000 }  -100 }
		{ normalizeimages  "Normalize images" "Normalize Images"  { boolean } 0 { 0 1 }  1 }
    }
	
    set defaultsuffix { "_checkerboard" }
    
    set scriptname bis_checkerboardimage
    set completionstatus "Done"
    #
    #document
    #

    set category "Image Processing Dual"
    set description "Creates checkerboard image"
    set description2 "a useful check of the quality of the transformations"
    set backwardcompatibility "Reimplemented from pxmat_blendimage.tcl."
    set authors "hirohito.okuda@yale.edu, xenophon.papademetris@yale.edu."

    $this InitializeDualImageTransformationAlgorithm
}


# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_checkerboardimage::Execute {  } {

    PrintDebug "bis_checkerboardimage::Execute"
    set lst [ $this ResliceImageIfNeeded ]
    set reslimage [ lindex $lst 0 ]

    
    set imcast2 [ vtkImageCast [ pxvtable::vnewobj ]]
    $imcast2 SetInput $reslimage
    $imcast2 SetOutputScalarType [ [ [ $this GetInput ] GetImage ] GetScalarType ]
    $imcast2 Update

    set sq [ expr round ([ $OptionsArray(spacing) GetValue ]) ] 


    set checkerboardCreator [  vtkpxCreateCheckerBoardImage [ pxvtable::vnewobj ]]
    $checkerboardCreator SetInput [ [ $this GetInput ] GetImage ]
    $checkerboardCreator SetInput2 [ $imcast2 GetOutput ]
    $checkerboardCreator SetSquareSize $sq
    $checkerboardCreator SetNormalizeImages [ $OptionsArray(normalizeimages) GetValue ]
    $checkerboardCreator Update
    
    $imcast2 Delete 
    
    [ $OutputsArray(output_image) GetObject ] ShallowCopyImage [ $checkerboardCreator GetOutput ]

    # Output orientation etc. is same as input
    set outimage [ $this GetOutput ] 
    set pimage   [ $this GetSecondInput ] 

    $outimage CopyImageHeader [ $pimage GetImageHeader ]

    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0


    $checkerboardCreator Delete
    $this DeleteResliceAlgorithmIfNeeded $lst 

    return 1
}


# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_checkerboardimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

   

    set alg [bis_checkerboardimage [pxvtable::vnewobj]]
    $alg MainFunction 
}

