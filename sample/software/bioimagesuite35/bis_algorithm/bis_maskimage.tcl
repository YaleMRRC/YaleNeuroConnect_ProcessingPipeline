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
package provide bis_maskimage 1.0

#
# blend image
#

itcl::class bis_maskimage {

    inherit bis_dualimagereslicetransformationalgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Mask Image"}




}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_maskimage::Initialize { } {

    PrintDebug "bis_maskimage::Initialize" 

    set options {
	{ interp       "Interpolation Mode that is used when reslicing the image" "Interpolation Mode"  listofvalues Linear { "NearestNeighbor" "Linear" "Cubic" }  0 }
	{ maskdilation "Dilate binary mask prior to masking" "Dilatation of Mask"  listofvalues 0 { 0 1 2 3 4 5 }   2 }
	{ background   "Background Level used to fill voxels outside of mapped area" "Background Value"  real 0.0 { -100000 100000 }  -100 }
    }

    set defaultsuffix { "_masked" }
    
    set scriptname bis_maskimage
    set completionstatus "Done"
    #
    #document
    #

    set category "Image Processing Dual"
    set description "blends an image using one or more transformations."
    set description2 "a useful check of the quality of the transformations"
    set backwardcompatibility "Reimplemented from pxmat_maskimage.tcl."
    set authors "hirohito.okuda@yale.edu, xenophon.papademetris@yale.edu."

    $this InitializeDualImageTransformationAlgorithm
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_maskimage::Execute {  } {

    PrintDebug "bis_maskimage::Execute"

    set d [ $OptionsArray(maskdilation) GetValue ]


    set lst [ $this ResliceImageIfNeeded ]
    set reslimage [ lindex $lst 0 ]
    set img [ vtkImageData [ pxvtable::vnewobj ]]

    set thr [ vtkImageThreshold [ pxvtable::vnewobj ]]
    $thr ThresholdByUpper 1.0
    $thr SetInput  $reslimage 
    $thr SetInValue 1.0
    $thr SetOutValue 0.0
    $thr ReplaceInOn
    $thr ReplaceOutOn
    
    if { $d > 0 } {
	set r [ expr 2*$d + 1 ]
	set dilate  [  vtkImageContinuousDilate3D [ pxvtable::vnewobj ] ]
	$dilate SetInput [ $thr GetOutput ] 
	$dilate SetKernelSize $r $r $r
	SetFilterCallbacks $dilate "Dilating Mask"
	$dilate Update
	$img ShallowCopy [ $dilate GetOutput ]
	$dilate Delete
    } else {
	$thr Update
	$img ShallowCopy [ $thr GetOutput ]
    }
    
    
    set mask  [  vtkpxImageMask [ pxvtable::vnewobj ] ]
    $mask SetInput [ [ $this GetInput ]  GetImage ]
    $mask SetMask  $img
    SetFilterCallbacks $mask  "Mask x Image"
    $mask Update
    $thr Delete
    
    
    [ $OutputsArray(output_image) GetObject ] ShallowCopyImage [ $mask GetOutput ]

    # Output orientation etc. is same as input
    set outimage [ $this GetOutput ] 
    $outimage CopyImageHeader [ [ $this GetInput ] GetImageHeader ]

    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0

    $img Delete

    $this DeleteResliceAlgorithmIfNeeded $lst 
    return 1
}


# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_maskimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

   

    set alg [bis_maskimage [pxvtable::vnewobj]]
    $alg MainFunction 
}

