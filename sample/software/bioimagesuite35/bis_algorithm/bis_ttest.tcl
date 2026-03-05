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

package provide bis_ttest 1.0
package require bis_dualimagealgorithm 1.0

itcl::class bis_ttest {

	inherit bis_dualimagealgorithm

	 constructor { } {	 $this Initialize  }

	public method Initialize { }
	public method Execute { }
	public method GetGUIName    { } { return "Compute T-Test" }
	#override parent function
	public method CheckInputObjects { }
	public method UpdateOutputFilenames { } 
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_ttest::Initialize { } {

	PrintDebug "bis_ttest::Initialize" 
	
	#commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
	set options {
	    { mode      "Type of T Test"	"Mode"	{ listofvalues radiobuttons } paired { paired unpaired singlegroup } 0 }
	}

	set defaultsuffix { "_ttest" }
	set scriptname bis_ttest
	set completionstatus "Done"

	#
	#document
	#
	
	set description "t test."
	set description2 "takes two inputs and computes either a paired t-test or an unpaired t-test or a single group t-test. For paired t-test both images must have the same number of frames."
	set backwardcompatibility ""
	set authors "isabella.murphy@yale.edu"

	$this InitializeDualImageAlgorithm
	
	$this RenameInput 0 "DataSet 1"
	$this RenameInput 1 "DataSet 2" 101
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_ttest::Execute {  } {
    PrintDebug "bis_ttest::Execute"
    
    set mode   [ $OptionsArray(mode) GetValue ]
    
    set image1 [ $this GetInput ]
    set image2 [ $this GetSecondInput ]
    
    set img1  [ $image1 GetImage ]
    set img2  [ $image2 GetImage ] 
    
    set tlist [ list $img1 $img2 ]
    set timg ""

    if { $mode == "paired" } {
	set imcast2 [ vtkImageCast [ pxvtable::vnewobj ]]
	$imcast2 SetInput $img2
	$imcast2 SetOutputScalarType [ $img1 GetScalarType ]
	$imcast2 Update
	
	set math [ vtkImageMathematics [ pxvtable::vnewobj ]]
	$math SetInput1 $img1
	$math SetInput2 [ $imcast2 GetOutput ]
	$math SetOperationToSubtract
	$math Update
	
	set timg [ vtkImageData New ]
	$timg ShallowCopy [ $math GetOutput ]
	$math Delete
	$imcast2 Delete
	set tlist $timg
    }

    if { $mode == "singlegroup" } {
	set tlist $img1 
    }
    
    set n [ llength $tlist ] 
    puts stderr "tlist=$tlist n=$n"
    set math [ vtkpxComputeTmap [ pxvtable::vnewobj ]]
    
    for { set i 0 } { $i < $n } { incr i } {
	set ave($i) [ vtkbisImageAverageComponents [ pxvtable::vnewobj ] ]
	$ave($i) SetInput [ lindex $tlist $i ]
	$ave($i) Update

	if { $i == 0 } {
	    $math SetInput  [ $ave($i) GetOutput ]
	    $math SetInputStandardDeviation  [ $ave($i) GetStandardDeviationImage ] 
	    $math SetNumberOfSamples1 [ $img1 GetNumberOfScalarComponents ]
	} else {
	    $math SetInput2  [ $ave($i) GetOutput ]
	    $math SetInputStandardDeviation2  [ $ave($i) GetStandardDeviationImage ]
	    $math SetNumberOfSamples2 [ $img2 GetNumberOfScalarComponents ]
	}
	$ave($i) Delete
    }
    
    $math SetNumberOfInputs $n
    $math SetScaleFactor 1000.0
    $math Update
    
    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage ShallowCopyImage [ $math GetOutput ]
    $outimage CopyImageHeader [ $image1 GetImageHeader ]
    
    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0
    
    if { $timg !="" } {
	$timg Delete
    }

   
    puts stdout "Results Range: [ [ [ [ $outimage GetImage ] GetPointData ] GetScalars ] GetRange ]"
    $math Delete
           
    return 1
}

# -----------------------------------------------------------------------------------------------------
itcl::body bis_ttest::UpdateOutputFilenames { } {

    set mode   [ $OptionsArray(mode) GetValue ]
    if { $mode == "singlegroup" } {
	set defaultsuffix { "_singlettest" }
    } elseif { $mode == "paired" } {
	set defaultsuffix { "_pairedttest" }
    } else {
	set defaultsuffix { "_unpairedttest" }
    }
    
    #puts stderr "ttest defaultsuffix=$defaultsuffix, guimode=$guimode"

    if { $mode != "singlegroup" } {
	return [ ::bis_dualimagealgorithm::UpdateOutputFilenames  ]
    }

    return [ ::bis_imagetoimagealgorithm::UpdateOutputFilenames  ]

}


itcl::body bis_ttest::CheckInputObjects { } {

    set mode   [ $OptionsArray(mode) GetValue ]
    set image1    [ $this GetInput ]
    set d [ $image1 GetImageSize ]
    if { $d < 2 } {
	set errormessage "Bad Second Image\n Cannot Perform $mode t-test!"
	return 0
    }

    set img1  [ $image1 GetImage ]
    if { [ $img1 GetNumberOfScalarComponents ] <2  } { 
	set errormessage "Not enough frmes to  perform compare $mode t-test!"
	return 0
    }


    if { $mode == "singlegroup" } {
	return 1
    }
    


    set image2    [ $this GetSecondInput ]
    set d [ $image2 GetImageSize ]
    if { $d < 2 } {
	set errormessage "Bad Second Image\n Cannot Perform $mode t-test!"
	return 0
    }
    
    set img1  [ $image1 GetImage ]
    set img2  [ $image2 GetImage ] 
    set mode   [ $OptionsArray(mode) GetValue ]
    

    if { [ $img1 GetNumberOfPoints ] != [ $img2 GetNumberOfPoints ] } {
	set errormessage "Unequal Image Sizes\n Cannot Perform Compare $mode t-test!"
	return 0
    }
    
    if { $mode == "paired" } {
	if { [ $img1 GetNumberOfScalarComponents ] != [ $img2 GetNumberOfScalarComponents ] } {
	    set errormessage "Unequal Number of Image Frames\n Cannot Perform paired t-test!"
	    return 0
	}
    }
    
    return 1
    
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_ttest.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
	# this is essentially the main function

	set alg [bis_ttest [pxvtable::vnewobj]]
	$alg MainFunction 
}





