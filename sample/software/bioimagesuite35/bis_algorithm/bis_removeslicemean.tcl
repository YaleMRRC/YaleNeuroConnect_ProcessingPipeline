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

package provide bis_removeslicemean 1.0
package require bis_dualimagealgorithm 1.0


itcl::class bis_removeslicemean {

    inherit bis_dualimagealgorithm

     constructor { } {	 $this Initialize  }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Remove Slice Mean" }
	#overwrite parent method
	public method  CheckInputObjects { } 
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_removeslicemean::Initialize { } {

    PrintDebug "bis_removeslicemean::Initialize"     

    set options {
	    {  usemask   "Use Mask Image"  "Use Mask Image"  boolean   0  { 0 1  }  40  } 
	    {  globalmean "Remove Volume Mean instead of Slice Mean"  "Volume Mean"  boolean   0  { 0 1  }  41  } 
    }
	
	#set inputs { { mask_image  "Mask Image" pxitclimage  ""  2} }
	
    set defaultsuffix { "_rsm" }
    
    set scriptname bis_removeslicemean
    set completionstatus "Done"
    
    #
    #document
    #
    
    set description "Remove Slice/Volumn Mean."
	set description2 "Calculate mean of each slice(frame) or the whole volumn and subtract this value from each voxel of that slice(frame)."
    set backwardcompatibility ""
    set authors "isabella.murphy@yale.edu, xilin.shen@yale.edu."

    set category "Image Processing-4D"    
    
    $this InitializeDualImageAlgorithm
	
	$this RenameInput 0 "Functional Image"
    $this RenameInput 1 "Mask Image" 101
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_removeslicemean::Execute {  } {


    set ok [ pxtclvtkpxcontrib::ConditionalLoadLibrary  vtkbisConnectivityTCL vtkbisROICorrelation 0  ]
    if { $ok == 0 } {
	set errormessage "Failed to load library vtkbisConnectivityTCL"
	return 0
    }

    
    PrintDebug "bis_removeslicemean::Execute"

    set image_in    [ $this GetInput ]

    set remove 0
    set globalmean [ $OptionsArray(globalmean) GetValue ]

    if { $globalmean == 1 } {
	set remove  [ vtkbisRemoveVolumeMean [ pxvtable::vnewobj ]  ] 
    } else {
	set remove  [ vtkbisRemoveSliceMean [ pxvtable::vnewobj ]  ] 
    }
    
    $remove SetInput [ $image_in GetObject ]

    set msk [ $OptionsArray(usemask) GetValue ]
    if { $msk == "1" } {
	puts stdout "Using Mask ..."
	$remove SetImageMask [ [ $this GetInputObject second_image ] GetObject ]
    } 

    if { $globalmean == 1 } {
	$this SetFilterCallbacks $remove "Remove Volume Mean"
    } else {
	$this SetFilterCallbacks $remove "Remove Slice Mean"
    }
    $remove Update

    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage ShallowCopyImage [ $remove GetOutput ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]

    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0

    $remove Delete

    return 1
}

itcl::body bis_removeslicemean::CheckInputObjects { } {


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

    set alg [bis_removeslicemean [pxvtable::vnewobj]]
    $alg MainFunction 
}





