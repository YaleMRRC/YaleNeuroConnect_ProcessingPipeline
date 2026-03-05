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

package require bis_landmarkstolandmarksalgorithm 1.0

package provide bis_smoothlandmarks 1.0

#
# compute curvatures of polydata
#

itcl::class bis_smoothlandmarks {

    inherit bis_landmarkstolandmarksalgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Smooth Landmarks" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_smoothlandmarks::Initialize { } {

    PrintDebug "bis_smoothlandmarks::Initialize" 
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ factor "Specify the relaxation factor for  smoothing" "Relaxation factor"  { real triplescale 100 }    0.33 { 0.0 1.0 }  1 }
    }

    set defaultsuffix { "_smooth" }
    
    set scriptname bis_smoothlandmarks

    #
    #document
    #
    set category "Landmarks Processing"
    set description  "Smoothing a curve stored as landmarks"
    set description2 ""
    set backwardcompaibitlity "Newly added."
    set authors "xenophon.papademetris@yale.edu"

    $this InitializeLandmarksToLandmarksAlgorithm
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_smoothlandmarks::Execute {  } {

    PrintDebug "bis_smoothlandmarks::Execute"

    # Get Inputs
    set landmarks    [ $this GetInput  ]
    # GetOptions
    
    set factor [ $OptionsArray(factor)      GetValue ]

    set out [ $this GetOutput ]
    [ $out GetLandmarks ] Compact

    $out CopyLandmarks [  $landmarks  GetLandmarks ]
    [ $out GetLandmarks ] Smooth $factor
    return 1
}


# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_smoothlandmarks.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_smoothlandmarks [pxvtable::vnewobj]]
    $alg MainFunction 
}

