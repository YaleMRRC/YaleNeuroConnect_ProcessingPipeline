#!/bin/sh
# the next line restarts using wish \
	exec vtk "$0" -- "$@"


lappend auto_path [ file dirname [ info script ]]
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] base]
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] apps]

package provide bis_comparecorrelations 1.0
package require bis_dualimagealgorithm 1.0

itcl::class bis_comparecorrelations {
    
	inherit bis_dualimagealgorithm

	constructor { } {	 $this Initialize  }
	
	public method Initialize { }
	public method Execute { }
	public method GetGUIName    { } { return "Compare Correlations" }
	
	public method CheckInputObjects { } 
    }

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_comparecorrelations::Initialize { } {

	PrintDebug "bis_comparecorrelations::Initialize" 
	
	#commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
	set options {
	    { n1 "Number of Subjects for Dataset 1" "Number of Subjects" int 6 { 6 100000000 } 0 }
	    { n2 "Number of Subjects for Dataset 2" "Number of Subjects" int 6 { 6 100000000 } 0 }
	    { dofisher "Perform the fisher transform on the correlations 1st"  "do fisher" boolean 0 { 0 1 } 20 } 
	}

	set defaultsuffix { "_zscore" }
	set scriptname bis_comparecorrelations
	set completionstatus "Done"

	#
	#document
	#
	

	$this InitializeDualImageAlgorithm
	
	$this RenameInput 0 "DataSet 1"
	$this RenameInput 1 "DataSet 2" 101
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_comparecorrelations::Execute { } {

    set ok [ pxtclvtkpxcontrib::ConditionalLoadLibrary  vtkbisConnectivityTCL vtkbisROICorrelation 0  ]
    if { $ok == 0 } {
	set errormessage "Failed to load library vtkbisConnectivityTCL"
	return 0
    }

    PrintDebug "bis_comparecorrelations::Execute"
    
    set mode   [ $OptionsArray(dofisher) GetValue ]
    
    set image1 [ [ $this GetInput       ] GetObject ]
    set image2 [ [ $this GetSecondInput ] GetObject ]

    #----- do fisher --------#
    if { $mode == 1 } { 
	set rtoz1 [ vtkbisRtoZ [ pxvtable::vnewobj ] ]
	$rtoz1 SetInput $image1
	$rtoz1 Update
	
	set image1 [ $rtoz1 GetOutput ] 
	
	set rtoz2 [ vtkbisRtoZ [ pxvtable::vnewobj ] ]
	$rtoz2 SetInput $image2
	$rtoz2 Update	
	
	set image2 [ $rtoz2 GetOutput ] 
    }

    #----- subtract fisher --------#
    set mathop [ vtkImageMathematics [  pxvtable::vnewobj ] ]
    $mathop SetOperationToSubtract
    $mathop SetInput1 $image1
    $mathop SetInput2 $image2
    $mathop Update

    #----- Create Std error --------#
    set n1 [ $OptionsArray(n1) GetValue ]
    set n2 [ $OptionsArray(n2) GetValue ]
    
    set se [ expr 1.0 / ( sqrt( 1.0 / ($n1-3.0) + 1.0 / ($n2-3.0) ) ) ]
    
    #----- Divide sub by std error ----#
    set scale [ vtkImageShiftScale [ pxvtable::vnewobj ] ]
    $scale SetInput [ $mathop GetOutput ] 
    $scale SetOutputScalarTypeToFloat
    $scale SetShift 0.0
    $scale SetScale $se
    $scale Update

    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage ShallowCopyImage [ $scale GetOutput ] 
    $outimage CopyImageHeader [ [ $this GetInput ] GetImageHeader ]
    
    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0

    $mathop Delete
    $scale  Delete

    if { $mode == 1 } { 
	$rtoz1 Delete
	$rtoz2 Delete
    }

    return 1
}

# -----------------------------------------------------------------------------------------------------
itcl::body bis_comparecorrelations::CheckInputObjects { } {
    
    set image1    [ $this GetInput ]
    set image2    [ $this GetSecondInput ]
    
    set img1  [ $image1 GetImage ]
    set img2  [ $image2 GetImage ] 

    if { [ $img1 GetNumberOfPoints ] != [ $img2 GetNumberOfPoints ] } {
	set errormessage "Unequal Image Sizes\n"
	return 0
    }
    
    return 1
    
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_comparecorrelations.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
	# this is essentially the main function

	set alg [ bis_comparecorrelations [ pxvtable::vnewobj ] ]
	$alg MainFunction 
}




