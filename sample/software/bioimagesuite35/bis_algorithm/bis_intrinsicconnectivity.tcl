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

package provide bis_intrinsicconnectivity 1.0
package require bis_dualimagealgorithm 1.0


itcl::class bis_intrinsicconnectivity {

    inherit bis_dualimagealgorithm

     constructor { } {	 $this Initialize  }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Intrinsic Connectivity Map" }
    public method GetSecondOutput { }
    public method GetThirdOutput { }
    public method GetFourthOutput { }
    #overwrite parent method
    public method CheckInputObjects { }
	
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_intrinsicconnectivity::Initialize { } {

    PrintDebug "bis_intrinsicconnectivity::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ mode      "Type of intrinsic connectivity"                       "Mode"             { listofvalues radiobuttons } Whole { Whole Ipsilateral Contralateral }       0 }
	{ usemask   "Use Mask"                                             "Use Mask"         boolean                       1     { 0 1  }                    20 } 
	{ threshold "Threshold to be count as connected"                   "Threshold"        { real triplescale 100 }      0.0   { 0.0 1.0 }                 30 }
	{ calculate "Take absolute sum or square sum of correlation"       "Calculate Method" { listofvalues radiobuttons } Abs   { Abs Sqr Z }                 50 }
	{ range     "Take positive correlation/negative correlation/both " "Range"            { listofvalues radiobuttons } Both  {  Positive Negative Both } 40 }
    }
    
    #this provide output GUI
    set outputs { 
	{ second_output "Overthreshold Count" pxitclimage  ""  10 }   
	{ third_output "Overthreshold sum not normalized" pxitclimage  ""  10 }   
	{ fourth_output "Overthreshold Count not normalized" pxitclimage  ""  10 }   
    }
    
    set defaultsuffix { "_ic" }
    set category "Functional Imaging"    
    set scriptname bis_intrinsicconnectivity
    set completionstatus "Done"
    
    #
    #document
    #
    
    set description "Calculate the intrinsic connectivity of an image."
    set description2 "User can choose the threshold, look at which range (+, - or both correlation) and look at absolute sum or sum squares. Output is a 3D image of absolute sum or sum squares."
    set backwardcompatibility ""
    set authors "isabella.murphy@yale.edu, xilin.shen@yale.edu."
    
    $this InitializeDualImageAlgorithm
    $this RenameInput 0 "Functional Image"
    $this RenameInput 1 "Mask Image" 102
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_intrinsicconnectivity::Execute {  } {


    set ok [ pxtclvtkpxcontrib::ConditionalLoadLibrary  vtkbisConnectivityTCL vtkbisROICorrelation 0  ]
    if { $ok == 0 } {
	set errormessage "Failed to load library vtkbisConnectivityTCL"
	return 0
    }
    
    #set doraw  [ $OptionsArray(raw)   GetValue ]
    set mode [ $OptionsArray(mode) GetValue ]
	
    set msk          [ $OptionsArray(usemask)   GetValue ]
    set threshold    [ $OptionsArray(threshold) GetValue ]
    set calculate    [ $OptionsArray(calculate) GetValue ]
    set range        [ $OptionsArray(range)     GetValue ]
    #set textfilename [ $OptionsArray(filename)  GetValue ]
    set image_in     [ $this GetInput ]
    #set lookN       [ $OptionsArray(lookN)     GetValue ]
    
    
    if { $mode == "Whole" } {
	set map  [ vtkbisIntrinsicConnMap New  ] 
    } else {
	set map [ vtkbisIpsilateralConnMap New ] 
    }
    
    #$map SetOutputRaw  [ expr $doraw > 0 ]
    $map SetThreshold $threshold
    #$map SetFileName $textfilename
    $map SetInput [ $image_in GetObject ]
    if { $mode == "Contralateral" } {
	$map SetDoContralateral 1
    }
    
    
    if { $msk == "1" } {
	puts stdout "Using Mask ..."
	$map SetImageMask [ [ $this GetInputObject second_image ] GetObject ]
    } 
    
    set f(2) 0
    if { $range == "Positive" } {		
	$map SetRange 1
	set f(2) Pos
    } elseif { $range == "Negative" } {
	$map SetRange 2
	set f(2) Neg
    } else {
	$map SetRange 3
	set f(2) Both
    }
    set f(3) 0
    if { $calculate == "Abs" } {
	$map SetAbs 1
	set f(3) Abs
    } elseif { $calculate == "Sqr" } {
	$map SetAbs 2
	set f(3) Sqr
    } else {
	$map SetAbs 3
	set f(3) Z
    }
    
    #if { $lookN == "N" } {
    #	$map SetLookN 1
    #} else {
    #	$map SetLookN 2
    #}
    
    $this SetFilterCallbacks $map "Calculate intrinsic connectivity map with threshold=$threshold"
    $map Update
    
    if { $mode == "Whole" } {
	set mean [ $map GetMean ]
	set std [ $map GetStd ]
	set degreemean [ $map GetDegreeMean ]
	set degreestd [ $map GetDegreeStd ]
	set textv1 "Mean: $mean, Standard Deviation: $std."
	set textv2 "Degree Mean: $degreemean, Degree Standard Deviation: $degreestd."
    } else {
	set lmean [ $map GetLMean ]
	set rmean [ $map GetRMean ]
	set lstd [ $map GetLStd ]
	set rstd [ $map GetRStd ]
	set lsize [ $map GetLSize ]
	set rsize [ $map GetRSize ]
	set ldegreemean [ $map GetLDegreeMean ]
	set rdegreemean	[ $map GetRDegreeMean ]
	set ldegreestd [ $map GetLDegreeStd ]
	set rdegreestd [ $map GetRDegreeStd ]
	set textv1 "Left Brain Mean\t $lmean\n Left Brain Standard Deviation\t $lstd\n Left Brain Number of Voxels\t $lsize\n Right Brain Mean\t $rmean\n Right Brain Standard Deviation\t $rstd\n Right Brain Number of Voxels\t $rsize\n"
	set textv2 "Left Brain Degree Mean\t $ldegreemean\n Left Brain Degree Standard Deviation\t $ldegreestd\n Right Brain Degree Mean\t $rdegreemean\n Right Brain Standard Deviation\t $rdegreestd\n"
	
    }
    set comment [ format " [ $this GetCommandLine full ]" ]    

    #weighted degree normalized
    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage ShallowCopyImage [ $map GetOutput ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]
    [ $outimage GetImageHeader ]  AddComment "$comment $Log" 0
    [ $outimage GetImageHeader ]  AddComment "[ $this GetGUIName ] Log: $textv1" 0
    
    #binary degree normalized
    set outimage2 [ $OutputsArray(second_output) GetObject ]
    $outimage2 ShallowCopyImage [ $map GetOutData2 ]
    $outimage2 CopyImageHeader [ $image_in GetImageHeader ]
    [ $outimage2 GetImageHeader ] AddComment "$comment $Log" 0
    [ $outimage2 GetImageHeader ] AddComment "[ $this GetGUIName ] Log: $textv2" 0
    
    if { $mode == "Whole" } {

	#weighted degree unnormalized
	set outimage3 [ $OutputsArray(third_output) GetObject ]
	$outimage3 ShallowCopyImage [ $map GetOutData3 ]
	$outimage3 CopyImageHeader [ $image_in GetImageHeader ]
	[ $outimage3 GetImageHeader ] AddComment "$comment $Log" 0
	[ $outimage3 GetImageHeader ] AddComment "[ $this GetGUIName ] Log: $textv2" 0
	
	#binary degree unnormalized
	set outimage4 [ $OutputsArray(fourth_output) GetObject ]
	$outimage4 ShallowCopyImage [ $map GetOutData4 ]
	$outimage4 CopyImageHeader [ $image_in GetImageHeader ]
	[ $outimage4 GetImageHeader ] AddComment "$comment $Log" 0
	[ $outimage4 GetImageHeader ] AddComment "[ $this GetGUIName ] Log: $textv2" 0
	
    }

    set fname2 [ $outimage2 cget -filename ]
    if { $fname2 == "" } {
	set f(0) [ $InputsArray(input_image) GetFileName ]
	set f(1) [ $InputsArray(second_image) GetFileName ]
	for { set i 0 } { $i <= 1 } { incr i } {
	    set l($i) [ ::bis_common::SplitFileNameGZ $f($i) ]
	    set f($i) [ file tail [ lindex $l($i) 0 ] ]
	    set ext($i) [ lindex $l($i) 1 ]
	}
	set newname [ file join [ file dirname $f(0) ]  "$f(0)_$f(1)_$f(2)_$f(3)_N_ic" ]
	$outimage2 configure -filename $newname
    }
    
    if { $mode == "Whole" } {
	
	set fname3 [ $outimage3 cget -filename ]
	if { $fname3 == "" } {
	    set f(0) [ $InputsArray(input_image) GetFileName ]
	    set f(1) [ $InputsArray(second_image) GetFileName ]
	    for { set i 0 } { $i <= 1 } { incr i } {
		set l($i) [ ::bis_common::SplitFileNameGZ $f($i) ]
		set f($i) [ file tail [ lindex $l($i) 0 ] ]
		set ext($i) [ lindex $l($i) 1 ]
	    }
	    set newname [ file join [ file dirname $f(0) ]  "$f(0)_$f(1)_$f(2)_$f(3)_N_ic" ]
	    $outimage3 configure -filename $newname
	}
	
	set fname4 [ $outimage4 cget -filename ]
	if { $fname4 == "" } {
	    set f(0) [ $InputsArray(input_image) GetFileName ]
	    set f(1) [ $InputsArray(second_image) GetFileName ]
	    for { set i 0 } { $i <= 1 } { incr i } {
		set l($i) [ ::bis_common::SplitFileNameGZ $f($i) ]
		set f($i) [ file tail [ lindex $l($i) 0 ] ]
		set ext($i) [ lindex $l($i) 1 ]
	    }
	    set newname [ file join [ file dirname $f(0) ]  "$f(0)_$f(1)_$f(2)_$f(3)_N_ic" ]
	    $outimage4 configure -filename $newname
	}
    }

    # This crashes the code -- there is some morey leak somewhere!
    $map Delete

    return 1
}

itcl::body bis_intrinsicconnectivity::GetSecondOutput {  } {
    return [ $this GetOutputObject second_output ]
}

itcl::body bis_intrinsicconnectivity::GetThirdOutput {  } {
    return [ $this GetOutputObject third_output ]
}

itcl::body bis_intrinsicconnectivity::GetFourthOutput {  } {
    return [ $this GetOutputObject fourth_output ]
}

itcl::body bis_intrinsicconnectivity::CheckInputObjects { } {


    set image_in    [ $this GetInput ]
    set d [ $image_in GetImageSize ]
    if { $d < 2 } {
	return 0
    }
    
    set msk [ $OptionsArray(usemask) GetValue ]
    if { $msk == "1" } {
	set image_in    [ $this GetSecondInput ]
        set d [ $image_in GetImageSize ]
        if { $d < 2 } {
	    return 0
    	}
    }
	
    return 1

}




# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_mediantemporalsmoothimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_intrinsicconnectivity [ pxvtable::vnewobj ] ]
    $alg MainFunction 
}








