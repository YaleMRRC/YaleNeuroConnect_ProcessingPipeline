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

package provide bis_connectivityhistogram 1.0
package require bis_dualimagealgorithm 1.0


itcl::class bis_connectivityhistogram {

    inherit bis_dualimagealgorithm

    constructor { } {	 $this Initialize  }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "CUDA Intrinsic Connectivity Map" }

    public method UpdateOutputFilenames { } 	

    #overwrite parent method
    public method CheckInputObjects { }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_connectivityhistogram::Initialize { } {

    PrintDebug "bis_connectivityhistogram::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ usegpu   "Perform Computation on gpu"  "Use GPU"         boolean       1     { 0 1  }                    10 } 
	{ usemask   "Use Mask"  "Use Mask"         boolean                       0     { 0 1  }                    20 } 
	{ numberofbins    "Number of bins for the joint histogram"          "Number of Bins"     int   201    { 1 1000 } 40 }
    }

    #this provide output GUI

    set defaultsuffix { "_hist" }
    set category "Functional Imaging"    
    set scriptname bis_connectivityhistogram
    set completionstatus "Done"
    
    #
    #document
    #
    
    set description "Calculate the histogram connectivity of an image."

    set backwardcompatibility ""
    set authors "dustin scheinost"
    
    $this InitializeDualImageAlgorithm
    $this RenameInput 0 "Functional Image"
    $this RenameInput 1 "Mask Image" 102
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_connectivityhistogram::Execute {  } {

    set ok [ pxtclvtkpxcontrib::ConditionalLoadLibrary  vtkbisConnectivityTCL  0  ]
    if { $ok == 0 } {
	set errormessage "Failed to load library vtkbisConnectivityTCL"
	return 0
    }

    set msk          [ $OptionsArray(usemask)    GetValue ]
    set gpu          [ $OptionsArray(usegpu)     GetValue ]
    set numbins      [ $OptionsArray(numberofbins) GetValue ]
    set image_in     [ $this GetInput ]
    
    set map 0 

    if { $gpu ==1 } {
	if { $::pxtclvtkpxcontrib::usescuda == 0 } {
	    puts stdout "CUDA is not available switching to CPU code"
	    set map  [ vtkbisIntrinsicHistogram New  ] 
	} else {
	    set map  [ vtkbisCUDAIntrinsicCorrelation New  ] 
	    $map SetUseGPU 1
	}
    } else {
	set map  [ vtkbisIntrinsicHistogram New  ] 
    }

    if { $map == 0 } { 
	puts stderr "Something went wrong"
	return 0;
    }

    $map SetNumBins $numbins
    $map SetInput [ $image_in GetObject ]

    if { $msk == "1" } {
	puts stdout "Using Mask ..."
	$map SetImageMask [ [ $this GetInputObject second_image ] GetObject ]
    } 
    
    $this SetFilterCallbacks $map "Calculate intrinsic connectivity histogram"
    $map Update

    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage ShallowCopyImage [ $map GetOutput ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]
    
    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0
    $map Delete
    
    return 1
}

itcl::body bis_connectivityhistogram::CheckInputObjects { } {

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

itcl::body bis_connectivityhistogram::UpdateOutputFilenames { } {
    
    set gpu [ $OptionsArray(usegpu) GetValue ]
    if { $::pxtclvtkpxcontrib::usescuda == 0 } {
	set gpu 0
    }

    if { $gpu ==1 } {
	set defaultsuffix [ list  "_GPU_hist" ]
    } else { 
	set defaultsuffix [ list  "_CPU_hist" ]
    }

    return [ ::bis_imagetoimagealgorithm::UpdateOutputFilenames  ]
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_mediantemporalsmoothimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [ bis_connectivityhistogram [ pxvtable::vnewobj ] ]
    $alg MainFunction 
}








