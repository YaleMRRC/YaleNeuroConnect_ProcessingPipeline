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

package require bis_baseintensityregistration 1.0
package provide bis_linearintensityregister 1.0

#
# register image
#



itcl::class bis_linearintensityregister {

    inherit bis_baseintensityregistration

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Linear Registration" }


    # Initialize Transformation
    protected method ExtractLinearTransform {  numparam } 

}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------



itcl::body bis_linearintensityregister::Initialize { } {

    PrintDebug "bis_linearintensityregister::Initialize" 

    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ mode   "Type of linear registration" "Transformation Mode" { listofvalues } rigid { rigid affine similarity affine2d rigid2d similarity2d } 0 }
	{ useinitial "Use Initial Transformation" "Use Initial Xform"  boolean   0     { 0 1 } 25 }
	{ optscalefactor  "Scale Factor for non-translation optimization parameters"   "Opt Scale Factor"  real   1.0    { 0.001 1000.0 } -800 }
	{ autooptscalefactor "Automatic Setting for Optimization Scale Factor" "Auto Opt Scale Factor"  boolean   1     { 0 1 } -799 }
    }
    set scriptname bis_linearintensityregister

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




itcl::body bis_linearintensityregister::ExtractLinearTransform {  numparam } {

    set image_ref    [ $this GetReferenceImage  ]
    set image_trn    [ $this GetTransformImage ]
    set in_xform     [ [ $this GetInitialTransformation ] GetObject ]
    
    set xform [ vtkpxLinearTransform [ pxvtable::vnewobj ]]
    $xform ExtractParameters $in_xform 9 [ $image_ref GetImage ] [ $image_ref GetOrientation ] [  $image_trn GetImage ] [ $image_trn GetOrientation ]
    for { set k $numparam } { $k < 15 } { incr k } {
	$xform Put $k 0
    }
    return $xform
}





itcl::body bis_linearintensityregister::Execute {  } {


    PrintDebug "bis_linearintensityregister::Execute"

    set numparam 6

    set usegpu      [ $OptionsArray(usegpu) GetValue ]
    set threadmode [  $OptionsArray(threadmode) GetValue ]

    puts stdout "GPU = $usegpu"
    set areg 0
    if { $usegpu > 0 } {
	catch { 

	    set areg  [ vtkbisCUDALinearRegistration New ]; 
	    $areg SetThreadMode $threadmode
	}
    }

    if { $areg == 0 } {
	set areg [ vtkpxLinearRegistration [ pxvtable::vnewobj ]]
    }

    set mode [ $OptionsArray(mode) GetValue ]
    #    puts stderr "Mode=$mode"

    switch -exact $mode { 
	"rigid"  { 	$areg SetTransformModeToRigid;   }
	"affine"  { 	$areg SetTransformModeToAffine; set numparam 9  }
	"similarity"  { 	$areg SetTransformModeToSimilarity; set numparam 9  }
	"rigid2d"  { 	$areg SetTransformModeToRigid2D }
	"affine2d"  { 	$areg SetTransformModeToAffine2D  }
	"similarity2d"  { 	$areg SetTransformModeToSimilarity2D  }
    }

    if { [ $OptionsArray(useinitial) GetValue ] !=0 } {
	set xform [ ExtractLinearTransform $numparam ]
	$areg SetInitialTransform $xform
	$xform Delete
    }
    $this SetCommonIntensityRegistrationOptions $areg

    $areg SetOptimizationAutoScale [ expr int( [ $OptionsArray(autooptscalefactor) GetValue ] ) ]
    $areg SetOptimizationScaleFactor [ $OptionsArray(optscalefactor) GetValue ]

    $this SetFilterCallbacks $areg "Linearly Registering Image"

    set current_registration $areg

    puts stderr " Running [ $areg GetClassName ]"

    $areg Run
    set current_registration 0
    [ $this GetOutputTransformation ] CopyTransformation [ $areg GetTransformation ]

    $areg Delete

    $this CreateWarpedImage

    return 1
}



# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_linearintensityregister.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_linearintensityregister [pxvtable::vnewobj]]
    $alg MainFunction 
}

