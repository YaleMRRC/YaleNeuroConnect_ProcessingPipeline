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

package require bis_dualimagetransformationalgorithm 1.0
package provide bis_visualizetransformation 1.0

#
# blend image
#

itcl::class bis_visualizetransformation {

    inherit bis_dualimagetransformationalgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Visualize Transformation"}


}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_visualizetransformation::Initialize { } {

    PrintDebug "bis_visualizetransformation::Initialize" 

    set inputs {
	{ xform2   "Transformation 2"    pxitcltransform  "" 300 }
	{ xform3   "Transformation 3"    pxitcltransform  "" 400 }
    }

    set options {
	{ sp "Spacing (in voxels) for lines" "Grid Spacing"  integer 8 { 4 32 }   1 }
	{ zsp "Spacing (in voxels) for lines in z direction" "Grid Z-Spacing"  integer 8 { 4 32 }   2 }
	{ opa "Grid Opacity" "Opacity"  real 0.5 { 0.0 1.0 }   3 }
	{ int "Grid Intensity" "Intensity"  real 0.9 { 0.0 5.0 }   -3 }
    }
	
    set defaultsuffix { "_vgrid" }
    
    set scriptname bis_visualizetransformation
    set completionstatus "Done"
    #
    #document
    #

    set category "Registration"
    set description "Creates a grid visualization of a transformation"
    set description2 "a useful check of the quality of the transformations"
    set backwardcompatibility "none"
    set authors "hirohito.okuda@yale.edu, xenophon.papademetris@yale.edu."

    $this InitializeDualImageTransformationAlgorithm
}


# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_visualizetransformation::Execute {  } {

    set gridspacing  [ $OptionsArray(sp) GetValue ]
    set gridspacing2 [ $OptionsArray(zsp) GetValue ]
    set gridopacity [ $OptionsArray(opa) GetValue ]
    set gridintensity [ $OptionsArray(int) GetValue ]


    set image_trn [  [ $this GetSecondInput ] GetImage ]
    set image_ref  [ [ $this GetInput ]  GetImage ]
    #set xform [ [ $this GetTransformation ] GetObject ]
    set xform1       [ [ $this GetTransformation ]  GetObject ]

    scan [ $image_trn GetExtent ]  "%d %d %d %d %d %d" e1 e2 e3 e4 e5 e6
    scan [ $image_trn GetSpacing ] "%f %f %f" s1 s2 s3
    scan [ $image_trn GetOrigin ]  "%f %f %f" o1 o2 o3
    set range [ lindex [[ [  $image_ref GetPointData ] GetScalars ] GetRange ] 1]
    
    set grdsource [ vtkImageGridSource [ pxvtable::vnewobj ]]
    $grdsource SetDataExtent  $e1 $e2 $e3 $e4 $e5 $e6
    $grdsource SetDataSpacing $s1 $s2 $s3 
    $grdsource SetDataOrigin  $o1 $o2 $o3 
    $grdsource SetGridSpacing $gridspacing $gridspacing $gridspacing2
    $grdsource SetDataScalarType [ $image_trn GetScalarType ]
    $grdsource SetLineValue [ expr $range * $gridintensity ]
    $grdsource Update

    set blendCreator [ vtkImageBlend [ pxvtable::vnewobj ]]
    $blendCreator AddInput $image_trn 
    $blendCreator AddInput [ $grdsource GetOutput ]
    $blendCreator SetOpacity 1 $gridopacity
    $blendCreator SetOpacity 0 [ expr 1.0 -  $gridopacity ]
    SetFilterCallbacks $blendCreator "Blending Grid Images"
    $blendCreator Update

    # Setup the tranforms
    set xform2 0
    set xform3 0
    if { [ $InputsArray(xform2) IsFileNameTheDefault ] != 1 } { 
	set xform2  [[ $InputsArray(xform2)    GetObject ] GetObject ] 
    }

    if { [ $InputsArray(xform3) IsFileNameTheDefault ] != 1 } { 
	set xform3  [[ $InputsArray(xform3)    GetObject ] GetObject ] 
    }

    set trans [ vtkGeneralTransform [ pxvtable::vnewobj ]]
    $trans Identity
    $trans PostMultiply
    $trans Concatenate $xform1
    if { $xform2 !=0 } {
	$trans Concatenate $xform2
	puts stdout "xform2 in use" 
    }
    if { $xform3 !=0 } {
	$trans Concatenate $xform3
	puts stdout "xform3 in use" 
    }
    
    set reslice [  vtkbisImageReslice [ pxvtable::vnewobj ]]
    $reslice OptimizationOff
    $reslice SetInterpolationMode 0
    $reslice SetBackgroundLevel 0.0
    $reslice SetInformationInput $image_ref
    #$reslice SetResliceTransform $xform
    $reslice SetResliceTransform $trans
    $trans Delete
    $reslice SetInput [ $blendCreator GetOutput ]
    SetFilterCallbacks $reslice "Reslicing Grid Source"
    $reslice Update

    [ $OutputsArray(output_image) GetObject ] ShallowCopyImage [ $reslice GetOutput ]
    # Output orientation etc. is same as input
    set outimage [ $this GetOutput ] 
    set pimage   [ $this GetSecondInput ] 

    $outimage CopyImageHeader [ $pimage GetImageHeader ]

    set comment [ $this GetCommandLine full ]
    [ $outimage GetImageHeader ] AddComment "$comment" 0


    $blendCreator Delete
    $reslice Delete
    $grdsource Delete
    return 1
 }


# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_visualizetransformation.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

   

    set alg [bis_visualizetransformation [pxvtable::vnewobj]]
    $alg MainFunction 
}

