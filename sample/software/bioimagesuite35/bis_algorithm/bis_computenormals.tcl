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

package require bis_surfacetosurfacealgorithm 1.0

package provide bis_computenormals 1.0

#
# compute curvatures of polydata
#

itcl::class bis_computenormals {

    inherit bis_surfacetosurfacealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Compute Normals" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_computenormals::Initialize { } {

    PrintDebug "bis_computenormals::Initialize" 
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ featureangle "Feature angle between 0 to 180 degrees" "Feature angle"  { real triplescale 100 }    90.0 { 0.0 180.0 }  0 }
	{ edgesplit      "Edge Splitting" "Edge Splitting" { boolean}  0 { 0 1 }   1}
	{ flipnormals "Flip normals" "Flip normals" { boolean}  0  {0 1}   2}
    }

    set defaultsuffix { "_normals" }
    
    set scriptname bis_computenormals

    #
    #document
    #
    set category "Surface Processing"
    set description  "computes normals of a surface"
    set description2 ""
    set backwardcompaibitlity "Newly added."
    set authors "alark.joshi@yale.edu"

    $this InitializeSurfacetoSurfaceAlgorithm
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_computenormals::Execute {  } {

    PrintDebug "bis_computenormals::Execute"

    # Get Inputs
    set surface    [ $this GetInput  ]
    # GetOptions
    
	set featureangle 	[ $OptionsArray(featureangle) GetValue ]
	set edgesplit    	[ $OptionsArray(edgesplit)      GetValue ]
	set flipnormals     [ $OptionsArray(flipnormals)    GetValue ]
	
    # Run Algorithm
    set filter [ vtkPolyDataNormals [ pxvtable::vnewobj ] ]
    $filter SetInput [ $surface GetObject ]
    $filter SetFeatureAngle $featureangle
    if { $edgesplit == "1"} {
    	$filter SplittingOn
    } else {
    	$filter SplittingOff
    }
    
    if { $flipnormals == "1"} {
		$filter FlipNormalsOn
	} else {
		$filter FlipNormalsOff
    }

	$filter Update
    
    # Store Results in output
    set surface_out [$filter GetOutput ]
    [ $OutputsArray(output_surface) GetObject ] DeepCopySurface $surface_out 

    # Clean up
    $filter Delete

    return 1
}


# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_computenormals.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_computenormals [pxvtable::vnewobj]]
    $alg MainFunction 
}

