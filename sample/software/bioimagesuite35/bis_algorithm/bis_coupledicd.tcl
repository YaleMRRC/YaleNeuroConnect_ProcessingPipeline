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

package provide bis_coupledicd 1.0
package require bis_dualimagealgorithm 1.0
package require bis_cropimage 1.0
package require bis_histogramtocdf 1.0
package require bis_connectivityfit 1.0
package require bis_pairedconnectivityhistogram 1.0

itcl::class bis_coupledicd {

    inherit bis_dualimagealgorithm

    constructor { } {	 $this Initialize  }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "COUPLEDICD" }

    #overwrite parent method
    public method UpdateOutputFilenames { } 	
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_coupledicd::Initialize { } {

    PrintDebug "bis_coupledicd::Initialize" 

    set inputs { 
    	{ third_image "ROI Image" pxitclimage "" 103 }     
    }
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ usemask   "Use Mask"  "Use Mask"         boolean                       0     { 0 1  }                    20 } 
	{ usegpu   "Perform Computation on gpu"  "Use GPU"         boolean       1     { 0 1  }                    10 } 
	{ dofisher   "Perform Fisher Transform before subtracting correlations"  "Fisher"         boolean       1     { 0 1  }                    10 } 
    	{ range      "Range of connectivity"  "range"  { listofvalues radiobuttons } Positive { Positive Negative Abs }       0 }
    }

    set defaultsuffix { "_COUPLEDICD" }
    set category "Functional Imaging"    
    set scriptname bis_coupledicd
    set completionstatus "Done"
    
    #
    #document
    #
    
    set description "COUPLEDICD"
    set description2 "This is a simple CUDA based testing implementation"
    set backwardcompatibility ""
    set authors "dustin.scheinost@yale.edu"
    
    $this InitializeDualImageAlgorithm
    $this RenameInput 0 "Functional Image"
    $this RenameInput 1 "2nd Functional Image"
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_coupledicd::Execute {  } {
    
    set usegpu   [ $OptionsArray(usegpu)     GetValue ]
    set msk      [ $OptionsArray(usemask)    GetValue ] ; 
    set dofisher [ $OptionsArray(dofisher)    GetValue ] ; 
    set range    [ $OptionsArray(range) GetValue ]
    
    set image_in  [ $this GetInput ]
    set image_in2 [ $this GetInputObject second_image ] 
    set mask      [ $this GetInputObject third_image ] 

    set con [ bis_pairedconnectivityhistogram \#auto ]
    $con InitializeFromContainer 0 $this
    $con SetInput $image_in
    $con SetSecondInput $image_in2
    $con SetInputObject third_image $mask
    $con SetOptionValue usemask $msk
    $con SetOptionValue numberofbins 401
    $con SetOptionValue usegpu $usegpu

    if { $range == "Abs" } {
	$con SetOptionValue useabs 1
    } else { 
	$con SetOptionValue useabs 0
    }

    $con Execute
    
    $this UpdateOutputFilenames
    set tmpname [ $OutputsArray(output_image) GetFileName ] 
    if { [ file extension $tmpname ] == ".gz" } {
	set tmpname [ file rootname [ file rootname [ $OutputsArray(output_image) GetFileName ] ] ]
    } else {
	set tmpname [ file rootname [ $OutputsArray(output_image) GetFileName ] ]
    }

    set outname2 ${tmpname}_histogram.nii.gz 
    [ $con GetOutput ] Save $outname2 ; # save image
    
    set crop [ bis_cropimage \#auto ]
    $crop InitializeFromContainer 0 $this
    $crop SetInput [ $con GetOutput ]

    if { $range == "Negative" } {
	$crop SetOptionValue startt 1 
	$crop SetOptionValue stopt 200
    } else { 
	$crop SetOptionValue startt 202
	$crop SetOptionValue stopt 401
    }

    $crop Execute
    
    set survival [ bis_histogramtocdf \#auto ]
    $survival InitializeFromContainer 0 $this
    $survival SetInput [ $crop GetOutput ]
    
    if { $range == "Negative" } {
	$survival SetOptionValue doneg 1
    }
    
    $survival Execute
    
    set coupledicd [ bis_connectivityfit \#auto ]
    $coupledicd InitializeFromContainer 0 $this
    $coupledicd SetInput [ $survival GetOutput ]
    $coupledicd SetSecondInput $mask
    $coupledicd SetOptionValue model 2
    $coupledicd SetOptionValue survival 1
    $coupledicd Execute
        
    set crop2 [ bis_cropimage \#auto ]
    $crop2 InitializeFromContainer 0 $this
    $crop2 SetInput [ $coupledicd GetOutput ]
    $crop2 SetOptionValue startt 2 ; $crop2 SetOptionValue stopt 2
    $crop2 Execute
    
    set outname3 ${tmpname}_Alpha.nii.gz 
    [ $crop2 GetOutput ] Save $outname3 ; #save image
   
    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage ShallowCopyImage [ [ $coupledicd GetOutput ] GetObject ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]
 
    itcl::delete obj $survival
    itcl::delete obj $coupledicd
    itcl::delete obj $crop
    itcl::delete obj $crop2
    
    itcl::delete obj $con
    
    return 1
}

itcl::body bis_coupledicd::UpdateOutputFilenames { } {
    
    set range [ $OptionsArray(range) GetValue ]

    set defaultsuffix [ list  "_COUPLEDICD_${range}" ]
    
    return [ ::bis_imagetoimagealgorithm::UpdateOutputFilenames  ]
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_mediantemporalsmoothimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_coupledicd [ pxvtable::vnewobj ] ]
    $alg MainFunction 
}








