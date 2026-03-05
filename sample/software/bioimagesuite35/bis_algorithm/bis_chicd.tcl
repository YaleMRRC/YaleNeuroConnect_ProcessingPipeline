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

package provide bis_chicd 1.0
package require bis_dualimagealgorithm 1.0
package require bis_cropimage 1.0
package require bis_histogramtocdf 1.0
package require bis_connectivityfit 1.0
package require bis_ipsicontrahistogram 1.0
package require bis_normalizeicd 1.0
package require bis_imagemathoperations 1.0

itcl::class bis_chicd {

    inherit bis_dualimagealgorithm

    constructor { } {	 $this Initialize  }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "CHICD" }

    #overwrite parent method
    public method CheckInputObjects { }
    public method UpdateOutputFilenames { } 
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_chicd::Initialize { } {

    PrintDebug "bis_chicd::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ usegpu   "Perform Computation on gpu"  "Use GPU"         boolean       1     { 0 1  }                    10 } 
    	{ range      "Range of connectivity"  "range"  { listofvalues radiobuttons } Positive { Positive Negative }       0 }
    }

    set defaultsuffix { "_CHICD" }
    set category "Functional Imaging"    
    set scriptname bis_chicd
    set completionstatus "Done"
    
    #
    #document
    #
    
    set description "CHICD"
    set description2 "This is a simple CUDA based testing implementation"
    set backwardcompatibility ""
    set authors "dustin.scheinost@yale.edu"
    
    $this InitializeDualImageAlgorithm
    $this RenameInput 0 "Functional Image"
    $this RenameInput 1 "Mask Image" 102
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_chicd::Execute {  } {

    set usegpu       [ $OptionsArray(usegpu)     GetValue ]
    set range        [ $OptionsArray(range) GetValue ]

    set image_in [ $this GetInput ]
    set mask     [ $this GetInputObject second_image ] 

    set con [ bis_ipsicontrahistogram \#auto ]
    $con InitializeFromContainer 0 $this
    $con SetInput $image_in
    $con SetSecondInput $mask
    $con SetOptionValue numberofbins 201  
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
    
    #first do ipsi 
    #ipsi is the first 201 frames of histogram
    set crop [ bis_cropimage \#auto ]
    $crop InitializeFromContainer 0 $this
    $crop SetInput [ $con GetOutput ]

    if { $range == "Negative" } {
	$crop SetOptionValue startt 1 ; $crop SetOptionValue stopt 100
    } else { 
	$crop SetOptionValue startt 102 ; $crop SetOptionValue stopt 201
    }

    $crop Execute
    
    set survival [ bis_histogramtocdf \#auto ]
    $survival InitializeFromContainer 0 $this
    $survival SetInput [ $crop GetOutput ]
    
    if { $range == "Negative" } {
	$survival SetOptionValue doneg 1
    }

    $survival Execute
    
    set icd [ bis_connectivityfit \#auto ]
    $icd InitializeFromContainer 0 $this
    $icd SetInput [ $survival GetOutput ]
    $icd SetSecondInput  $mask
    $icd SetOptionValue model 2
    $icd SetOptionValue survival 1
    $icd Execute
    
    [ $icd GetOutput ] Save ${tmpname}_ipsilateral.nii.gz ; # save image
    
    set crop2 [ bis_cropimage \#auto ]
    $crop2 InitializeFromContainer 0 $this
    $crop2 SetInput [ $icd GetOutput ]
    $crop2 SetOptionValue startt 2 ; $crop2 SetOptionValue stopt 2
    $crop2 Execute
    
    [ $crop2 GetOutput ] Save ${tmpname}_ipsilateral_Alpha.nii.gz  ; # save image
    
    set norm1 [ bis_normalizeicd \#auto ]
    $norm1 InitializeFromContainer 0 $this
    $norm1 SetInput [ $crop2 GetOutput ]
    $norm1 SetSecondInput $mask
    $norm1 Execute

    [ $norm1 GetOutput ] Save ${tmpname}_ipsilateral_Alpha_norm.nii.gz

    #contralateral
    
    $crop SetInput [ $con GetOutput ]
    
    if { $range == "Negative" } {
	$crop SetOptionValue startt 202 ; $crop SetOptionValue stopt 301
    } else { 
	$crop SetOptionValue startt 303 ; $crop SetOptionValue stopt 402
    }
    $crop Execute

    $survival SetInput [ $crop GetOutput ]
    if { $range == "Negative" } {
	$survival SetOptionValue doneg 1
    }
    $survival Execute
    
    $icd SetInput [ $survival GetOutput ]
    $icd SetSecondInput  $mask
    $icd SetOptionValue model 2
    $icd SetOptionValue survival 1
    $icd Execute
    
    [ $icd GetOutput ] Save ${tmpname}_contralateral.nii.gz ; #save image
    
    $crop2 SetInput [ $icd GetOutput ]
    $crop2 SetOptionValue startt 2 ; $crop2 SetOptionValue stopt 2
    $crop2 Execute
    
    [ $crop2 GetOutput ] Save ${tmpname}_contralateral_Alpha.nii.gz ; #save image

    set norm2 [ bis_normalizeicd \#auto ]
    $norm2 InitializeFromContainer 0 $this
    $norm2 SetInput [ $crop2 GetOutput ]
    $norm2 SetSecondInput $mask
    $norm2 Execute

    [ $norm1 GetOutput ] Save ${tmpname}_contralateral_Alpha_norm.nii.gz

    set math [ bis_imagemathoperations \#auto ]
    $math InitializeFromContainer 0 $this
    $math SetOptionValue mathoperation Subtract
    $math SetInput       [ $norm1 GetOutput ]
    $math SetSecondInput [ $norm2 GetOutput ]
    $math Execute

    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage ShallowCopyImage [ [ $math GetOutput ] GetObject ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]

    itcl::delete obj $survival
    itcl::delete obj $icd
    itcl::delete obj $crop
    itcl::delete obj $crop2
    itcl::delete obj $norm1
    itcl::delete obj $norm2
    itcl::delete obj $math

    itcl::delete obj $con
    
    return 1
}


itcl::body bis_chicd::CheckInputObjects { } {

    set image_in    [ $this GetInput ]
    set d [ $image_in GetImageSize ]
    if { $d < 2 } {
	return 0
    }
	
    set image_in    [ $this GetSecondInput ]
    set d [ $image_in GetImageSize ]
    if { $d < 2 } {
	return 0
    }
    
    return 1
}


itcl::body bis_chicd::UpdateOutputFilenames { } {
    
    set defaultsuffix [ list  "_CHICD" ]
    
    return [ ::bis_imagetoimagealgorithm::UpdateOutputFilenames  ]
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_mediantemporalsmoothimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_chicd [ pxvtable::vnewobj ] ]
    $alg MainFunction 
}








