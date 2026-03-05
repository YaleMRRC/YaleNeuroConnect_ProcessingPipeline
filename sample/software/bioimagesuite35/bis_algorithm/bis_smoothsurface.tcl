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

package provide bis_smoothsurface 1.0

#
# compute curvatures of polydata
#

itcl::class bis_smoothsurface {

    inherit bis_surfacetosurfacealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Smooth Surface" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_smoothsurface::Initialize { } {

    PrintDebug "bis_smoothsurface::Initialize" 
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ iterations "Number of iterations for smoothing" "Number of iterations"  { integer triplescale 100 }    5 { 0 200 }  0 }
	{ relaxationfactor "Specify the relaxation factor for Laplacian smoothing" "Relaxation factor"  { real triplescale 100 }    0.2 { 0.0 1.0 }  1 }
	{ smoothBoundary "Turn on/off the smoothing of vertices on the boundary of the mesh. " "Smooth Boundaries (Sinc)" { boolean }  0 { 0 1}   2}
	{ smoothMethod "Pick a smoothing method: Laplacian or Windowed Sinc. " "Smooth Method" { listofvalues radiobutton}  Laplacian { Laplacian Windowed_Sinc}   3}
    }

    set defaultsuffix { "_smooth" }
    
    set scriptname bis_smoothsurface

    #
    #document
    #
    set category "Surface Processing"
    set description  "smoothing a surface"
    set description2 ""
    set backwardcompaibitlity "Newly added."
    set authors "alark.joshi@yale.edu"

    $this InitializeSurfacetoSurfaceAlgorithm
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_smoothsurface::Execute {  } {

    PrintDebug "bis_smoothsurface::Execute"

    # Get Inputs
    set surface    [ $this GetInput  ]
    # GetOptions
    
	set iterations [ $OptionsArray(iterations) GetValue ]
	set relaxationfactor [ $OptionsArray(relaxationfactor)      GetValue ]
	set smoothBoundary     [ $OptionsArray(smoothBoundary)    GetValue ]
	set smoothMethod [ $OptionsArray(smoothMethod)    GetValue ]
	
    # Run Algorithm
    
    if { $smoothMethod == "Laplacian"} {
		set filter [ vtkSmoothPolyDataFilter [ pxvtable::vnewobj ] ]
		$filter SetInput [ $surface GetObject ]
		$filter SetNumberOfIterations $iterations
		$filter SetRelaxationFactor $relaxationfactor
		$filter Update
	} else {
		set filter [vtkWindowedSincPolyDataFilter [ pxvtable::vnewobj ] ]
		$filter SetInput [ $surface GetObject ]
		$filter SetNumberOfIterations $iterations

		if { $smoothBoundary == "1"} {
				$filter BoundarySmoothingOn  	
		} else {
				$filter BoundarySmoothingOff  	
    	}
    	$filter Update
	}
	
    
    # Store Results in output
    set surface_out [$filter GetOutput ]
    [ $OutputsArray(output_surface) GetObject ] DeepCopySurface $surface_out 

    # Clean up
    $filter Delete

    return 1
}


# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_smoothsurface.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_smoothsurface [pxvtable::vnewobj]]
    $alg MainFunction 
}

