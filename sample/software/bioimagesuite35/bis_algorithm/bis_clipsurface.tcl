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

package provide bis_clipsurface 1.0
package require bis_imageandsurfacetosurfacealgorithm 1.0



itcl::class bis_clipsurface {

    inherit bis_imageandsurfacetosurfacealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Clip Surface" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_clipsurface::Initialize { } {

    PrintDebug "bis_clipsurface::Initialize" 

     #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
		{ lowthreshold "Low Threshold" "Low Threshold"  { real triplescale 100 }    0.0 { 0.0 1096.0 }  0 }
		{ highthreshold "High Threshold" "High Threshold"  { real triplescale 100 }    255.0 { 0.0 1096.0 }  1 }
    }
	
    set defaultsuffix { "_clipsurface" }
    
    set scriptname bis_clipsurface

    #
    #document
    #
    set category "Surface Processing"
    set description  "Clip polygonal data with user-specified implicit function or input scalar data"
    set description2 ""
    set backwardcompatibility "Newly added."
    set authors "alark.joshi@yale.edu"



    $this InitializeImageandSurfacetoSurfaceAlgorithm 

}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_clipsurface::Execute {  } {

    PrintDebug "bis_clipsurface::Execute"

    # Get Inputs
    set surface    [ $this GetInputSurface  ]
    # GetOptions
    set lowthreshold [ $OptionsArray(lowthreshold) GetValue ]
    set highthreshold [ $OptionsArray(highthreshold) GetValue ]

    set image_in [ $this GetInputImage ] 
    
   # Run Algorithm    
    set thrfilter [ vtkImageThreshold [ pxvtable::vnewobj ] ]
    $thrfilter SetInput [ $image_in GetImage ]
	$thrfilter ThresholdBetween $lowthreshold  $highthreshold 
    $thrfilter SetOutValue 0.0
    $thrfilter SetInValue 1.0
    $thrfilter ReplaceInOn
    $thrfilter ReplaceOutOn
    $thrfilter Update 

    set vol [ vtkImplicitVolume [ pxvtable::vnewobj ] ]
    $vol SetVolume [ $thrfilter GetOutput ]
    $vol SetOutValue 0.0

    set clipfilter [ vtkClipPolyData [ pxvtable::vnewobj ] ]
    $clipfilter SetInput  [ $surface GetObject ]
    $clipfilter SetClipFunction $vol
    $clipfilter GenerateClipScalarsOff
    $clipfilter SetValue 0.5
    $clipfilter Update
	
    # Store Results in output
    set surface_out [$clipfilter GetOutput ]
    [ $OutputsArray(output_surface) GetObject ] DeepCopySurface $surface_out 

    # Clean up
    $thrfilter Delete
    $clipfilter Delete

    return 1
}


# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_clipsurface.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_clipsurface [pxvtable::vnewobj]]
    $alg MainFunction 
}

