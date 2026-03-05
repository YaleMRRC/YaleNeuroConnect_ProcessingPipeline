#!/bin/sh
# the next line restarts using wish \
    exec vtk "$0" "$@"

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

package require bis_dualimagealgorithm 1.0

package provide bis_biasfield 1.0

#
# bias field correction
#

itcl::class bis_biasfield {

    inherit bis_dualimagealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Bias Field" }

    #
    #protected
    #

    protected variable pabic_shimval ""

    protected method RunSliceHomogeneity   { inputimage } 
    protected method RunTripleSliceHomogeneity   { inputimage } 
    protected method RunTripleSliceHomogeneityFit   { inputimage minb1 maxb1 } 
    protected method RunPolynomial { inputimage maskimage degree numclasses resolution sigmaratio minb1 maxb1 }

}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_biasfield::Initialize { } {

    PrintDebug "bis_biasfield::Initialize" 
    #name,description,type,object,filename(if applicable),priority (optional)

    set outputs {
	{ bias_field_image "Bias Field Estimate"  pxitclimage  "" 120 }
    }

    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ initmode "Preprocessing mode, none, slice or triple slice" "Initialization Moode" listofvalues None { None Slice TripleSlice } 0 }
	{ mode "Fitting Mode either None, Quadratic or Cubic" "Mode" listofvalues Quadratic { None Quadratic Cubic } 1 }
	{ numclasses    "Number of classes = number of tissue labels (background is a tissue label so add this) for polynomial" "Number Of Classes" int  3   { 2 10 }  2 }
	{ resolution    "resolution sampling for polynomial estimation " "Resolution" int  3   { 1 5 }  3 }
	{ maxsigmaratio    "The program assumes this as the ratio of the max standard deviation to the min standard deviation. This helps the program to prevent from detecting false peak from the histogram." "Max Sigma Ratio" real  0.2   { 0.1 1.0 }  -100 }
	{ minb1    "The program assumes this as the minimum value of the field B1 " "Min B1" real  0.2   { 0.1 0.95 }  -101 }
	{ maxb1    "The program assumes this as the maximum value of the filed B1 " "Max B1" real  5.0   { 1.1 10.0 }  -102 }
	{ usemask  "Use Mask Image" "Use Mask" boolean   0  { 0 1 } 25 }
    }
    
    set defaultsuffix { "restored" "biasfield" }
    
    set scriptname bis_biasfield

    #
    #document
    #

    set category "Image Processing Dual"
    set description "corrects bias field"
    set description2 "uses either simple linear inhomogeneity model algrotihm or PABIC's algorithm"
    set backwardcompatibility "Reimplemented from pxmat_biasfieled.tcl.The default output filename was ****_pabic etc, Now you need to specify output filename explicitly. "
    set authors "hirohito.okuda@yale.edu,xenophon.papademetris.yale.edu"

    $this InitializeDualImageAlgorithm

    $this RenameInput 1 "Mask Image" 102

}
# ---------------------------------------------------------------------------------------------------------

itcl::body bis_biasfield::RunSliceHomogeneity   { inputimage } { 

    set fit [ vtkpxSliceBiasFieldCorrection  [ pxvtable::vnewobj ]]
    $fit SetRobustMode  1
    $fit SetPureScaling 0
    $fit SetInput       $inputimage

	
    $fit Update

    set img [ vtkImageData [ pxvtable::vnewobj ]]
    $img ShallowCopy [ $fit GetOutput ]

    set bfield [ vtkImageData [ pxvtable::vnewobj ]]
    $bfield ShallowCopy [ $fit GetBiasField ]
    $fit Delete
    return [ list $img $bfield ] 
}
# ----------------------------------------------------------------------------------------------------
itcl::body bis_biasfield::RunTripleSliceHomogeneity   { inputimage } { 

    set axislist { x y z }

    set output [ vtkImageData [ pxvtable::vnewobj ]]
    set bfield [ vtkImageData [ pxvtable::vnewobj ]]
    $output ShallowCopy $inputimage
    
    for { set axis 0 } { $axis <=2 } { incr axis } {
	puts stderr ".... Slice Inhomogeneity Correction orientation  axis= [ lindex $axislist $axis ]\n"
	set fit [ vtkpxSliceBiasFieldCorrection  [ pxvtable::vnewobj ]]
	$fit SetAxis $axis
	$fit SetRobustMode  1
	$fit SetPureScaling 0
	$fit SetInput       $output
	$fit Update
	$output ShallowCopy [ $fit GetOutput ]
	$bfield ShallowCopy [ $fit GetBiasField ]
	$fit Delete
    }
    return [ list $output $bfield ]
}
# ----------------------------------------------------------------------------------------------------
itcl::body bis_biasfield::RunTripleSliceHomogeneityFit   { inputimage minb1 maxb1 } { 

    
    for { set axis 0 } { $axis <=2 } { incr axis } {
	puts stderr ".... Slice Inhomogeneity Correction orientation  axis= $axis /2\n"
	set fit [ vtkpxSliceBiasFieldCorrection  [ pxvtable::vnewobj ]]
	$fit SetAxis $axis
	$fit SetRobustMode  1
	$fit SetPureScaling 0
	$fit SetInput       $inputimage
	$fit Update

	set p [ vtkFloatArray [ pxvtable::vnewobj ]]
	$fit PolynomialFitToParameters 2 $p
	if { $axis == 0 } {
	    set pabic_shimval(0) [ $p GetComponent 0 0 ]
	    set pabic_shimval(3) [ $p GetComponent 1 0 ]
	} elseif { $axis == 1 } {
	    set pabic_shimval(1) [ $p GetComponent 0 0 ]
	    set pabic_shimval(4) [ $p GetComponent 1 0 ]
	} else { 
	    set pabic_shimval(2) [ $p GetComponent 0 0 ]
	    set pabic_shimval(5) [ $p GetComponent 1 0 ]
	}
	$fit Delete
	$p Delete
    }


    set fit [ vtkpxPolynomialBiasFieldCorrection  [ pxvtable::vnewobj ]]
    set db [ vtkDoubleArray [ pxvtable::vnewobj ]]
    $db SetNumberOfTuples 18
    $db FillComponent 0 0.0
    for { set i 0 } { $i <= 5 } { incr i } {
	$db SetComponent $i 0 $pabic_shimval($i) 
    }
    set tmp [ $fit ComputeBiasFieldImage [ $currentimage GetImage ] $db  2 $minb1 $maxb1 ]
    set outimage [ $fit ComputeCorrectedImage $inputimage $tmp  ]


    $db Delete
    $fit Delete

    return [ list  $outimage $tmp ]
}

# ----------------------------------------------------------------------------------------------------

itcl::body bis_biasfield::RunPolynomial { inputimage maskimage degree numclasses resolution sigmaratio minb1 maxb1 } {

    puts stdout "input=$inputimage mask=$maskimage"

    set fit [ vtkpxPolynomialBiasFieldCorrection  [ pxvtable::vnewobj ]]

    if { $maskimage !=0 } {
	$fit SetMaskImage $maskimage
    } 
    $fit SetInput                $inputimage
    $fit SetMetric               0
    $fit SetNumberOfLevels       1
    $fit SetNumberOfSteps        1
    $fit SetResolution           $resolution
    $fit SetStepSize             0.05
    $fit SetNumberOfIterations   10
    $fit SetEpsilon              0.1
    $fit SetDegree               $degree
    $fit SetOptimizationMethodToConjugateGradient
    $fit SetFrame               0
    $fit SetMinValue            $minb1
    $fit SetMaxValue            $maxb1
    $fit SetHisto_NumberOfClasses  $numclasses
    $fit SetHisto_Iterations       50
    $fit SetHisto_NumberOfBins    256
    $fit SetHisto_Convergence     0.05
    $fit SetHisto_Sigma           0.05
    $fit SetHisto_MaxSigmaRatio     $sigmaratio
    $fit SetHisto_OutlierDetection 0 
    $fit SetHisto_PreprocessingMode 2
    $fit Update

    set outimage [ vtkImageData [ pxvtable::vnewobj ]]
    $outimage ShallowCopy [ $fit GetOutput ]

    set bfield [ vtkImageData [ pxvtable::vnewobj ]]
    $bfield ShallowCopy [ $fit GetBiasField ]

    $fit Delete
    return [ list $outimage $bfield ]
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_biasfield::Execute {  } {

    DebugOn
    PrintDebug "bis_biasfield::Execute"

    set initmode    [ $OptionsArray(initmode)      GetValue ]
    set mode        [ $OptionsArray(mode)      GetValue ]

    if { $initmode == "None" && $mode=="None" } {
	set errormessage "Nothing to do both mode and initmode are set to None"
	return 0
    }

    set usemask      [ $OptionsArray(usemask)      GetValue ]
    set mode        [ $OptionsArray(mode)      GetValue ]
    set numclasses  [ $OptionsArray(numclasses)      GetValue ]
    set resolution  [ $OptionsArray(resolution)      GetValue ]
    set sigmaratio  [ $OptionsArray(maxsigmaratio)      GetValue ]
    set minb1        [ $OptionsArray(minb1)      GetValue ]
    set maxb1        [ $OptionsArray(maxb1)      GetValue ]
    set image_in    [ $InputsArray(input_image) GetObject ]
    set mask_in 0


    set outimage 0

    set tmplist ""

    
    set degree 3
    if { $mode == "None" } { 
	set degree 0
    } elseif { $mode == "Quadratic" } {
	set degree 2
    }

    if { $usemask > 0 && $degree > 0 } {
	set mask_in    [ $InputsArray(second_image) GetObject ]
	if { [ $mask_in GetImageSize ] !=  [ $image_in GetImageSize ] } {
	    set errormessage "Supplied mask does not have the same dimensions as the input image"
	    return 0
	} else {
	    puts stdout "Supplied mask [ $mask_in GetImageSize ] does not have the same dimensions as the input image [ $image_in GetImageSize ]"
	}
    }

    set md 0
    if { $initmode == "Slice" }  {
	set md 1
    } elseif { $initmode == "TripleSlice" } {
	set md 2
    }

    set tmplst  ""
    set deletetmplst 0
    set outlst ""
    set outimage [ [ $this GetInput ] GetImage ]

    puts stderr "Md=$md, degree=$degree"

    if { $md ==  1 } {
	puts stderr "Running Slice"
	set outlst [ RunSliceHomogeneity [$image_in GetObject]]
	set outimg [ lindex $outlst 0 ]
	set modename "slicehom"
	set deletetmplst 1
    } elseif { $md == 2 } {
	puts stderr "Running Triple Slice"
	set outlst [ RunTripleSliceHomogeneity [$image_in GetObject]]
	set outimg [ lindex $outlst 0 ]
	set modename "triplehom"
	set deletetmplst 1
    } 

    if { $degree > 0 } {
	set modename "pabic${degree}"
	set tmplst $outlst
	puts stderr "Running Polynomial degree=$degree"
	if { $usemask > 0 } {
	    set msk [ $mask_in GetImage ]
	} else {
	    set msk 0
	}
	set outlst [ RunPolynomial $outimage  $msk $degree $numclasses $resolution $sigmaratio $minb1 $maxb1 ]
    }

    [ $OutputsArray(output_image) GetObject ] ShallowCopyImage [ lindex $outlst 0 ]
    [ $OutputsArray(bias_field_image) GetObject ] ShallowCopyImage [ lindex $outlst 1 ]

    # Output orientation etc. is same as input
    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]

    set bfield [ $OutputsArray(bias_field_image) GetObject ]
    $bfield CopyImageHeader [ $image_in GetImageHeader ]

    set comment [ $this GetCommandLine "full" ]

    [ $outimage GetImageHeader ] AddComment $comment 0

    for { set i 0 } { $i < [ llength $outlst ] } { incr i } {
	[ lindex $outlst $i ] Delete
    }

    if { $deletetmplst > 0 } {
	for { set i 0 } { $i < [ llength $tmplist ] } { incr i } {
	    [ lindex $tmplst $i ] Delete
	}
    }

    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_biasfield.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_biasfield [pxvtable::vnewobj]]
    $alg MainFunction 
}

