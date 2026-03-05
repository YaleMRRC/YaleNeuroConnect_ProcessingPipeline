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
package provide bis_matvis_reordernodes 1.0

#
# compute curvatures of polydata
#

itcl::class bis_matvis_reordernodes {

    inherit bis_imagetosurfacealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "MatvisReoderNodes" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_matvis_reordernodes::Initialize { } {

    PrintDebug "bis_matvis_reordernodes::Initialize" 
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ sortindex1 "Index to sort nodes by -- must have left v right valence" "Index 1" int 1 { 1 4 } 0 }
	{ sortindex2 "Second Index to sort nodes by" "Index 2" int 2 { 1 4 } 0 }
    }

    set inputs { 
	{ second_image   "Atlas Image" pxitclimage  ""  1 }   
    }

    set defaultsuffix { "_reordercentroids" }
    
    set scriptname bis_matvis_reordernodes

    #
    #document
    #
    set category "Surface Processing"
    set description  "Extract and reorders the centroids of a parcellation from an objectmap (image) and an atlas (image)"
    set description2 ""
    set backwardcompaibitlity "Newly added."
    set authors "xenophon.papademetris@yale.edu"

    $this InitializeImageToSurfaceAlgorithm
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_matvis_reordernodes::Execute {  } {

    PrintDebug "bis_matvis_reordernodes::Execute"

    # Get Inputs
    set image_in [ $this GetInput ]
    set atlas_img [ $this GetInputObject second_image ]

    # GetOptions
    
    set index1 [ $OptionsArray(sortindex1) GetValue ]
    set index2 [ $OptionsArray(sortindex2) GetValue ]


    if { [ $image_in IsSameDisplaySize $atlas_img ] == 0 } {
	set errormessage "Bad Input Image Dimensions"
	return 0
    }

    set parcutil [ vtkbisParcellationVisualizationUtility New ]
    set poly [ $parcutil ComputeCentroidsAndAtlasIndices [ $image_in GetImage ] [ $atlas_img GetImage ] ]
    
    set tmp     [ $parcutil ComputeNodeOrder [ [  $poly GetPointData ] GetScalars ] 0 1 ]
    set newpoly [ $parcutil ReorderSurface  $poly $tmp ]
    $parcutil Delete

    if { $newpoly != 0 } {
	# Store Results in output
	[ $OutputsArray(output_surface) GetObject ] DeepCopySurface $newpoly
	$newpoly Delete
    }
    
    # Clean up
    $tmp Delete
       
    return 1
}


# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_matvis_reordernodes.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_matvis_reordernodes [pxvtable::vnewobj]]
    $alg MainFunction 
}

