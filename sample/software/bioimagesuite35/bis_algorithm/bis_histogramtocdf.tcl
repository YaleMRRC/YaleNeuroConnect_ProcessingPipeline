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

package provide bis_histogramtocdf 1.0
package require bis_imagetoimagealgorithm 1.0


itcl::class bis_histogramtocdf {

    inherit bis_imagetoimagealgorithm

     constructor { } {	 $this Initialize  }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Histo CDF" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_histogramtocdf::Initialize { } {

    PrintDebug "bis_histogramtocdf::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ survival  "Do 1-cdf instead of cdf" "survival mode" { listofvalues radiobuttons }    0 { 0  1 }  -999 }
	{ doneg  "Flip the order of frame for neg side of the histogram" "negative mode" { listofvalues radiobuttons }    0 { 0  1 }  -999 }
    }


    set defaultsuffix { "_cdf" }
    
    set scriptname bis_histogramtocdf
    set completionstatus "Done"

    #
    #document
    #

    $this InitializeImageToImageAlgorithm
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_histogramtocdf::Execute {  } {

    set ok [ pxtclvtkpxcontrib::ConditionalLoadLibrary  vtkbisConnectivityTCL 0  ]
    if { $ok == 0 } {
	set errormessage "Failed to load library vtkbisConnectivityTCL"
	return 0
    }

    PrintDebug "bis_histogramtocdf::Execute"

    set image_in    [ $this GetInput ]

    set smooth  [ vtkbisHistogramToCDF [ pxvtable::vnewobj ]  ]
    $smooth SetInput [ $image_in GetObject ]
    $smooth Update
    $smooth SetDoSurvival    [ $OptionsArray(survival) GetValue ]
    $smooth SetDoNeg    [ $OptionsArray(doneg) GetValue ]
    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage ShallowCopyImage [ $smooth GetOutput ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]

    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0

    $smooth Delete

    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_histogramtocdf.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_histogramtocdf [pxvtable::vnewobj]]
    $alg MainFunction 
}





