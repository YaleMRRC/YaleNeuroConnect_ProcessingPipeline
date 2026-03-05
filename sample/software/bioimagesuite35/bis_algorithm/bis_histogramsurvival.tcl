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

package provide bis_histogramsurvival 1.0
package require bis_dualimagealgorithm	1.0


itcl::class bis_histogramsurvival {

    inherit bis_dualimagealgorithm 

     constructor { } {	 $this Initialize  }

    public method CheckInputObjects { } 
    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Histo Survival" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_histogramsurvival::Initialize { } {

    PrintDebug "bis_histogramsurvival::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ usemask     "Use Mask"	  "Use Mask"   boolean			     0 { 0 1  }	      5 } 
	{ donormalize     "normalize oto guassian variable"	  "normalize"   integer			     0 { 0 2  }	      6 }
 	{ doneg     "do negative correlations"	  "neg corr"   boolean			     0 { 0 1  }	      6 } 
	{ dozero     "include a threshold of zero in degree"	  "zero frame"   boolean			     0 { 0 1  }	      6 } 
	{ factor     "a hack for both +/- histogram to be add"	  "zero frame"   boolean			     1 { 0 1  }	      6 } 
    }


    set defaultsuffix { "survival" }
    
    set scriptname bis_histogramsurvival
    set completionstatus "Done"

    #
    #document
    #

    $this InitializeDualImageAlgorithm

    $this RenameInput 0 "Histogram Image"
    #set priority to 102 to make it optional
    $this RenameInput 1 "Mask Image" 102
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_histogramsurvival::Execute {  } {

    set ok [ pxtclvtkpxcontrib::ConditionalLoadLibrary  vtkbisConnectivityTCL 0  ]
    if { $ok == 0 } {
	set errormessage "Failed to load library vtkbisConnectivityTCL"
	return 0
    }

    PrintDebug "bis_histogramsurvival::Execute"

    set image_in    [ $this GetInput ]

    set smooth  [ vtkbisHistogramToSurvivalCurve [ pxvtable::vnewobj ]  ]
    set msk [ $OptionsArray(usemask) GetValue ]
    set donormalize [ $OptionsArray(donormalize) GetValue ]
    set doneg [ $OptionsArray(doneg) GetValue ]
    set dozero [ $OptionsArray(dozero) GetValue ]

    if { $msk == "1" } {
	puts stdout "Using Mask ..."
	$smooth SetMaskImage [ [ $this GetInputObject second_image ] GetObject ]
    } 

    $smooth SetDoZeroFrame $dozero
    $smooth SetDoNormalize $donormalize
    $smooth SetDoNeg $doneg
    $smooth SetFactor  [ $OptionsArray(factor) GetValue ]
    $smooth SetInput [ $image_in GetObject ]
    $smooth Update

    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage ShallowCopyImage [ $smooth GetOutput ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]

    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0

    if { $dozero == 1 } {
	set appnd [ vtkImageAppendComponents [ pxvtable::vnewobj ] ]	
	
	$appnd AddInput	[ $smooth GetMaskImage ] 
	$appnd AddInput	[ $smooth GetOutput ]
	$appnd Update

	set outimage [ $OutputsArray(output_image) GetObject ]
	$outimage ShallowCopyImage [ $appnd GetOutput ]
	$outimage CopyImageHeader [ $image_in GetImageHeader ]
	
	set comment [ format " [ $this GetCommandLine full ]" ]
	[ $outimage GetImageHeader ] AddComment "$comment $Log" 0

	$appnd Delete
    }

    $smooth Delete

    return 1
}

itcl::body bis_histogramsurvival::CheckInputObjects { } {

    set image_in    [ $this GetInput ]
    set d [ $image_in GetImageSize ]
    if { $d < 2 } {
	return 0
    }
    
    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_histogramsurvival.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_histogramsurvival [pxvtable::vnewobj]]
    $alg MainFunction 
}





