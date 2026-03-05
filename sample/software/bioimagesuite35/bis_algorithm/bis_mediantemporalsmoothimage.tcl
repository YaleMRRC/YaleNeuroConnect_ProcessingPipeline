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

package provide bis_mediantemporalsmoothimage 1.0
package require bis_dualimagealgorithm  1.0


itcl::class bis_mediantemporalsmoothimage {

    inherit bis_dualimagealgorithm 

     constructor { } {	 $this Initialize  }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Median Temporal Smooth" }
	#override parent function
	public method CheckInputObjects { }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_mediantemporalsmoothimage::Initialize { } {

    PrintDebug "bis_mediantemporalsmoothimage::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ radius  "Median Temporal Window size" "Radius in frames"  integer 2 { 1 9 }  0 }
	{ usemask   "Use Mask Image"  "Use Mask Image"  boolean   0  { 0 1  }  40  }         
    }
	
	#for testing functions has nothing to do with this class
	#set outputs { 
	#		 { second_output "selected blocks" pxitclimage  ""  10 }   
	#	}

    set defaultsuffix { "_mtsm" }
    
    set scriptname bis_mediantemporalsmoothimage
    set completionstatus "Done"
    
    #
    #document
    #
    
    set description "Smooth an image with median filter."
	set description2 "Temporal smoothing using median filter. Length of the kernel is 2*radius+1."
    set backwardcompatibility ""
    set authors "isabella.murphy@yale.edu, xilin.shen@yale.edu."
    set category "Image Processing-4D"
    
    $this InitializeDualImageAlgorithm
	
	$this RenameInput 0 "Functional Image"
	#set priority to 102 to make it optional
    $this RenameInput 1 "Mask Image" 102
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_mediantemporalsmoothimage::Execute {  } {


    set ok [ pxtclvtkpxcontrib::ConditionalLoadLibrary  vtkbisConnectivityTCL vtkbisROICorrelation 0  ]
    if { $ok == 0 } {
	set errormessage "Failed to load library vtkbisConnectivityTCL"
	return 0
    }

    
    PrintDebug "bis_mediantemporalsmoothimage::Execute"

    set radius   [ $OptionsArray(radius) GetValue ]
	#set threshold [ $OptionsArray(threshold) GetValue ]
    set image_in    [ $this GetInput ]

    
    set smooth  [ vtkbisMedianTemporalSmoothing [ pxvtable::vnewobj ]  ] 
    $smooth SetRadius $radius
    $smooth SetInput [ $image_in GetObject ]
	#$smooth SetThreshold $threshold
	set msk [ $OptionsArray(usemask) GetValue ]
	if { $msk == "1" } {
	puts stdout "Using Mask ..."
	$smooth SetImageMask [ [ $this GetInputObject second_image ] GetObject ]
    } 
    $this SetFilterCallbacks $smooth "Median Temporal Smoothing Image with radius=$radius"
    $smooth Update

    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage ShallowCopyImage [ $smooth GetOutput ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]
	
	#set outimage2 [ $OutputsArray(second_output) GetObject ]
	#$outimage2 ShallowCopyImage [ $smooth GetResult ] 
	#$outimage2 CopyImageHeader [ $image_in GetImageHeader ]

    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0
	#[ $outimage2 GetImageHeader ] AddComment "$comment $Log" 0
    $smooth Delete
	
	#set fname2 [ $outimage2 cget -filename ]
	#if { $fname2 == "" } {
	#set f(0) [ $InputsArray(input_image) GetFileName ]
	#set f(1) [ $InputsArray(second_image) GetFileName ]
	#for { set i 0 } { $i <= 1 } { incr i } {
	#set l($i) [ ::bis_common::SplitFileNameGZ $f($i) ]
	#set f($i) [ file tail [ lindex $l($i) 0 ] ]
	#set ext($i) [ lindex $l($i) 1 ]
	#}
	#set newname [ file join [ file dirname $f(0) ]  "_selectedblocks" ]
	#$outimage2 configure -filename $newname
	#}

    return 1
}

itcl::body bis_mediantemporalsmoothimage::CheckInputObjects { } {


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

    set alg [bis_mediantemporalsmoothimage [pxvtable::vnewobj]]
    $alg MainFunction 
}





