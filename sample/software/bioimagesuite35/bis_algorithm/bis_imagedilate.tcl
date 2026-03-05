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

package provide bis_imagedilate 1.0
package require bis_imagetoimagealgorithm 1.0


#
# smooth image
#

itcl::class bis_imagedilate {

    inherit bis_imagetoimagealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Dilate/Erode Filter" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_imagedilate::Initialize { } {

    PrintDebug "bis_imagedilate::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ windowsize "kernel size [voxels] -ve values =erosion" "Filter Size"  {  listofvalues  } 3 { -9 -7 -5 -3 3 5 7 9 }  0 }
	{ dimension  "2 or 3 to to do dilation/erosion in 2D or 3D" "Dimensionality"  { listofvalues radiobuttons }    3 { 2  3 }  -999 }

    }

    set defaultsuffix { "_dil" }
    
    set scriptname bis_imagedilate
    set completionstatus "Done"

    #
    #document
    #
    
    set description "Modifies an image using continuous dilation filtering"
    set description2 " "
    set backwardcompatibility "New"

    $this InitializeImageToImageAlgorithm
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_imagedilate::Execute {  } {

    PrintDebug "bis_imagedilate::Execute"

    set windowsize   [ $OptionsArray(windowsize) GetValue ]
    set dimension   [ $OptionsArray(dimension)    GetValue ]
    set image_in    [ $InputsArray(input_image) GetObject ]

    PrintDebug "windowsize = $windowsize, dimension = $dimension "

    if { $windowsize > 0 } {
	set smooth  [ vtkImageContinuousDilate3D [ pxvtable::vnewobj ]  ]
    } else {
	set smooth  [ vtkImageContinuousErode3D [ pxvtable::vnewobj ]  ]
    }
    
    set r [ expr abs($windowsize) ]

    if { $dimension == 3 } {
	$smooth SetKernelSize $r $r $r
    } else {
	$smooth SetKernelSize $r $r 1
    }
    $smooth SetInput [ $image_in GetImage ]
    $this SetFilterCallbacks $smooth "Dilate Smoothing Image"
    $smooth Update


    set image_out [ $smooth GetOutput ]

    [ $OutputsArray(output_image) GetObject ] ShallowCopyImage $image_out 

    # Output orientation etc. is same as input
    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]

    set comment [ format "BIS::pxmat_imagedilate.tcl windowsize=%d " $windowsize ]

    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0


    $smooth Delete

    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_imagedilate.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_imagedilate [pxvtable::vnewobj]]
    $alg MainFunction 
}





