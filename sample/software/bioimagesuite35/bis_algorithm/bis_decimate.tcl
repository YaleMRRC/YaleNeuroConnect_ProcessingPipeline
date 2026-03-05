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

package provide bis_decimate 1.0

#
# compute curvatures of polydata
#

itcl::class bis_decimate {

    inherit bis_surfacetosurfacealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Decimate" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_decimate::Initialize { } {

    PrintDebug "bis_decimate::Initialize" 
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ decimatefactor "Specify the desired reduction in the total number of polygons." "Decimate factor"  { real triplescale 100 }    0.2 { 0.0 1.0 }  0 }
	{ preserveTopology "Turn on/off whether to preserve the topology of the original mesh. If on, mesh splitting and hole elimination will not occur. This may limit the maximum reduction that may be achieved." "Preserve Topology" { listofvalues radiobutton}  On { On Off}   1}
    }

    set defaultsuffix { "_decimate" }
    
    set scriptname bis_decimate

    #
    #document
    #
    set category "Surface Processing"
    set description  "decimate a surface"
    set description2 "takes in a surface and returns a surface with less points"
    set backwardcompaibitlity "Newly added."
    set authors "alark.joshi@yale.edu"

    $this InitializeSurfacetoSurfaceAlgorithm
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_decimate::Execute {  } {

    PrintDebug "bis_decimate::Execute"

    # Get Inputs
    set surface    [ $this GetInput  ]
    # GetOptions
    
    set decimatefactor [ $OptionsArray(decimatefactor)      GetValue ]
    set preserveTopology [ $OptionsArray(preserveTopology)    GetValue ]
    
	
    # Run Algorithm
    set triangleFilter [ vtkTriangleFilter [ pxvtable::vnewobj ] ]
    $triangleFilter SetInput [ $surface GetObject ]
	
    set decimateFilter [vtkDecimatePro  [ pxvtable::vnewobj ] ]
    $decimateFilter SetInput [$triangleFilter GetOutput]
    $decimateFilter SetTargetReduction $decimatefactor
    
    if { $preserveTopology == "On"} {
	$decimateFilter PreserveTopologyOn
    } else { 
	$decimateFilter PreserveTopologyOff
    }
    
    #$triangleFilter Update
    $decimateFilter Update
    
    # Store Results in output
    set surface_out [$decimateFilter GetOutput ]
    [ $OutputsArray(output_surface) GetObject ] DeepCopySurface $surface_out 

    # Clean up
    $triangleFilter Delete
    $decimateFilter Delete

    return 1
}


# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_decimate.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_decimate [pxvtable::vnewobj]]
    $alg MainFunction 
}

