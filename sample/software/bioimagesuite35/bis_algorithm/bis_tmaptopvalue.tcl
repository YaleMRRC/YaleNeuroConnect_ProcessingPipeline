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

package require bis_imagetoimagealgorithm 1.0
package require vtkpxcontrib     1.2

package provide bis_tmaptopvalue 1.0


itcl::class bis_tmaptopvalue {

    inherit bis_imagetoimagealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "T-score to P-value" }

}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_tmaptopvalue::Initialize { } {

    PrintDebug "bis_tmaptopvalue::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
   
     set options {
	 { dof         "Degree of Freedom" "DOF"   int    1   {.0            100000000   }  0 }
	 { scaleFactor "Scale factor "     "Scale" float  1.0 { -100000000.0 100000000.0 }  -10 }
	 { autoscale   "Detect Whether t-values are scaled by 1000 or not"	  "AutoScale"   boolean	 1 { 0 1  }  6 } 
    }

    set defaultsuffix { "_pvalue" }
    
    set completionstatus "Done, tested"

    set scriptname bis_tmaptopvalue


    set description "converts tmap to pvalue."
    set description2 ""
    set backwardcompatibility "N/A"
    set authors ""
    set category "Functional Imaging"

    $this InitializeImageToImageAlgorithm

}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_tmaptopvalue::Execute {  } {

    PrintDebug "bis_tmaptopvalue::Execute"

    set dof         [ $OptionsArray(dof)          GetValue  ]
    set image_in    [ $InputsArray(input_image)   GetObject ]
    set outimage    [ $OutputsArray(output_image) GetObject ]
    set autoscale   [ $OptionsArray(autoscale)  GetValue  ]
    

    if { $autoscale == 1 } {
	set r [ lindex [ [ [ [ $image_in GetImage ] GetPointData ] GetScalars ] GetRange ] 1 ]
	if { $r > 1000.0 } {
	    puts stderr "Setting scaleFactor to 1000.0"
	    $this SetOptionValue scaleFactor 1000.0
	} else {
	    $this SetOptionValue scaleFactor 1.0
	}
    }
    set scaleFactor [ $OptionsArray(scaleFactor)  GetValue  ]

    set tm [ vtkpxComputeTmap [ pxvtable::vnewobj ] ]
    set image_out [ $tm TmapToPvalueConversion [ $image_in GetImage ] $dof $scaleFactor ]

    $outimage ShallowCopyImage $image_out 
    $outimage CopyImageHeader [ $image_in GetImageHeader ]

    set comment [ format "BIS::bis_tmaptopvalue.tcl"  ]
    [ $outimage GetImageHeader ] AddComment "[ $this GetCommandLine full ]" 0

    $tm Delete
    return 1
}


# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_tmaptopvalue.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_tmaptopvalue [pxvtable::vnewobj]]
    $alg MainFunction 
}

