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

package provide bis_tensorproperties 1.0
package require bis_imagetoimagealgorithm 1.0


itcl::class bis_tensorproperties {

    inherit bis_imagetoimagealgorithm

     constructor { } {	 $this Initialize  }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Tensor Properties" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_tensorproperties::Initialize { } {

    PrintDebug "bis_tensorproperties::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ mode "tensor operation to compute (default = FA)" "Mode"  listofvalues FA { Eigenvalues Eigenvectors FA RA VR MD }   1 }
	{ thr   "Lower Threshold value (for smallest eigenvalue)" "Min Eigenvalue Threshold"   real   0.00001 { 0.0 100000000.0 }  -1 }
    }

    set defaultsuffix { "_tensorop" }
    
    set scriptname bis_tensorproperties
    set completionstatus "Done"

    #
    #document
    #
    set category "Diffusion Tensor"    
    set description "Compute common properties from a diffusion tensor such as FA (Fractional Anisotropy), RA (Relative Anisotropy), VR (Volume Ratio) MD (Mean Diffusivity)"
    set description2 ""
    set backwardcompatibility "None"

    $this InitializeImageToImageAlgorithm
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_tensorproperties::Execute {  } {

    set mode   [ $OptionsArray(mode) GetValue ]
    set thr    [ $OptionsArray(thr) GetValue ]
    set image_in [ $this GetInput ]

    set eigen [ vtkmpjImageTensorEigenAnalysis [ pxvtable::vnewobj ] ]
    $this SetFilterCallbacks $eigen "Computing eigenvalues and eigenvectors..."
    $eigen SetInput [ $image_in GetImage ]
    if { $mode != "Eigenvectors" } {
	$eigen SetOutputTypeToEigenvalues
    } else {
	$eigen SetOutputTypeToEigenvectors
    }
    $this SetFilterCallbacks $eigen "Computing eigenvalues"
    $eigen Update

    set outimage [ $OutputsArray(output_image) GetObject ]

    if { $mode != "Eigenvalues" && $mode != "Eigenvectors" } {

	set extr [ vtkImageExtractComponents New ]
	$extr SetInput [ $eigen GetOutput ]
	$extr SetComponents 2

	set thresholdF  [  vtkImageThreshold New ]
	$thresholdF ThresholdByUpper $thr
	$thresholdF SetInValue    1
	$thresholdF SetOutValue   0
	$thresholdF SetReplaceOut 1
	$thresholdF SetReplaceIn  1
	$thresholdF SetInput [ $extr GetOutput ]
	$thresholdF Update


	set filt [ vtkmpjImageTensorInvariants New ]
	$filt SetInput [ $eigen GetOutput ]
	$filt SetMask [ $thresholdF GetOutput ]
	
	if { $mode == "RA" } {
	    $filt  SetOperationToRelativeAnisotropy
	} elseif { $mode == "VR" } {
	    $filt SetOperationToVolumeRatio
	} elseif { $mode == "MD" } {
	    $filt SetOperationToMeanDiffusivity
	} else {
	    $filt SetOperationToFractionalAnisotropy
	}
	$this SetFilterCallbacks $filt "Computing $mode"
	$filt Update
	
	$outimage ShallowCopyImage [ $filt GetOutput ]
	$filt Delete
	$thresholdF Delete
	$extr Delete

    } else {
	$outimage ShallowCopyImage [ $eigen GetOutput ]
    }
    $outimage CopyImageHeader [ $image_in GetImageHeader ]
	
    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0


    $eigen Delete

    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_tensorproperties.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_tensorproperties [pxvtable::vnewobj]]
    $alg MainFunction 
}





