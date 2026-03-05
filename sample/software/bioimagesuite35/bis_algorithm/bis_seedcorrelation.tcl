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

package provide bis_seedcorrelation 1.0
package require bis_dualimagealgorithm 1.0


itcl::class bis_seedcorrelation {

    inherit bis_dualimagealgorithm

     constructor { } {	 $this Initialize  }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Seed Correlation" }
    public method CheckInputObjects { }
    public method UpdateOutputFilenames { }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_seedcorrelation::Initialize { } {

    PrintDebug "bis_seedcorrelation::Initialize" 
	
    set inputs { 
    	{ third_image "Mask Image" pxitclimage "" 102}     
    }
    
    set options {
	{ usemask   "Use Mask Image"  "Use Mask Image"  boolean   0  { 0 1  }  10  }
	{ raw   "Raw Correlation"  "Compute Raw Correlations"  boolean   0  { 0 1  }  -10  }
	{ ztransform   "Z Transform"  "Z Transform"  boolean   0  { 0 1  }  -20  }
	{ usegpu   "Use GPU Implementation (if available)"  "Use GPU"  boolean   0  { 0 1  }  -21  }
    }
    
    set defaultsuffix { "_sc" }
    
    set scriptname bis_seedcorrelation
    set completionstatus "Done"
    set category "Functional Imaging"
    #
    #document
    #
    
    set description "Correlation between brain and ROIs."
    set description2 "Calculate correlation among ROIs and the whole brain image voxel by voxel."
    set backwardcompatibility ""
    set authors "isabella.murphy@yale.edu, xilin.shen@yale.edu."

    $this InitializeDualImageAlgorithm
	
    $this RenameInput 0 "Functional Image"
    $this RenameInput 1 "ROI Mean"
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_seedcorrelation::Execute {  } {


    set ok [ pxtclvtkpxcontrib::ConditionalLoadLibrary  vtkbisConnectivityTCL vtkbisROICorrelation 0  ]
    if { $ok == 0 } {
	set errormessage "Failed to load library vtkbisConnectivityTCL"
	return 0
    }


    set doraw       [ $OptionsArray(raw)   GetValue ]
    set ztranform   [ $OptionsArray(ztransform) GetValue ]
    set usegpu      [ $OptionsArray(usegpu) GetValue ]
    set con 0

    set image_in    [ $this GetInput ]

    set crr 0
    if { $usegpu > 0 } {
	catch { set crr  [ vtkbisCUDAROICorrelation New ] }
	if { $crr == 0 } { set usegpu 0 }
    }

    if { $usegpu == 0 } {
	catch { set crr  [ vtkbisROICorrelation New  ] }
	if { $crr ==0 } {
	    return 0
	}
    }

    if { [ $crr GetClassName ] == "vtkbisCUDAROICorrelation" } {
	puts stdout "+++++++++++++ Using GPU Accelerated Version "
    }

    $crr SetOutputRaw  [ expr $doraw > 0 ]
    $crr SetInput [ $image_in GetObject ]
    $crr SetAverageROI [ [ $this GetInputObject second_image ] GetObject ]
    set msk [ $OptionsArray(usemask) GetValue ]
    if { $msk == "1" } {
	puts stdout "Using Mask ..."
	$crr SetImageMask [ [ $this GetInputObject third_image ] GetObject ]
    } 
    $this SetFilterCallbacks $crr "ROI Correlation"
    $crr Update
    
    set outimage [ $OutputsArray(output_image) GetObject ]
    if { $ztranform == "1" } {
	puts "doing z transform"
	set output [ vtkImageData New ]
	set fit [ vtkbisConnectivityUtility New ]
	$fit Ztransform [ $crr GetOutput ] $output
	$outimage ShallowCopyImage $output
	$fit Delete
    } else {
	$outimage ShallowCopyImage [ $crr GetOutput ]
    }
    
    $outimage CopyImageHeader [ $image_in GetImageHeader ]
    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0

    
    set nc [ [ $outimage GetImage ] GetNumberOfScalarComponents ]
    for { set i 0 } { $i < $nc } { incr i } {
	puts stderr "Frame $i : Range = [ [ [ [ $outimage GetImage ] GetPointData ] GetScalars ] GetRange $i ]"
    }
    $crr Delete
    

    return 1
}
itcl::body bis_seedcorrelation::CheckInputObjects { } {


    set image_in    [ $this GetInput ]
    set d [ $image_in GetImageSize ]
    if { $d < 1 } {
	return 0
    }
	
    set image_in    [ $this GetSecondInput ]
    set d [ $image_in GetImageSize ]
    if { $d < 1 } {
	return 0
    }
	
    set msk [ $OptionsArray(usemask) GetValue ]
    if { $msk == "1" } {
	set image_in    [ $this GetInputObject third_image ]
	set d [ $image_in GetImageSize ]
	if { $d < 1 } {
	    return 0
	}
    }
    
    return 1

}
itcl::body bis_seedcorrelation::UpdateOutputFilenames { } {

    set f(0) [ $InputsArray(input_image) GetFileName ]
    set f(1) [ $InputsArray(second_image) GetFileName ]
    set f(2) [ $InputsArray(third_image) GetFileName ]
    
    for { set i 0 } { $i <= 2 } { incr i } {
	set l($i) [ ::bis_common::SplitFileNameGZ $f($i) ]
	set f($i) [ file tail [ lindex $l($i) 0 ] ]
	set ext($i) [ lindex $l($i) 1 ]
    }
    
    set fname [ file join [ file dirname $f(0) ] "$f(0)_$f(1)_$f(2)" ]
    set outlist [ $this CreateDefaultOutputFileList $fname ]
    
    set force 0;    if { $guimode == "managed" } {	set force 1    }    
    $OutputsArray(output_image) SetFileName "[ lindex $outlist 0 ]$ext(0)" $force
    return 1

}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_temporalsmoothimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_seedcorrelation [pxvtable::vnewobj]]
    $alg MainFunction 
}





