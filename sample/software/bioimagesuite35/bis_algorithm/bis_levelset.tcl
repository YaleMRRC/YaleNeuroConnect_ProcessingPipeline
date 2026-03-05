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

package provide bis_levelset 1.0
package require bis_baselevelset 1.0


#
# strip skull
#

itcl::class bis_levelset {

    inherit bis_baselevelset

     constructor { } {	 $this Initialize  }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Tissue Levelset" }

}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_levelset::Initialize { } {

    PrintDebug "bis_levelset::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ insidemean "Inside Mean Intensity" "Inside Mean" real 100 { -100000 100000 } 6 }
	{ outsidemean "Outside Mean Intensity" "Outside Mean" real 20 { -100000 100000 } 8 }
	{ insidesigma "Inside Standard Deviation of Intensity" "Inside Sigma" real 10 { -100000 100000 } 7 }
	{ outsidesigma "Outside Standard Deviation Intensity" "Outside Sigma" real 10 { -100000 100000 } 9 }
	{ biexponential "Outside Distribution is BiExponential" "Biexponential" boolean 0 { 0 1 } { -10 } }
	{ outsidemean2 "Outside Mean Intensity 2" "Outside Mean 2" real 50 { -100000 100000 } -11 }
	{ outsidesigma2 "Outside Standard Deviation Intensity 2" "Outside Sigma 2" real 100 { -100000 100000 } -12 }
	{ dynamicupdate "Dynamic Parameter Update" "Update Parameters" boolean 0 { 0 1 } { 10 } }
	{ approximatevolume "Volume to constrain levelset to" "Approximate Volume" real 1000 { 0 100000 } -14 }
	{ volumeweight "Volume constraint weight" "Volume Weight" real 0.0 { 0.0 100.0 } -15 }
    }
    lappend options [ list beginlevel "Starting Resolution Level (x native)" "Begin Level"  integer 2 { 1 4  }  20 ]
    lappend options [ list endlevel   "Final Resolution Level (x native)" "Final Level"  integer 2 { 1 4  }  21 ]

	
    set defaultsuffix { "_levelset" }

    set scriptname bis_levelset
    set completionstatus "To be tested"

    #
    #document
    #
    
    set description "Performs levelset segmentation using the  levelset method of Chan and Vesse with bi-exponential output extensions"
    set description2 ""
    set backwardcompatibility "None"
    set authors "xenios.papademetris@yale.edu"

    $this InitializeBaseLevelset
}


# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------


itcl::body bis_levelset::Execute {  } {

    PrintDebug "bis_levelset::Execute"
    set filter [ vtkpxTissueLevelSetFilter New]

    $this SetLevelsetParameters $filter

    $filter SetInsideMean [ $OptionsArray(insidemean) GetValue ]
    $filter SetInsideSigma [ $OptionsArray(insidesigma) GetValue ]
    $filter SetOutsideMean [ $OptionsArray(outsidemean) GetValue ]
    $filter SetOutsideSigma [ $OptionsArray(outsidesigma) GetValue ]
    $filter SetOutside2Mean [ $OptionsArray(outsidemean2) GetValue ]
    $filter SetOutside2Sigma [ $OptionsArray(outsidesigma2) GetValue ]
    $filter SetDynamicParameterUpdate [ $OptionsArray(dynamicupdate) GetValue ]
    $filter SetBiExponentialOutside [ $OptionsArray(biexponential) GetValue ]
    $filter SetApproximateVolume [ $OptionsArray(approximatevolume) GetValue ]
    $filter SetVolumeWeight      [ $OptionsArray(volumeweight) GetValue ]
    $filter SetBeginLevel [ $OptionsArray(beginlevel) GetValue ]
    $filter SetEndLevel [ $OptionsArray(endlevel) GetValue ]

    $this SetFilterCallbacks $filter " Levelset"
    set levelset $filter
    $filter Update

    set image_in      [ $this GetInput ]
    set comment [ format " [ $this GetCommandLine full ]" ]

    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]
    $outimage ShallowCopyImage [ $filter GetOutput ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0



    # Clean up
    $filter Delete

    
#    if { $has_surface_actors !=0 } {
#	set ortho [ $this GetViewer ]
#	for { set i 0 } { $i <=3 } { incr i } {
#	    [ [ $ortho GetRenderer $i ] GetRenderer ] RemoveActor $surf_actor($i)
#	    $surf_actor($i) Delete
#	}
#	set has_surface_actors 0
#    }

    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_levelset.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_levelset [pxvtable::vnewobj]]
    $alg MainFunction 
}





