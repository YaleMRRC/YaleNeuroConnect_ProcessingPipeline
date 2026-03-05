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

package require bis_basepointbasedregistration 1.0
package require bis_linearpointregister 1.0
package provide bis_nonlinearpointregister 1.0

#
# register image
#



itcl::class bis_nonlinearpointregister {

    inherit bis_basepointbasedregistration

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "NonLinear RPM" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------



itcl::body bis_nonlinearpointregister::Initialize { } {

    PrintDebug "bis_nonlinearpointregister::Initialize" 

    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ smoothstart   "Starting Smoothness Value"                                      "smoothstart"    real 5.0  { 0.0 10.0}  20 }
	{ smoothend     "Final Smoothness Value"                                        "smoothend"      real 1.0  { 0.0 10.0}  21 }
	{ cpsstart      "Starting Control Point Spacing"                                         "cpsstart"       real 30.0     { 0.0 100}  22 }
	{ cpsend        "Final Control Point Spacing"                                           "cpsend"         real 15.0     { 0.0 100.0} 23 }
	{ linearmode        "Type of linear registration" "LinearMode"  { listofvalues } rigid { rigid affine similarity none } 24 }
	{ linearnumpoints   "number of points for linear part (0=default, figure out from nonlinear)" "Linear Numpoints"          int  0 { 0 10000 }    -100 }
	{ lineartstart      "linear start temparature (0=default, figure out from nonlinear)"         "Linear Init Temperature"   real 0  { 0.0 10.0 }  -101}
	{ lineartstop        "end temparature (0=default, figure out from nonlinear)"                 "Linear Stop Temperature"    real 0  { 0.0 10.0}   -102}

    }
    set scriptname bis_nonlinearpointregister

    #
    #document
    #

    set category "Registration"
    set description "computes a linear  point-based registrations."
    set description2 ""
    set backwardcompatibility "Refactored from pxmat_pointregister.tcl"
    set authors "hirohito.okuda@yale.edu,xenophon.papademetris.yale.edu"

    $this InitializeBasePointBasedRegistration
}

# -----------------------------------------------------------------------------------------
# Execute. reimplemented from DoNMIAll of pxmat_register.tcl
# ----------------------------------------------------------------------------------------

itcl::body bis_nonlinearpointregister::Execute {  } {

    set rpm [ vtkpxBSplineRPMRegistration  [ pxvtable::vnewobj ]]
    $this SetCommonPointBasedRegistrationOptions $rpm

    $rpm SetInitialControlPointSpacing  [ $OptionsArray(cpsstart) GetValue ]
    $rpm SetFinalControlPointSpacing    [ $OptionsArray(cpsend) GetValue ]
    $rpm SetInitialSmoothnessFactor     [ $OptionsArray(smoothstart) GetValue ]
    $rpm SetFinalSmoothnessFactor       [ $OptionsArray(smoothend) GetValue ]

    set currentregistration 0
    set linearmode [ $OptionsArray(linearmode) GetValue ]
    if { $linearmode != "none" } {

	set nfactor 0.5
	set tfactor 3.0
	
	if { [ $OptionsArray(linearnumpoints) GetValue ] == 0 } {
	    $OptionsArray(linearnumpoints) SetValue [ expr int($nfactor * [ $OptionsArray(numpoints) GetValue ]) ]
	}
	if { [ $OptionsArray(lineartstart) GetValue ] == 0 } {
	    $OptionsArray(lineartstart)    SetValue [ expr $tfactor * [ $OptionsArray(tstart) GetValue ] ]
	}
	if { [ $OptionsArray(lineartstop) GetValue ] == 0 } {
	    $OptionsArray(lineartstop) SetValue [ expr $nfactor * [ $OptionsArray(tstop) GetValue ] ]
	}

	set lin_alg [ [bis_linearpointregister [pxvtable::vnewobj]] GetThisPointer ]
	$lin_alg InitializeFromContainer $this
	$lin_alg SetReferenceSurface [ $this GetReferenceSurface ]
	$lin_alg SetTransformSurface [ $this GetTransformSurface ]
	$lin_alg SetInitialTransformation [ $this GetInitialTransformation ]
	$lin_alg SetOptionValue useinitial [ $OptionsArray(useinitial) GetValue ]
	$lin_alg SetOptionValue mode $linearmode
	$lin_alg SetOptionValue tstart [ $OptionsArray(lineartstart) GetValue ]
	$lin_alg SetOptionValue tstop [ $OptionsArray(lineartstop) GetValue ]
	$lin_alg SetOptionValue numpoints [ $OptionsArray(linearnumpoints) GetValue ]
	#	set currentregistration $lin_alg
	$lin_alg Execute
	$rpm SetInitialTransform [ [ $lin_alg GetOutputTransformation ] GetTransformation ]
	$rpm SetUseInitialTransform 1

	itcl::delete obj $lin_alg
    } elseif { [ $OptionsArray(useinitial) GetValue ] !=0 } {
	$rpm SetUseInitialTransform 1
	$rpm SetInitialTransform [[ $this GetInitialTransformation ] GetObject ]
    }

    set surface1    [ $this GetReferenceSurface  ]
    set surface2    [ $this GetTransformSurface ]
    
    $this SetFilterCallbacks $rpm "Non-Linear RPM Registration"
    set currentregistration $rpm
    $rpm SetSource [ $surface1 GetSurface ]
    $rpm SetTarget [ $surface2 GetSurface ]
    $rpm Run
    set currentregistration 0
    [ $this GetOutputTransformation ] CopyTransformation [ $rpm GetCurrentTransformation ]
    $rpm Delete

    $this CreateWarpedSurface

    return 1
}



# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_nonlinearpointregister.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_nonlinearpointregister [pxvtable::vnewobj]]
    $alg MainFunction 
}

