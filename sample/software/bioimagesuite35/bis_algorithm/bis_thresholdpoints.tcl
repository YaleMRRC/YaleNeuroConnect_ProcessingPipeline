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

package require bis_imagetosurfacealgorithm 1.0                
package provide bis_thresholdpoints 1.0

#
# compute curvatures of polydata
#

itcl::class bis_thresholdpoints {

    inherit bis_imagetosurfacealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Threshold points" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_thresholdpoints::Initialize { } {

    PrintDebug "bis_thresholdpoints::Initialize" 
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
		{ thresholdMethod "Thresholding method" "Thresholding method" { listofvalues radiobutton}  Below_Lower { Below_Lower Above_Higer Between}   0}
		{ lowthreshold "Low Threshold" "Low Threshold"  { real triplescale 100 }    0.0 { 0.0 255.0 } 1 }
		{ highthreshold "High Threshold" "High Threshold"  { real triplescale 100 }    255.0 { 0.0 255.0 } 2 }
    }
	
    set defaultsuffix { "_thresholdsurface" }
    
    set scriptname bis_thresholdpoints
	
    #
    #document
    #
    set category "Surface Processing"
    set description  "Extract a surface from an image"
    set description2 ""
    set backwardcompaibitlity "Newly added."
    set authors "alark.joshi@yale.edu"

    $this InitializeImageToSurfaceAlgorithm
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_thresholdpoints::Execute {  } {

    PrintDebug "bis_thresholdpoints::Execute"

    # Get Inputs
    set image_in [ $this GetInput ]

    # GetOptions
    set thresholdMethod [ $OptionsArray(thresholdMethod) GetValue ]
    set lowthreshold [ $OptionsArray(lowthreshold) GetValue ]
    set highthreshold [ $OptionsArray(highthreshold) GetValue ]

    if { $lowthreshold > $highthreshold } { 
	    set temp $lowthreshold 
	    set lowthreshold $highthreshold
	    set highthreshold $temp
	    puts "Lower threshold was greater than High threshold. The values have been swapped"
	}
	
	set thrfilter [ vtkThresholdPoints [ pxvtable::vnewobj ] ]
	$thrfilter SetInput  [ $image_in GetObject]

	if { $thresholdMethod == "Below_Lower" } { 
			$thrfilter ThresholdByLower $lowthreshold
		} elseif { $thresholdMethod == "Above_Higher" } {
			$thrfilter ThresholdByUpper $highthreshold
		} else {
			$thrfilter ThresholdBetween $lowthreshold $highthreshold
		}

		$thrfilter Update
		
	set surface_out [$thrfilter GetOutput ]
	
    # Store Results in output
	[ $OutputsArray(output_surface) GetObject ] DeepCopySurface $surface_out 
	
    # Clean up
	$thrfilter Delete
	
	return 1
}


# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_thresholdpoints.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_thresholdpoints [pxvtable::vnewobj]]
    $alg MainFunction 
}

