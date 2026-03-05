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
package require bis_resliceimage 1.0
package provide bis_imagemathoperations 1.0

#
# blend image
#

itcl::class bis_imagemathoperations {

    inherit bis_dualimagetransformationalgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }

    public method GetGUIName { } { return "Math Operations"}
    public method UpdateOutputFilenames { } 


    # T-test computation for 4D Images
    protected method ComputeIntersection { img1 img2 threshold mode } 
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_imagemathoperations::Initialize { } {

    PrintDebug "bis_imagemathoperations::Initialize" 

    set options {
	{ interp        "Interpolation Mode that is used when reslicing the image" "Interpolation Mode"  listofvalues Linear { "NearestNeighbor" "Linear" "Cubic" }  -10 }
	{ background    "Background Level used to fill voxels outside of mapped area" "Background Value"  real 0.0 { -100000 100000 }  -100 }
	{ mathoperation "Pick math operation" "Operation "  listofvalues Add { "Add" "Subtract" "Multiply" "Divide"  "Intersection" }  1 }
	{ interthr  "Threshold for interesection Operation" "Intersection Threshold"   real   0.0 { -100000000.0 100000000.0 }  2 }
	{ intermode "Type of Interesection mode" "Intersection Mode"  listofvalues Positive { "Positive" "Negative" "Both" }  3 }
    }
	
    set defaultsuffix { "_mathop" }
    
    set scriptname bis_imagemathoperations
    set completionstatus "Done"
    #
    #document
    #

    set category "Image Processing Dual"
    set description "Add, Subtract, Multiply or Divide two images to give an output."
    set description2 ""
    set backwardcompatibility " "
    set authors "alark.joshi@yale.edu, xenophon.papademetris@yale.edu."

    $this InitializeDualImageTransformationAlgorithm
}

itcl::body bis_imagemathoperations::UpdateOutputFilenames { } {

    set defaultsuffix "_[ string tolower [ $OptionsArray(mathoperation) GetValue ]]"
    return [ bis_dualimagetransformationalgorithm::UpdateOutputFilenames ]
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_imagemathoperations::ComputeIntersection { img1 img2 threshold mode } {

    if { [ $img1 GetNumberOfPoints ] != [ $img2 GetNumberOfPoints ] } {
	set errormessage "Unequal Image Sizes\n Cannot Perform Compare Operation $mode!"
	return 0
    }

    set currentresults [ pxitclimage \#auto ]
    set math [ vtkpxImageThresholdedIntersection [ pxvtable::vnewobj ]]
    $math AddInput $img1
    $math AddInput $img2
    $math SetThreshold  $threshold
    switch -exact -- $mode {
	"Positive" { $math SetThresholdMode 0}
	"Negative" { $math SetThresholdMode 1}
	"Both"     { $math SetThresholdMode 2}
    }
    SetFilterCallbacks $math "Computing Intersection"    
    $math Update
    $currentresults ShallowCopyImage [ $math GetOutput ]
    
    $math Delete
    return $currentresults
}



# ----------------------------------------------------------------------------------------------------------------

itcl::body bis_imagemathoperations::Execute {  } {

    PrintDebug "bis_imagemathoperations::Execute"
    set mathop [ $OptionsArray(mathoperation) GetValue ]

    set reslice_alg [bis_resliceimage [pxvtable::vnewobj]]
    $reslice_alg InitializeFromContainer $this
    $reslice_alg SetInput [ $this GetInput ] 
    $reslice_alg SetSecondInput [ $this GetSecondInput ] 
    $reslice_alg SetTransformation [ $this GetTransformation ] 
    $reslice_alg SetOptionValue interp     [ $OptionsArray(interp) GetValue ]
    $reslice_alg Execute

    set reslimage [  [ $reslice_alg GetOutput ] GetImage ]
    set mathOpsResult 0

    set outimage [ $this GetOutput ] 

    if { $mathop == "Intersection" } {
	set thr [ $OptionsArray(interthr) GetValue ]
	set md [ $OptionsArray(intermode) GetValue ]
	set tmp [ $this ComputeIntersection [ [ $this GetInput ] GetImage ] $reslimage $thr $md ]
	if { $tmp == 0 } {
	    return 0
	}
	$outimage ShallowCopyImage [ $tmp GetImage ]
	itcl::delete object $tmp
    } else {
	set imcast2 [ vtkImageCast [ pxvtable::vnewobj ]]
	$imcast2 SetInput $reslimage
	$imcast2 SetOutputScalarType [ [ [ $this GetInput ] GetImage ] GetScalarType ]
	$imcast2 Update

	set mathOpsResult [ vtkImageMathematics [  pxvtable::vnewobj ] ]
	
	if { $mathop == "Add" } {
	    $mathOpsResult SetOperationToAdd 
	} elseif { $mathop == "Subtract" } {
	    $mathOpsResult SetOperationToSubtract
	} elseif { $mathop == "Multiply" } { 
	    $mathOpsResult SetOperationToMultiply
	} else {
	    $mathOpsResult SetOperationToDivide
	    $mathOpsResult DivideByZeroToCOn
	    $mathOpsResult SetConstantC 0.0
	}
	
	$mathOpsResult SetInput1  [ [ $this GetInput ] GetImage ]
	$mathOpsResult SetInput2  [ $imcast2 GetOutput ] 
	$mathOpsResult Update
	$outimage ShallowCopyImage [ $mathOpsResult GetOutput ]
    }


    # Output orientation etc. is same as input

    set pimage   [ $this GetSecondInput ] 

    $outimage CopyImageHeader [ $pimage GetImageHeader ]

    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0

    puts stderr "Outimage Description = [ $outimage GetDescription ]"

    if { $mathOpsResult !=0 } {
	$mathOpsResult Delete
    }
    itcl::delete object $reslice_alg

    return 1
}


# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_imagemathoperations.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function
 

    set alg [bis_imagemathoperations [pxvtable::vnewobj]]
    $alg MainFunction 
}

