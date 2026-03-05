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

package provide bis_convolveimage 1.0
package require bis_imagetoimagealgorithm 1.0


itcl::class bis_convolveimage {

    inherit bis_imagetoimagealgorithm

     constructor { } {	 $this Initialize  }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Convolve Image" }
	public method UpdateOutputFilenames { } 
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_convolveimage::Initialize { } {

    PrintDebug "bis_convolveimage::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ blursigma "kernel size [mm/voxel] of FWHM filter size" "Filter Size"  { real triplescale 100 }    2.0 { 0.0 20.0 }  2 }
	{ unit      "kernel size unit mm or voxels " "Units" { listofvalues radiobuttons }  mm { mm voxels }   3 }
	{ radius    "radius factor of the gaussian in voxel units " "Filter Radius" real  1.5   { 0.0 5.0 }  -1 }
	{ mode      "Operation to perform" "Mode" { listofvalues }  Smooth { Smooth Gradient Hessian }   1}
    }

    set outputs { 
	{ filterbank   "FilterBank Image" pxitclimage  ""  200 }
    }

    set defaultsuffix { "_sm" }
    
    set scriptname bis_convolveimage
    set completionstatus "Done"

    #
    #document
    #
    
    set description "Convolvees an image with a specific gaussian/gaussian derivative/hessian kernel."
    set description2 "Convolveing kernel size blursigma (in mm by default ) represents the FWHM filter size."
    set backwardcompatibility ""

    $this InitializeImageToImageAlgorithm
}
# -----------------------------------------------------------------------------------------
itcl::body bis_convolveimage::UpdateOutputFilenames { } {

    set mode   [ $OptionsArray(mode) GetValue ]
    if { $mode == "Smooth" } {
	set defaultsuffix { "_sm" }
    } elseif { $mode == "Gradient" } {
	set defaultsuffix { "_grad" }
    } else {
	set defaultsuffix { "_hessian" }
    }

    return [ ::bis_imagetoimagealgorithm::UpdateOutputFilenames  ]
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_convolveimage::Execute {  } {

    PrintDebug "bis_convolveimage::Execute"

    set mode   [ $OptionsArray(mode) GetValue ]
    set blursigma   [ $OptionsArray(blursigma) GetValue ]
    set unit        [ $OptionsArray(unit)      GetValue ]
    set radius      [ $OptionsArray(radius)    GetValue ]
    set image_in    [ $this GetInput ]

    set spacing [[ $image_in GetImage ] GetSpacing ]

    if { $unit == "mm"} {
	for { set j 0 } { $j <=2 } { incr j } {
	    set sigma($j) [ expr $blursigma * 0.4247 / [ lindex $spacing $j ]]
	}
    } else {
	for { set j 0 } { $j <=2 } { incr j } {
	    set sigma($j) [ expr $blursigma * 0.4247 ]
	}
    }


    PrintDebug "radius = $radius sigma = $sigma(0) $sigma(1) $sigma(2), mode=$mode"
    set convolve  [ vtkxqImageFourierConvolution [ pxvtable::vnewobj ]  ]

    if { $mode == "Smooth" } {
	$convolve SetFilterBankToGaussian $sigma(0) $sigma(1) $sigma(2) $radius
    } elseif { $mode == "Gradient" } {
	$convolve SetFilterBankToGaussianDerivative $sigma(0) $sigma(1) $sigma(2) $radius
#    } elseif { $mode == "Blob" } {
#	$convolve SetFilterBankToMultiScaleBlob [ $OptionsArray(blobscale) GetValue ] $sigma(0) 
    } else {
	$convolve SetFilterBankToHessian $sigma(0) $sigma(1) $sigma(2) $radius
    }
    $convolve SetMode 0
    $convolve SetInput [ $image_in GetObject ]
    $this SetFilterCallbacks $convolve "Convolving Image ($mode)"
    $convolve Update

    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage ShallowCopyImage [ $convolve GetOutput ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]

    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0

    set fbank [ $OutputsArray(filterbank) GetObject ]
    $fbank ShallowCopyImage [ $convolve GetFilterBank ]
    [ $fbank GetImageHeader ] AddComment "$comment -- this is the filterbank" 0


    $convolve Delete

    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_convolveimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_convolveimage [pxvtable::vnewobj]]
    $alg MainFunction 
}





