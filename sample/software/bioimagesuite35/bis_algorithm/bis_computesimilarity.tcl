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

package require bis_dualimagetransformationalgorithm 1.0
package provide bis_computesimilarity 1.0

#
# compute similarity
#

itcl::class bis_computesimilarity {

    inherit bis_dualimagetransformationalgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Compute Similarity" }
    public method UpdateContainerWithOutput { } { }
    
    #
    #protected
    #
    protected method ComputeImageSimilarity { }
    protected method ComputeSurfaceSimilarity { }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_computesimilarity::Initialize { } {

    PrintDebug "bis_computesimilarity::Initialize" 
    set inputs { 
	{ reference_surface   "Reference Surface"  pxitclsurface  ""  103 }
	{ target_surface      "Target Surface "    pxitclsurface  ""  104 }
    }

    set options {
	{ temperature    "Surface Matching: temperature. Used when matchmode !=0 " "temperature" int   1.0     { 0.01 10.0 }  -100 }
	{ numpoints      "Surface Matching: number of points to use for distance computation" "numpoints" int   1000     { 100 10000 } -101 }
	{ matchmode     "Surface Matching:  0 = ICP, 1=Mixture, 2=RPM (Use 0 for nearest neighbor)" "matchmode"  int   0     { 0 1 }  -102 }
	{ numberofbins    "Number of bins for the joint histogram"          "Number of Bins"     int   64    { 32  1024 } -103 }
	{ mode           "Mode (Surface/Image/Both)"   "Mode"  listofvalues  Image    { Image Surface Both }  1  }
	{ filename       "specify the filname for the output text file" "Text File Name" { filename writefile } "" { text { .txt } 50 } -30 }
	{ saveasimage "If on the output is an image instead of a text file"  "SaveImage"  boolean   0  { 0 1  }  -40  } 
    }


    set defaultsuffix { "_similarity" }
    
    set scriptname bis_computesimilarity
    set completionstatus "Done"

    #
    #document
    #

    set category "Registration"
    set description  "computes image similarity measures between the reference image and the target image after a transform and optionally point distances between the reference surface and the target surface."
    set description2 "Computed metrics for images are Joint Entropy, CR, Gradient Correlation, Mutual Information, Normalized Mutual Information, Sum of Squared Differences, Correlation ratio C(X|Y), Correlation ratio C(Y|X), Product, DifferenceEntropy."
    set backwardcompatibility "Reimplemented from pxmat_computesimilarity.tcl.point distance computation part should be integrated with bis_computedistance.tcl"
    set authors "hirohito.okuda@yale.edu,xenophon.papademetris.yale.edu"


    $this InitializeDualImageTransformationAlgorithm

    $this RenameInput 0 "Reference Objectmap" 100
    $this RenameInput 1 "Target Objectmap" 101
    $this RenameInput 2 "Tranformation" 102

}

# -----------------------------------------------------------------------------------------
itcl::body bis_computesimilarity::ComputeImageSimilarity { } {

    set inp(1) [ $this GetInput ] 
    set inp(2) [ $this GetSecondInput ] 

    for { set i 1 } { $i  <=2 } { incr i } {
	set d [ $inp($i) GetImageSize ]
	if { $d < 2 } {
	    set errormessage "Input Image $i is bad, cannot compute image similarity"
	    return 0
	}
    }

    set image_ref [ $inp(1) GetImage ]
    set image_trn [ $inp(2) GetImage ]
    set current_transform  [ [  $this GetTransformation ]  GetObject ]
    set numbins [ $OptionsArray(numberofbins) GetValue ]

    set reg [ vtkpxRegistration [ pxvtable::vnewobj ]]
    set arr [ vtkFloatArray [ pxvtable::vnewobj ]]
    set reg_measures [ list "Joint Entropy" "CR" "Gradient Correlation" "Mutual Information" "NMI" "Sum of Sq Diff" "Correlation ratio C(X|Y)" "Correlation ratio C(Y|X)" ]

    set image_ref_short [vtkImageData [pxvtable::vnewobj]]
    set image_trn_short [vtkImageData [pxvtable::vnewobj]]

    $reg ExtractComponentAndCastImageToShort $image_ref_short $image_ref 0 0
    $reg ExtractComponentAndCastImageToShort $image_trn_short $image_trn 0 0
    $reg ComputeAllSimilarityMetricsBetweenImages $image_ref_short $image_trn_short $current_transform $arr $numbins
    $reg Delete

    PrintMessage  "Computing Similarity between ref and resliced transform images\n"

    set headerline "\#"
    set contentline ""
    
    for { set i 0 } { $i < [ llength $reg_measures ] } { incr i } {
	if { $i== 1 || $i ==3 || $i==4 || $i==5 } {
	    append headerline "[ lindex $reg_measures $i ]\t"
	    append contentline "[ $arr GetComponent $i 0 ]\t"
	    #	    puts stdout "H=$headerline\nC=$contentline\n"
	}
    }

    $image_ref_short Delete
    $image_trn_short Delete
    $arr Delete

    set sm 0.0
    if { [ $current_transform IsA vtkpxComboTransform  ] ==1 } {
	set sm [ [ $current_transform GetGridTransform ] ComputeTotalBendingEnergy ]
	append headerline "Bending Energy"
	append contentline $sm
    }

    PrintMessage "$headerline\n$contentline\n"
    return "$headerline\n$contentline\n"
}

itcl::body bis_computesimilarity::ComputeSurfaceSimilarity {  } {


    set inp(1) [ $this GetInputObject reference_surface ]
    set inp(2) [ $this GetInputObject target_surface ]

    for { set i 1 } { $i  <=2 } { incr i } {
	set d [ $inp($i) GetSurfaceSize ]
	if { $d < 2 } {
	    set errormessage "Input Surface $i is bad, cannot compute surface similarity"
	    return 0
	}
    }

    set distance 0.0
    set surface_ref [ $inp(1)   GetObject ] 
    set surface_trn [ $inp(2)   GetObject ] 
    set numpoints [ $OptionsArray(numpoints) GetValue ]
    set temperature [ $OptionsArray(temperature) GetValue ]
    set matchmode [ $OptionsArray(matchmode) GetValue ]

    set rpm [ vtkpxRPMCorrespondenceFinder New ]
    $rpm SetSource $surface_ref 
    $rpm SetTarget $surface_trn 
    $rpm SetMaximumNumberOfLandmarks $numpoints
    $rpm SetMatchMode $matchmode
    $rpm SetUseLabels 1
    $rpm SetFastThreshold 3.0
    $rpm Initialize
	
    set trn  [ [  $this GetTransformation ]  GetObject ]

    $rpm WarpAndUpdateCorrespondence $trn $temperature
    set d [ $rpm ComputeDistance "Registration" ]
    set output [ format "\#EX \t %s \t RPM %8.5f\n" [ [ $this GetTransformation ] GetFileName  ] $d ]
    $rpm Delete

    PrintMessage $output
    return $output
    
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_computesimilarity::Execute {  } {

    PrintDebug "bis_computesimilarity::Execute"
    set saveimage [  $OptionsArray(saveasimage)  GetValue ]
    set mode [ $OptionsArray(mode) GetValue ]

    if { $saveimage == 0 } {
	if { $guimode == "commandline" } {
	    if { [ $OptionsArray(filename) GetValue ] == "" } {
		set errormessage "Empty Output Filename (-filename) for computing similarity metrics ($mode)"
		return 0
	    }
	}
    }

    set out1 "#No Image Similarity Computed\n0\t0\t0"
    set out2 "#No Surface Similarity Computed\n 0\t0\t0"


    if { $guimode !="commandline" } {
	pxtkconsole; 
	pxtkprint "\n-------------------------------------------------\n"
	pxtkprint "Computing Similarities ($mode), [ $this GetCommandLine short ]\n" 
	pxtkprint "-------------------------------------------------\n"
    }



    if { $mode == "Image" || $mode == "Both" } {
	set out1 [ $this ComputeImageSimilarity ]
	puts stderr "out1 = $out1"
	if { $out1 == 0 } {
	    return 0
	}
    }

    if { $mode == "Surface" || $mode == "Both" } {
	set out2 [ $this ComputeSurfaceSimilarity ]
	if { $out2 == 0 } {
	    return 0
	}
    }

    if { $saveimage == 0 } {
	if { [ $OptionsArray(filename) GetValue ] != "" } {
	    set fout [ open [ $OptionsArray(filename) GetValue ] w ]
	    puts -nonewline $fout $out1
	    puts -nonewline $fout $out2
	    close $fout
	    PrintMessage "Output saved in [ $OptionsArray(filename) GetValue ]"
	}
    }

    set output "$out1\n$out2\n"
    set lines [ split $output "\n" ]
    set goodlines ""
    set max 0 
    for { set i 0 } { $i < [ llength $lines ] } { incr i } {
	set line [ lindex $lines $i ] 
	#	puts stdout "Line $i = $line"
	set n [ llength $line ]
	set m [ string range $line 0 0 ]
	if { $m != "\#"  && $n > 1 } {
	    lappend goodlines $line
	    if { $n > $max } {
		set max $n
	    }
	}
    }
    #    puts stderr "Goodlines = $goodlines"

    set img [ vtkImageData New ]
    $img SetDimensions 2 $max 1
    $img SetScalarTypeToFloat
    $img AllocateScalars
    
    set dat [ [ $img GetPointData ] GetScalars ]
    $dat FillComponent 0 -10000.0

    for { set i 0 } { $i < [ llength $goodlines ] } { incr i } {
	set line [ lindex $goodlines $i ]
	for { set j 0 } { $j < [ llength $line ] } { incr j } {
	    $img SetScalarComponentFromDouble $i $j 0 0 [ lindex $line $j ] 
	}
    }

    set outimage [ $this GetOutput ]
    $outimage ShallowCopyImage $img;     $img Delete
    $outimage CopyImageHeader [ [ $this GetInput ] GetImageHeader ]
    
    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment" 0
    [ $outimage GetImageHeader ] AddComment "Similarity Output\n$output\n" 0
    



    return 1
}


# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_computesimilarity.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_computesimilarity [pxvtable::vnewobj]]
    $alg MainFunction 
}

