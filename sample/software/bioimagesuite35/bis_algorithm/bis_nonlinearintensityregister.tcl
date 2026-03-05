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

package provide bis_nonlinearintensityregister 1.0
package require bis_baseintensityregistration 1.0
package require bis_linearintensityregister 1.0


#
# register image
#

itcl::class bis_nonlinearintensityregister {

    inherit bis_baseintensityregistration

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "NonLinear Reg" }
    public method GetExtension { } { return ".grd" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_nonlinearintensityregister::Initialize { } {

    PrintDebug "bis_nonlinearintensityregister::Initialize" 

    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ initialmode   "Type of initial registration" "Initial Mode" { listofvalues } affine { none rigid affine similarity  } 0 }
	{ spacing       "Control Point Spacing in mm" "Control Point Spacing" { real } 15.0 { 1.0 50.0 } 1 }
	{ spacingrate   "Rate of increase of Control Point Spacing" "Cont Spacing Rate" { real } 2.0 { 1.1 3.0 } -105 }
	{ smoothness    "Smoothness factor (using bending energy regularization)" "Smoothness" { real } 0.001 { 0.0 1.0 } 2 }
	{ windowsize    "Size (in control points of the window to use for computing gradients (2.0=full,1.0=accelerated)" "Windowsize" { real } 1.0 { 1.0 2.0 } -150 }
	{ extralevels   "Number of `fluid' iterations at end of main level " "Extra Levels" { integer } 0 { 0 10 } -106 }
	{ useinitial "Use Initial Transformation" "Use Initial Xform"  boolean   0     { 0 1 } 25 }
	{ directstorage "GPU Direct Storage  " "GPU Direct Storage Mode" boolean 1 { 0 1 }  -502 }
    }
    set scriptname bis_nonlinearintensityregister

    #
    #document
    #

    set category "Registration"
    set description "computes a linear  intensity based registrations."
    set description2 ""
    set backwardcompatibility "Refactored from pxmat_register.tcl."
    set authors "hirohito.okuda@yale.edu,xenophon.papademetris.yale.edu"

    $this InitializeBaseIntensityRegistration
}

# -----------------------------------------------------------------------------------------
# Execute. reimplemented from DoNMIAll of pxmat_register.tcl
# ----------------------------------------------------------------------------------------

itcl::body bis_nonlinearintensityregister::Execute {  } {


    PrintDebug "bis_nonlinearintensityregister::Execute"
    set usegpu      [ $OptionsArray(usegpu) GetValue ]
    set threadmode [  $OptionsArray(threadmode) GetValue ]
    set directstorage [ $OptionsArray(directstorage) GetValue ]

    set nreg 0
    if { $usegpu > 0 } {
	catch { 
	    set nreg  [ vtkbisCUDANonLinearRegistration New ]; 
	    $nreg SetThreadMode $threadmode
	    $nreg SetDirectStorageMode $directstorage
	}
    }

    if { $nreg == 0 } {
	set nreg [ vtkpxNonLinearRegistration [ pxvtable::vnewobj ]]
    }

    puts stderr "Using class [ $nreg GetClassName ]"

    set initialmode [ $OptionsArray(initialmode) GetValue ]

    if { $initialmode != "none" } {
	set lin_alg [bis_linearintensityregister [pxvtable::vnewobj]]
	$lin_alg InitializeFromContainer 0
	$lin_alg SetReferenceImage [ $this GetReferenceImage ]
	$lin_alg SetTransformImage [ $this GetTransformImage ]
	if { [ $OptionsArray(useinitial) GetValue ] !=0 } {
	    $lin_alg SetOptionValue useinitial 1
	    $lin_alg SetInitialTransformation  [ $this GetInitialTransformation ] 
	}
	$lin_alg SetOptionValue mode $initialmode
	$lin_alg SetOptionValue threadmode $threadmode
	$lin_alg SetOptionValue usegpu $usegpu
	set useweights     [ $OptionsArray(useweightimage) GetValue ]
	if { $useweights > 0 } {
	    $lin_alg SetOptionValue useweightimage $useweights
	    $lin_alg SetInputObject weight_image  [ $this GetInputObject weight_image  ]
	    if { $useweights > 1 } {
		$lin_alg SetInputObject weight_image2 [ $this GetInputObject weight_image2 ]
	    }
	}
	$lin_alg Execute
	$nreg SetInitialTransform [ [ $lin_alg GetOutputTransformation ] GetTransformation ]
	itcl::delete obj $lin_alg
    } else {
	if { [ $OptionsArray(useinitial) GetValue ] !=0 } {
	    $nreg SetInitialTransform [ [ $this GetInitialTransformation ] GetTransformation ]
	}
    }


    $this SetCommonIntensityRegistrationOptions $nreg

    $nreg SetLambda [ expr 0.01 * [  $OptionsArray(smoothness) GetValue ]]
    $nreg SetControlPointSpacing [  $OptionsArray(spacing) GetValue ]
    $nreg SetControlPointSpacingRate [  $OptionsArray(spacingrate) GetValue ]
    $nreg SetWindowSize [  $OptionsArray(windowsize) GetValue ]
    $nreg SetNumberOfExtraLevels [  $OptionsArray(extralevels) GetValue ]

    $this SetFilterCallbacks $nreg "Non-Linearly Registering Image"

    set current_registration $nreg

    set tstart [ clock clicks -milliseconds ]
    $nreg Run
    set tend [ clock clicks -milliseconds ]

    puts stdout "++++++        End of non rigid registration [ expr $tend - $tstart ] ms\n"
    set current_registration 0
    [ $this GetOutputTransformation ] CopyTransformation [ $nreg GetTransformation ]

    puts stdout "Deleting\n"
    $nreg Delete
    $this CreateWarpedImage

    return 1
}




# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_nonlinearintensityregister.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_nonlinearintensityregister [pxvtable::vnewobj]]
    $alg MainFunction 
}

