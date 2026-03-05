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

package provide bis_regularizeobjectmap 1.0
package require bis_imagetoimagealgorithm 1.0


itcl::class bis_regularizeobjectmap {

    inherit bis_imagetoimagealgorithm

     constructor { } {	 $this Initialize  }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Regularize Objectmap" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_regularizeobjectmap::Initialize { } {

    PrintDebug "bis_regularizeobjectmap::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ lambda "Relaxation factor for smoothing the objectmap" "Smoothness Factor:"   real  2.0 { 0.5 50.0 }  0 }
	{ epsilon  "Convergence factor as % of voxels changed " "Convergence" real 0.2 { 0.01 2.0 } 1 }
	{ maxobjects  "Maximum number of labels in objectmap  " "Max Labels" integer 128 { 2 512 } -10 }
	{ maxiter  "Maximum number of iterations  " "Max Iterations" integer 25 { 1 512 } -11 }
    }

    set defaultsuffix { "_reg" }
    
    set scriptname bis_regularizeobjectmap
    set completionstatus "Done"

    #
    #document
    #
    
    set description "Regularizes an objectmap (an image where each value represents an object) to smooth manual segmentations"
    set description2 ""
    set backwardcompatibility ""

    $this InitializeImageToImageAlgorithm
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_regularizeobjectmap::Execute {  } {

    PrintDebug "bis_regularizeobjectmap::Execute"

    set lambda   [ $OptionsArray(lambda) GetValue ]
    set epsilon   [ $OptionsArray(epsilon) GetValue ]
    set maxobjects   [ $OptionsArray(maxobjects) GetValue ]
    set maxiter   [ $OptionsArray(maxiter) GetValue ]
    set image_in    [ $this GetInput ]

    set r [ [ [ [  $image_in GetImage ] GetPointData ] GetScalars ] GetRange ]
    
    set rmin [ lindex $r 0 ]
    set rmax [ lindex $r 1 ]
    if {  ( ($rmax-$rmin)> $maxobjects ) } {
	set errormessage "The input image has too big a range ($r) for this algorithm to be useful. If you really know what you are doing set the maxobjects parameter to a value greater than [ expr $rmax-$min ]"
	return 0
    }

    set segm [ vtkbisObjectmapRegularization New ] 
    $segm SetInput [ $image_in GetImage ] 
    $segm SetSmoothness $lambda
    $segm SetConvergencePercentage $epsilon
    $segm SetNumberOfIterations $maxiter
    $this SetFilterCallbacks $segm "Objectmap Regularization"
    $segm Update

    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage ShallowCopyImage [ $segm GetOutput ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]

    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0

    $segm Delete

    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_regularizeobjectmap.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_regularizeobjectmap [pxvtable::vnewobj]]
    $alg MainFunction 
}





