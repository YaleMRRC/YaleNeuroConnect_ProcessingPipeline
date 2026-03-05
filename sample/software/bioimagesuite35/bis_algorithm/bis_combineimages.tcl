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

package provide bis_combineimages 1.0
package require bis_imagelisttoimagealgorithm 1.0

itcl::class bis_combineimages {

    inherit bis_imagelisttoimagealgorithm

     constructor { } {	 $this Initialize  }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Combine Set of Images" }
    public method UpdateOutputFilenames { } 
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_combineimages::Initialize { } {

    PrintDebug "bis_combineimages::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ mode "Method to combinie images" "mode" listofvalues Mean { Mean Sum Max Min Median } 1 }
    }

    set defaultsuffix { "mean" }
    
    set scriptname bis_combineimages
    set completionstatus "Done"

    #
    #document
    #
    set category "Image Processing Multiple"
    set description "Takes in a set of 3d images and creates a 3d mean, maximum, sum or minimum"
    set description2 ""
    set backwardcompatibility "Reimplemented from pxaverageimages.tcl, with extra features."

    $this InitializeImageListToImageAlgorithm
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_combineimages::Execute {  } {

    set inplist [ $InputsArray($directinputs) GetAllObjects ]
    set numfiles [ llength $inplist ]
    
    if { $numfiles < 2 } {
	set errormessage "Nothing do less than 2 inputs specified"
	return 0
    }

    set md [ $OptionsArray(mode) GetValue ]
    if { $md == "Min" || $md == "Max" } {
	set filt [ vtkpxMaximumImages New ]
    } else {
	set filt [ vtkpxAverageImages New ]
    }

    for { set i 0 } { $i < $numfiles } { incr i } {
	$filt AddInput [ [ lindex $inplist $i ] GetImage ]
    }

    if { $md == "Min" || $md == "Max" } {
	if { $md == "Min" } {
	    $filt SetDoMinimum 1
	} else {
	    $filt SetDoMinimum 0
	}
    } else {
	$filt SetMedian 0
	$filt SetSumOnly 0
	if { $md == "Median" } {
	    $filt SetMedian 1
	} elseif { $md == "Sum" } {
	    $filt SetSumOnly 1
	} 
    }
    $this SetFilterCallbacks $filt "Computing $md Image"
    $filt Update

    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage ShallowCopyImage [ $filt GetOutput ]
    $filt Delete

    $outimage CopyImageHeader [ [ lindex $inplist 0 ] GetImageHeader ]
    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment" 0
    return 1
}

# ----------------------------------------------------------------------

itcl::body bis_combineimages::UpdateOutputFilenames { } { 

    set md [ $OptionsArray(mode) GetValue ]

    if { $md == "Max" } {
	set defaultsuffix { "_max" }
    } elseif { $md == "Sum" } {
	set defaultsuffix { "_sum" }
    }  elseif { $md == "Min" } {
	set defaultsuffix { "_min" }
    }  elseif { $md == "Median" } {
	set defaultsuffix { "_median" }
    } else {
	set defaultsuffix { "_mean" }
    }

    return [ ::bis_imagelisttoimagealgorithm::UpdateOutputFilenames  ]
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_combineimages.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_combineimages [pxvtable::vnewobj]]
    $alg MainFunction 
}

