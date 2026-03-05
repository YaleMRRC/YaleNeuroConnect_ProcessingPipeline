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

package provide bis_nonlinearsmoothimage 1.0
package require bis_imagetoimagealgorithm 1.0


#
# smooth image
#

itcl::class bis_nonlinearsmoothimage {

    inherit bis_imagetoimagealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Anisotropic Diffusion" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_nonlinearsmoothimage::Initialize { } {

    PrintDebug "bis_nonlinearsmoothimage::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ threshold "Threshold for  Anisotropic Diffusion" "Threshold"   real   30 { 1 20000 }  1 }
	{ factor    "Lambda factor  Regular Anisotropic Diffusion" "Lambda"   real   1.0 { 0.2 10.0 }  2 }
	{ iterations "Number of Iterations" "Iterations"   int  4 { 1 20  }  3 }
	{ mode  "Use intensity difference or gradient difference as constraint" "Mode"  { listofvalues radiobuttons } intensity { intensity gradient }  4 }
	{ dimension  "2 or 3 to to do smoothin in 2D or 3D" "Dimensionality"  { listofvalues radiobuttons }    3 { 2  3 } 6 }

    }

#	{ keyframe  "Use the difference of the firstframe (in case of 4D Images) to control smoothing, instead of doing each frame differently (for 3D Only)" "Keyframe"  { listofvalues radiobuttons } On { On Off }  5 }

    set defaultsuffix { "_nlsm" }
    
    set scriptname bis_nonlinearsmoothimage
    set completionstatus "Done"

    #
    #document
    #
    
    set description "Smoothes an image using anisotropic diffusion filtering"
    set description2 " "
    set backwardcompatibility "New"

    $this InitializeImageToImageAlgorithm
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_nonlinearsmoothimage::Execute {  } {

    PrintDebug "bis_nonlinearsmoothimage::Execute"

    set threshold   [ $OptionsArray(threshold) GetValue ]
    set factor      [ $OptionsArray(factor) GetValue ]
    set iterations  [ $OptionsArray(iterations) GetValue ]
    set mode        [ $OptionsArray(mode) GetValue ]
    #    set keyframe    [ $OptionsArray(keyframe) GetValue ]
    set keyframe 0
    set dimension   [ $OptionsArray(dimension)    GetValue ]

    if { $keyframe == "On" && $dimension == 2 } {
	set dimension 2
	$OptionsArray(dimensions) SetValue 3
    }
    
    set image_in    [ $InputsArray(input_image) GetObject ]

    if { $dimension == 2 } {
	set smooth  [ vtkImageAnisotropicDiffusion2D [ pxvtable::vnewobj ]  ]
    } else {
	set smooth  [ vtkImageAnisotropicDiffusion3D [ pxvtable::vnewobj ]  ]
    }
    #else { 
    #	set smooth  [ vtkpxImageAnisotropicDiffusion3D [ pxvtable::vnewobj ]  ]
    #    }


    $smooth SetDiffusionFactor $factor
    if { $mode == "intensity" } {
	$smooth SetDiffusionThreshold $threshold
    } else {
	$smooth SetGradientMagnitudeThreshold $threshold
    }

    $smooth SetInput [ $image_in GetImage ]
    $smooth SetNumberOfIterations  $iterations
    SetFilterCallbacks $smooth "[ $smooth GetClassName ] Diffusing Image"
    $smooth Update

    set image_out [ $smooth GetOutput ]

    [ $OutputsArray(output_image) GetObject ] ShallowCopyImage $image_out 

    # Output orientation etc. is same as input
    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]

    set comment [ format "BIS::pxmat_nonlinearsmoothimage.tcl threshold=%.2f factor= %.2f iterations=%d mode=%s  dimension=%d " \
		      $threshold $factor $iterations $mode  $dimension ]

    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0

    $smooth Delete

    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_nonlinearsmoothimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_nonlinearsmoothimage [pxvtable::vnewobj]]
    $alg MainFunction 
}





