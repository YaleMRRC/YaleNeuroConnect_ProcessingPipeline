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

package provide bis_edgedetectimage 1.0
package require bis_imagetoimagealgorithm 1.0
package require bis_smoothimage 1.0

#
# smooth image
#

itcl::class bis_edgedetectimage {

    inherit bis_imagetoimagealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Edge Detection" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_edgedetectimage::Initialize { } {

    PrintDebug "bis_edgedetectimage::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ blursigma "kernel size [mm/voxel] of FWHM filter size" "Filter Size"  { real triplescale 200 }    2.0 { 0.0 20.0 }  0 }
	{ unit      "kernel size unit mm or voxels " "Units" { listofvalues radiobuttons }  mm { mm voxels }   1}
	{ mode      "Use image gradient or raw intensity" "Mode"  { listofvalues radiobuttons } gradient { intensity gradient }  4 }
	{ nonmax    "Use Non-Maximal Suppression" "Non-Maximum Suppression"  { boolean checkbutton } 1 { 0 1 }  6 }

    }

    set defaultsuffix { "_edge" }
    
    set scriptname bis_edgedetectimage
    set completionstatus "Done"

    #
    #document
    #
    
    set description "Computes an edge map for an image following smoothing"
    set description2 "first smooths the image than finds the edges "
    set backwardcompatibility "New"

    $this InitializeImageToImageAlgorithm
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_edgedetectimage::Execute {  } {

    PrintDebug "bis_edgedetectimage::Execute"

    set blursigma   [ $OptionsArray(blursigma) GetValue ]
    set unit        [ $OptionsArray(unit) GetValue ]
    set mode        [ $OptionsArray(mode) GetValue ]
    set nonmax      [ $OptionsArray(nonmax) GetValue ]
    set image_in    [ $InputsArray(input_image) GetObject ]

    # Step 1 ... Invoke bis_smoothimage -----
    set smooth_alg [bis_smoothimage [pxvtable::vnewobj]]
    $smooth_alg InitializeFromContainer $this
    $smooth_alg SetInput $image_in
    $smooth_alg SetOptionValue blursigma $blursigma
    $smooth_alg SetOptionValue unit      $unit
    $smooth_alg Execute

    set smimage [  [ $smooth_alg GetOutput ] GetImage ]

    set grad [ vtkImageGradient [ pxvtable::vnewobj ]]
    $grad HandleBoundariesOn
    $grad SetInput $smimage
    set magn [ vtkImageMagnitude [ pxvtable::vnewobj ]]
    $magn SetInput [ $grad GetOutput ]
    SetFilterCallbacks $magn "Computing Gradient Magnitude"	
    
    
    if { $nonmax == 0 } {
	$magn Update
	[ $OutputsArray(output_image) GetObject ] ShallowCopyImage [ $magn GetOutput ]
    } else {
	set sup [ vtkImageNonMaximumSuppression [ pxvtable::vnewobj ]]
	$sup SetVectorInput [ $grad GetOutput ]

	
	if { $mode == "gradient" } {
	    $sup SetMagnitudeInput [ $magn GetOutput ]
	} else {
	    set cast [ vtkImageCast [ pxvtable::vnewobj ]]
	    $cast SetInput  $smimage
	    $cast SetOutputScalarTypeToDouble
	    $sup SetMagnitudeInput [ $cast GetOutput ]
	    $cast Delete
	} 

	$sup HandleBoundariesOn
	SetFilterCallbacks $sup "Eliminating NonMaxima"	
	$sup Update
	[ $OutputsArray(output_image) GetObject ] ShallowCopyImage [ $sup GetOutput ]
	$sup Delete
    }

    $magn Delete
    $grad Delete


    # Output orientation etc. is same as input
    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]

    set comment [ format "BIS::bis_edgedetectimage.tcl blursigma = %.2f unit=%s mode=%s nonmax=%d "\
		      $blursigma $unit $mode $nonmax ]

    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0


    itcl::delete obj $smooth_alg
    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_edgedetectimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function
    set alg [bis_edgedetectimage [pxvtable::vnewobj]]
    $alg MainFunction 
}





