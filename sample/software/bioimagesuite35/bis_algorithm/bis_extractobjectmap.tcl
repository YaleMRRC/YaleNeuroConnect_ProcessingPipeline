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
package provide bis_extractobjectmap 1.0

#
# compute curvatures of polydata
#

itcl::class bis_extractobjectmap {

    inherit bis_imagetosurfacealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Extract Objectmap" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_extractobjectmap::Initialize { } {

    PrintDebug "bis_extractobjectmap::Initialize" 
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ lowthreshold "Low Threshold" "Low Threshold"   real     1.0 { 1.0 255.0 }  0 }
	{ highthreshold "High Threshold" "High Threshold"   real    255.0 { 1.0 255.0 }  1 }
	{ smoothingxy "Smoothing XY 1-4" "Smoothing XY" { listofvalues radiobutton}  1.0 { 0.0 1.0 2.0 3.0 4.0 }   2}
	{ smoothingz "Smoothing Z 1-4" "Smoothing Z" { listofvalues radiobutton}  1.0 { 0.0 1.0 2.0 3.0 4.0 }   3}
	{ resample "Resample scale 1-4" "Resample" { listofvalues radiobutton}  2.0 { 1.0 2.0 3.0 4.0 }   4}
    }

    set defaultsuffix { "_objmap" }
    
    set scriptname bis_extractobjectmap

    #
    #document
    #
    set category "Surface Processing"
    set description  "Extract a surface from an objectmap (image)"
    set description2 ""
    set backwardcompaibitlity "Newly added."
    set authors "alark.joshi@yale.edu"

    $this InitializeImageToSurfaceAlgorithm
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_extractobjectmap::Execute {  } {

    PrintDebug "bis_extractobjectmap::Execute"

    # Get Inputs
    set image_in [ $this GetInput ]

    # GetOptions
    
    set smoothingxy [ $OptionsArray(smoothingxy) GetValue ]
    set smoothingz [ $OptionsArray(smoothingz) GetValue ]
    set resample [ $OptionsArray(resample)      GetValue ]
    set lowthreshold [ $OptionsArray(lowthreshold) GetValue ]
    set highthreshold [ $OptionsArray(highthreshold)      GetValue ]
   
    set lt [expr { int( $lowthreshold) } ]
    set ht [expr { int( $highthreshold) } ]


    set temp  [ vtkPolyData [ pxvtable::vnewobj ] ]
    set objtopoly [ vtkpxSurfaceUtil [ pxvtable::vnewobj ] ]
    $objtopoly ObjectMapToPolyData [ $image_in GetObject] $temp $lt $ht $smoothingxy $smoothingz [ expr 1.0 + $resample ] 
    
    if { $temp > 0 } {
	# Store Results in output
	[ $OutputsArray(output_surface) GetObject ] DeepCopySurface $temp
    }

    # Clean up
    $temp Delete
       
    return 1
}


# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_extractobjectmap.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_extractobjectmap [pxvtable::vnewobj]]
    $alg MainFunction 
}

