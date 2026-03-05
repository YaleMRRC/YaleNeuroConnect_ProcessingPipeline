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

package provide bis_integratedintensityregister 1.0
package require bis_baseintensityregistration 1.0
package require bis_linearintensityregister 1.0


#
# register image
#

itcl::class bis_integratedintensityregister {

    inherit bis_baseintensityregistration

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Integrated Reg" }
    public method GetExtension { } { return ".grd" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_integratedintensityregister::Initialize { } {

    PrintDebug "bis_integratedintensityregister::Initialize" 

    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ spacing       "Control Point Spacing in mm" "Control Point Spacing" { real } 15.0 { 1.0 50.0 } 1 }
	{ spacingrate   "Rate of increase of Control Point Spacing" "Cont Spacing Rate" { real } 2.0 { 1.1 3.0 } -105 }
	{ smoothness    "Smoothness factor (using bending energy regularization)" "Smoothness" { real } 0.001 { 0.0 1.0 } 2 }
	{ windowsize    "Size (in control points of the window to use for computing gradients (2.0=full,1.0=accelerated)" "Windowsize" { real } 1.0 { 1.0 2.0 } -150 }
	{ extralevels   "Number of `fluid' iterations at end of main level " "Extra Levels" { integer } 0 { 0 10 } -106 }
	{ matchmode   "Match Mode either RPM or ICP" "Match Mode" { listofvalues } rpm { rpm icp } 20 }
	{ numpoints     "Number of points" "Numpoints (RPM)" int 4000 { 0 10000 }    21 }
	{ temperature "Temparature " "Temperature"  real 1.0  { 0.0 100.0 } 22 }
	{ fixedcorrespondences "Fixed Correspondences -- i.e. do not update as we register" "Fixed Corr (RPM)"  boolean  1 { 0 1 }  -200 }
	{ pointsweight "Relative Weight of Point Correspondences" "Points Weight" real 1.0 { 0.0 10.0 } 9 }
    }

    set tmp $inputs
    set inputs { 
	{ reference_surface   "Reference Surface" pxitclsurface  ""  22}    
	{ transform_surface   "Transform Surface" pxitclsurface  ""  23}     
    }
    for { set i 0 } { $i < [ llength $tmp ] } { incr i } {
	lappend inputs [ lindex $tmp $i ]
    }


    set scriptname bis_integratedintensityregister

    #
    #document
    #

    set category "Registration"
    set description "computes a combined nonlinear intensity+rpm registrations (Papademetris MICCAI 2004)."
    set description2 ""
    set backwardcompatibility "Refactored from pxmat_register.tcl."
    set authors "hirohito.okuda@yale.edu,xenophon.papademetris.yale.edu"

    $this InitializeBaseIntensityRegistration

    $this RenameInput 2 "RPM Transformation" 20

}

# -----------------------------------------------------------------------------------------
# Execute. reimplemented from DoNMIAll of pxmat_register.tcl
# ----------------------------------------------------------------------------------------

itcl::body bis_integratedintensityregister::Execute {  } {


    PrintDebug "bis_integratedintensityregister::Execute"
    set usegpu      [ $OptionsArray(usegpu) GetValue ]
    set threadmode [  $OptionsArray(threadmode) GetValue ]

    set nreg [ vtkpxNonLinearIntegratedRegistration [ pxvtable::vnewobj ]]
    puts stderr "Using class [ $nreg GetClassName ]"
    $nreg SetInitialTransform [ [ $this GetInitialTransformation ] GetTransformation ]
    $this SetCommonIntensityRegistrationOptions $nreg
    $nreg SetLambda [ expr 0.01 * [  $OptionsArray(smoothness) GetValue ]]
    $nreg SetControlPointSpacing [  $OptionsArray(spacing) GetValue ]
    $nreg SetControlPointSpacingRate [  $OptionsArray(spacingrate) GetValue ]
    $nreg SetWindowSize [  $OptionsArray(windowsize) GetValue ]
    $nreg SetNumberOfExtraLevels [  $OptionsArray(extralevels) GetValue ]

    $nreg SetFixedCorrespondences [ $OptionsArray(fixedcorrespondences) GetValue ]
    $nreg SetPointsWeight [ expr 0.1* [ $OptionsArray(pointsweight) GetValue ] ]


    set rpm [ $nreg GetRPMEstimator ]
    $rpm SetSource [   [ $this GetInputObject reference_surface ] GetSurface ]
    $rpm SetTarget [  [ $this GetInputObject transform_surface ] GetSurface ]
    $rpm SetMaximumNumberOfLandmarks [ $OptionsArray(numpoints) GetValue ]
    $rpm SetExtraDebug 1
    $rpm SetMatchModeToRPMFast
    if { [ $OptionsArray(matchmode) GetValue ] == "icp" } { 
	$rpm SetMatchModeToICP
    }
    $rpm SetUseLabels 1
    $rpm SetFastThreshold 3.0
    $rpm SetEnableFeedback 1
    $rpm SetTemperature [ $OptionsArray(temperature) GetValue ]

    $this SetFilterCallbacks $nreg "Non-Linearly Registering Image+Points"

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
#  This checks if executable is called (in this case bis_integratedintensityregister.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_integratedintensityregister [pxvtable::vnewobj]]
    $alg MainFunction 
}

