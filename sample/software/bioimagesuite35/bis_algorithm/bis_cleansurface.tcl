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

package provide bis_cleansurface 1.0

#
# compute curvatures of polydata
#

itcl::class bis_cleansurface {

    inherit bis_surfacetosurfacealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Clean Surface" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_cleansurface::Initialize { } {

    PrintDebug "bis_cleansurface::Initialize" 
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ cleanTolerance "Specify the tolerance for the cleansurface algorithm" "Clean Tolerance"  { real triplescale 100 }    0.1 { 0.0 20.0 }  0 }
	{ cleanMethod "Pick a smoothing method: Distance Sampling or Quadric Clustering. " "Clean Method" { listofvalues radiobutton}  Distance_Sampling { Distance_Sampling Quadric_Clustering}   1}
    }

    set defaultsuffix { "_clean" }
    
    set scriptname bis_cleansurface

    #
    #document
    #
    set category "Surface Processing"
    set description  "smooths a surface "
    set description2 ""
    set backwardcompaibitlity "Newly added."
    set authors "alark.joshi@yale.edu"

    $this InitializeSurfacetoSurfaceAlgorithm
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_cleansurface::Execute {  } {

    PrintDebug "bis_cleansurface::Execute"

    # Get Inputs
    set surface    [ $this GetInput  ]
    # GetOptions
    
    set cleanTolerance [ $OptionsArray(cleanTolerance) GetValue ]
    set cleanMethod [ $OptionsArray(cleanMethod)      GetValue ]
    
    # Run Algorithm
    
    if { $cleanMethod == "Distance_Sampling"} {
	set cleanfilter [ vtkCleanPolyData [ pxvtable::vnewobj ] ]
	$cleanfilter SetInput [ $surface GetObject ]
	$cleanfilter SetToleranceIsAbsolute 1 
	$cleanfilter SetAbsoluteTolerance $cleanTolerance
	$cleanfilter Update
	
	set surface_out [$cleanfilter GetOutput ]
	[ $OutputsArray(output_surface) GetObject ] DeepCopySurface  $surface_out
	$cleanfilter Delete

    } else {
	set trianglefilter [vtkTriangleFilter [ pxvtable::vnewobj ] ]
	$trianglefilter SetInput [ $surface GetObject ]
	$trianglefilter Update
	
	set bounds [ [ $trianglefilter GetOutput] GetBounds]
	
	set clusterFilter [ vtkQuadricClustering [ pxvtable::vnewobj ] ]
	$clusterFilter SetInput [ $trianglefilter GetOutput]
	
	set b0 [ lindex $bounds 0]
	set b1 [ lindex $bounds 1]
	set b2 [ lindex $bounds 2]
	set b3 [ lindex $bounds 3]
	set b4 [ lindex $bounds 4]
	set b5 [ lindex $bounds 5]
	
	$clusterFilter SetDivisionOrigin $b0 $b2 $b4
	$clusterFilter SetDivisionSpacing $cleanTolerance $cleanTolerance $cleanTolerance 
	
	set xdiv [ expr {int (1.5 + (($b1 - $b0)/$cleanTolerance))} ]
	set ydiv [ expr {int (1.5 + (($b3 - $b2)/$cleanTolerance))} ]
	set zdiv [ expr {int (1.5 + (($b5 - $b4)/$cleanTolerance))} ]
	
#	puts stderr "xdiv=$xdiv, $ydiv, $zdiv, $bounds, [ $clusterFilter GetDivisionOrigin ], [ $clusterFilter GetDivisionSpacing]"
	
	$clusterFilter SetNumberOfXDivisions $xdiv
	$clusterFilter SetNumberOfYDivisions $ydiv
	$clusterFilter SetNumberOfZDivisions $zdiv
	$clusterFilter Update
	
	puts "Numpoints = [ [$clusterFilter GetOutput ] GetNumberOfPoints ]"

	[ $OutputsArray(output_surface) GetObject ] DeepCopySurface  [$clusterFilter GetOutput ]
	$clusterFilter Delete
	
    }
    return 1
}


# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_cleansurface.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_cleansurface [pxvtable::vnewobj]]
    $alg MainFunction 
}

