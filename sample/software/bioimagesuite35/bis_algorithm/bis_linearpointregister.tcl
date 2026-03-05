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
package provide bis_linearpointregister 1.0
#
# register image
#



itcl::class bis_linearpointregister {

    inherit bis_basepointbasedregistration

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Linear RPM" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------



itcl::body bis_linearpointregister::Initialize { } {

    PrintDebug "bis_linearpointregister::Initialize" 

    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ mode   "Type of linear registration" "Transformation Mode" { listofvalues } affine { rigid affine similarity } 0 }
    }
    set scriptname bis_linearpointregister

    #
    #document
    #

    set category "Registration"
    set description "computes a linear point based registrations."
    set description2 ""
    set backwardcompatibility "Refactored from pxmat_pointregister.tcl"
    set authors "hirohito.okuda@yale.edu,xenophon.papademetris.yale.edu"

    $this InitializeBasePointBasedRegistration
}

# -----------------------------------------------------------------------------------------
# Execute. reimplemented from DoNMIAll of pxmat_register.tcl
# ----------------------------------------------------------------------------------------

itcl::body bis_linearpointregister::Execute {  } {
    set rpm [ vtkpxLinearRPMRegistration [ pxvtable::vnewobj ]]

    set mode [ $OptionsArray(mode) GetValue ]
    $rpm SetTransformModeToAffine 

    if { $mode == "rigid" } {
	$rpm SetTransformModeToRigid   
    } elseif { $mode == "similarity" } {
	$rpm SetTransformModeToSimilarity 
    }

    $this SetCommonPointBasedRegistrationOptions $rpm

    if { [ $OptionsArray(useinitial) GetValue ] !=0 } {
	set in_xform     [ [ $this GetInitialTransformation ] GetObject ]
        $rpm UseInitialTransformOn
	$rpm SetInitialTransform   $in_xform
    }

    set surface1    [ $this GetReferenceSurface  ]
    set surface2    [ $this GetTransformSurface ]
    
    puts stderr "This far"
    puts stderr "Inputs = [ $surface1  GetDescription ], [ $surface2 GetDescription ]"


    $this SetFilterCallbacks $rpm "Linear RPM Registration"
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
#  This checks if executable is called (in this case bis_linearpointregister.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_linearpointregister [pxvtable::vnewobj]]
    $alg MainFunction 
}

