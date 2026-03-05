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

package provide  bis_connectivityfit  1.0
package require bis_dualimagealgorithm 1.0

itcl::class bis_connectivityfit {

    inherit bis_dualimagealgorithm

     constructor { } {	 $this Initialize  }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Fit" }
    public method UpdateOutputFilenames { } 
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_connectivityfit::Initialize { } {

    PrintDebug " bis_connectivityfit::Initialize" 
	
    set options {
	{ model  "model choice for fitting" "model"  integers     1 { 1 4 }  -999 }
	{ flip  "Flip a distrubution from [-1,0] to [0,1] " "for Negative" { listofvalues radiobuttons }    0 { 0 1 }  -999 }
	{ survival  "do survival instead of pdf " "for modeling the survival curve" { listofvalues radiobuttons }    0 { 0 1 }  -999 }
    }

    set defaultsuffix { "_fit" }
    
    set scriptname bis_connectivityfit 
    set completionstatus "Done"
    
    #
    #document
    #
    
    $this InitializeDualImageAlgorithm

    $this RenameInput 0 "Connectivity Histogram Image"
    $this RenameInput 1 "Mask Image"
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_connectivityfit::Execute {  } {

    PrintDebug "bis_connectivityfit::Execute"
	
    set image_in [ $this GetInput ]
    set model  [ $OptionsArray(model) GetValue ]
    set flip   [ $OptionsArray(flip) GetValue ]
    set survival   [ $OptionsArray(survival) GetValue ]
		 
    puts "model = $model"

    set fit [ vtkbisConnectivityFit [ pxvtable::vnewobj ]  ] 

    $fit SetModel $model
    $fit SetDoNeg $flip
    $fit SetInput     [ $image_in GetObject ]	
    $fit SetImageMask [ [ $this GetInputObject second_image ] GetObject ]
    if { $model == 3 } {
	$fit SetNumberOfBetas 2
    } elseif { $model == 4 } {
	$fit SetNumberOfBetas 1
    } else {
	$fit SetNumberOfBetas 3
    }
    $fit SetDoCDF $survival
    $fit Update

    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage ShallowCopyImage [ $fit GetOutput ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]

    $fit Delete

    return 1
}

itcl::body bis_connectivityfit::UpdateOutputFilenames { } {

    set t0   [ $OptionsArray(model) GetValue ]
    puts "the model = $t0"
    set defaultsuffix [ list "_fit_model${t0}" ]

    return [ ::bis_imagetoimagealgorithm::UpdateOutputFilenames  ]
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_Connectivityfit.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_connectivityfit [pxvtable::vnewobj]]
    $alg MainFunction 
}



