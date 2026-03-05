#!/bin/sh
# the next line restarts using wish \
    exec vtk "$0" "$@"

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

package provide bis_combineframes 1.0
package require bis_imagetoimagealgorithm 1.0

itcl::class bis_combineframes {

    inherit bis_imagetoimagealgorithm

     constructor { } {	 $this Initialize  }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Combine Frames" }
    public method  UpdateOutputFilenames { } 
}


# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_combineframes::Initialize { } {

    PrintDebug "bis_combineframes::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ mode "Combining Mode either Mean,Sum,Min, Max or Magnitude" "mode" listofvalues Mean { Mean Sum Min Max Magn } 1 }
    }

    set defaultsuffix { "mean" }
    
    set scriptname bis_combineframes
    set completionstatus "Done"

    #
    #document
    #
    set category "Image Processing-4D"

    set description "Takes in a 4d image and creates a 3d mean, maximum, sum, minimum, or magnitude"
    set description2 ""

    $this InitializeImageToImageAlgorithm
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_combineframes::Execute {  } {

    PrintDebug "bis_combineframes::Execute"


    set ok [ pxtclvtkpxcontrib::ConditionalLoadLibrary  vtkbisConnectivityTCL vtkbisROICorrelation 0  ]
    if { $ok == 0 } {
	set errormessage "Failed to load library vtkbisConnectivityTCL"
	return 0
    }

    set average  [ vtkbisTimeSeriesStat [ pxvtable::vnewobj ]  ]
    if { $average == 0 } {
	set errormessage "Cannot compute Time Series average .. bad library"
	return 0
    }

    set image_in    [ $this GetInput ]
    set outimage [ $OutputsArray(output_image) GetObject ]

    set md [ $OptionsArray(mode) GetValue ]
    
    $average SetInput [ $image_in GetObject ]

    if { $md == "Max" } {
	$average SetMode 3
    } elseif { $md == "Sum" } {
	$average SetMode 1
    }  elseif { $md == "Min" } {
	$average SetMode 2
    }  elseif { $md == "Magn" } {
	$average SetMode 4
    } else {
	$average SetMode 0
    }
    $average Update
    $outimage ShallowCopyImage [ $average GetOutput ]
    $average Delete

	

    $outimage CopyImageHeader [ $image_in GetImageHeader ]
    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment" 0

    return 1
}

itcl::body bis_combineframes::UpdateOutputFilenames { } { 

    set md [ $OptionsArray(mode) GetValue ]

    if { $md == "Max" } {
	set defaultsuffix { "_max" }
    } elseif { $md == "Sum" } {
	set defaultsuffix { "_sum" }
    }  elseif { $md == "Min" } {
	set defaultsuffix { "_min" }
    }  elseif { $md == "Magn" } {
	set defaultsuffix { "_magn" }
    } else {
	set defaultsuffix { "_mean" }
    }

    return [ ::bis_imagetoimagealgorithm::UpdateOutputFilenames  ]
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_combineframes.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_combineframes [pxvtable::vnewobj]]
    $alg MainFunction 
}

