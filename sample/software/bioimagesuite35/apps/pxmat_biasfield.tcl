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





# 	$Id: pxflipslices.tcl,v 1.1 2004/01/15 15:11:59 xenios Exp xenios $	

set num $argc 

if { $num < 1 } {
    set scriptname [ file tail $argv0 ]
    puts stdout "\n$scriptname is part of BioImage Suite (www.bioimagesuite.org)\n"
    puts stdout "Syntax: $scriptname input \[ mode = 3 \] \[ threshold =0.05 \] \[ numclasses = 4 \] \[ res=3 \] \[ maxsigmaratio = 0.2 \] \[ minb1 =0.2 \] \[ maxb1=5.0 \]"
    puts stdout "\t\t mode = 0 (slice homogeneity) 1 (triple slice homogeneity) 2 (quadratic polynomial) 3 (cubic polynomial)"
    puts stdout "\t\t\t      4 = triple slice + quadratic, 5=triple slice + cubic."
    puts stdout "\t\tThreshold = 0.05, normalized threshold (0..1) to exclude voxels from bias field estimation -- to eliminate background"
    puts stdout "\t\tNumber of classes = number of tissue labels (background is a tissue label so add this) for polynomial"
    puts stdout "\t\tResolution = 3, resolution sampling for polynomial estimation"
    puts stdout "\t\tMaxSigmaRatio  = this constrains the ratio of the max standard deviation to the min standard deviation"
    puts stdout "\t\tMin B1 and Max B1 specify the range of B1 field allowed"
    puts stdout "\n"
    exit 0
}

# ---------------------------------------------------------------------------------------------------------

lappend auto_path [ file dirname [ info script ]]; package require pxappscommon


set name [ lindex $argv 0 ]
set argc [ llength $argv ]

set mode 3;         if { $argc > 1 } { set mode       [ ::pxappscommon::RestrictIntRange [ lindex $argv 1 ] 0 5 ] }
set threshold 0.05; if { $argc > 2 } { set threshold  [ ::pxappscommon::RestrictRange [ lindex $argv 2 ] 0.0 0.2 ] }
set numclasses 3;   if { $argc > 3 } { set numclasses [ ::pxappscommon::RestrictIntRange [ lindex $argv 3 ] 2 10 ] }
set resolution 3;   if { $argc > 4 } { set resolution [ ::pxappscommon::RestrictIntRange [ lindex $argv 4 ] 1 5 ] }
set sigmaratio 0.2; if { $argc > 5 } { set sigmaratio [ ::pxappscommon::RestrictRange [ lindex $argv 5 ] 0.0 1.0 ] }
set minb1 0.2      ;if { $argc > 6 } { set minb1      [ ::pxappscommon::RestrictRange [ lindex $argv 6 ] 0.1 0.95 ] }
set maxb1 5.0      ;if { $argc > 7 } { set maxb1      [ ::pxappscommon::RestrictRange [ lindex $argv 7 ] 1.1 10.0 ] }

# ---------------------------------------------------------------------------------------------------------

proc RunSliceHomogeneity   { inputimage } { 

    set fit [ vtkpxSliceBiasFieldCorrection  [ pxvtable::vnewobj ]]
    $fit SetRobustMode  1
    $fit SetPureScaling 0
    $fit SetInput       $inputimage
    $fit Update

    set img [ vtkImageData [ pxvtable::vnewobj ]]
    $img ShallowCopy [ $fit GetOutput ]
    $fit Delete
    return $img
}
# ----------------------------------------------------------------------------------------------------
proc RunTripleSliceHomogeneity   { inputimage } { 

    set axislist { x y z }

    set output [ vtkImageData [ pxvtable::vnewobj ]]
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
	$fit Delete
    }
    return $output
}
# ----------------------------------------------------------------------------------------------------
proc RunTripleSliceHomogeneityFit   { inputimage minb1 maxb1 } { 

    
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
	    set thisparam(pabic_shimval_0) [ $p GetComponent 0 0 ]
	    set thisparam(pabic_shimval_3) [ $p GetComponent 1 0 ]
	} elseif { $axis == 1 } {
	    set thisparam(pabic_shimval_1) [ $p GetComponent 0 0 ]
	    set thisparam(pabic_shimval_4) [ $p GetComponent 1 0 ]
	} else { 
	    set thisparam(pabic_shimval_2) [ $p GetComponent 0 0 ]
	    set thisparam(pabic_shimval_5) [ $p GetComponent 1 0 ]
	}
	$fit Delete
	$p Delete
    }


    set fit [ vtkpxPolynomialBiasFieldCorrection  [ pxvtable::vnewobj ]]
    set db [ vtkDoubleArray [ pxvtable::vnewobj ]]
    $db SetNumberOfTuples 18
    $db FillComponent 0 0.0
    for { set i 0 } { $i <= 5 } { incr i } {
	$db SetComponent $i 0 $thisparam(pabic_shimval_$i) 
    }
    set tmp [ $fit ComputeBiasFieldImage [ $currentimage GetImage ] $db  2 $minb1 $maxb1 ]
    set outimage [ $fit ComputeCorrectedImage $inputimage $tmp  ]

    $db Delete
    $fit Delete
    $tmp Delete
    return $outimage
}

# ----------------------------------------------------------------------------------------------------

proc RunPolynomial { inputimage degree threshold numclasses resolution sigmaratio minb1 maxb1 } {


    set fit [ vtkpxPolynomialBiasFieldCorrection  [ pxvtable::vnewobj ]]

    set tFilter  [ vtkImageThreshold [ pxvtable::vnewobj ]  ]

    if { $threshold > 0.0 } { 

	set range  [ [ [ $inputimage GetPointData ] GetScalars ] GetRange ]
	set tvalue [ expr [ lindex $range 0 ] + $threshold * ( [ lindex $range 1] - [ lindex $range 0 ]) ]
	puts stdout "\t\t Thresholding at $tvalue (range = $range) to generate mask for bias field correction"

	$tFilter SetInput $inputimage
	$tFilter SetInValue  100.0
	$tFilter SetOutValue   0.0
	$tFilter ReplaceInOn
	$tFilter ReplaceOutOn
	$tFilter ThresholdBetween $tvalue [ expr 0.001 + [ lindex $range 1 ] ]
	$tFilter SetOutputScalarTypeToShort
	$tFilter Update

	$fit SetMaskImage [ $tFilter GetOutput ]
    }

    $fit SetInput                $inputimage
    $fit SetMetric               0
    $fit SetNumberOfLevels       1
    $fit SetNumberOfSteps        1
    $fit SetResolution           $resolution
    $fit SetStepSize             0.05
    $fit SetNumberOfIterations   15
    $fit SetEpsilon              0.1
    $fit SetDegree               $degree
    $fit SetOptimizationMethodToConjugateGradient
    $fit SetFrame               0
    $fit SetMinValue            $minb1
    $fit SetMaxValue            $maxb1
    $fit SetHisto_NumberOfClasses  $numclasses
    $fit SetHisto_Iterations       50
    $fit SetHisto_NumberOfBins    128
    $fit SetHisto_Convergence     0.05
    $fit SetHisto_Sigma           0.05
    $fit SetHisto_MaxSigmaRatio     $sigmaratio
    $fit SetHisto_OutlierDetection 0 
    $fit SetHisto_PreprocessingMode 0
    $fit Update

    set outimage [ vtkImageData [ pxvtable::vnewobj ]]
    $outimage ShallowCopy [ $fit GetOutput ]
    $fit Delete
    $tFilter Delete
    return $outimage
}

# ----------------------------------------------------------------------------------------------------


set ana [ vtkpxAnalyzeImageSource  [ pxvtable::vnewobj ]]
$ana Load $name
set or [ $ana GetOrientation ]
puts stdout "\nRead $name [ [ $ana GetOutput ] GetDimensions ] ori=$or "

set outimage 0
set input [ $ana GetOutput ]
set modename ""

if { $mode == 0  } {
    set outimage [ RunSliceHomogeneity $input ]
    set modename "slicehom"
} elseif { $mode ==  1 || $mode >= 4 } {
    set outimage [ RunTripleSliceHomogeneity $input ]
    set modename "triplehom"
} else {
    set outimage [ vtkImageData [ pxvtable::vnewobj ]]
    $outimage ShallowCopy $input
}

set degree 0
if { $mode == 2 || $mode == 4 } {
    set degree 2
} elseif { $mode == 3 || $mode == 5 } {
    set degree 3
}

if { $degree > 0 } {
    set tmp $outimage
    set outimage [ RunPolynomial $tmp $degree $threshold $numclasses $resolution $sigmaratio $minb1 $maxb1 ]
    set modename "pabic$degree"
    $tmp Delete
}

set fname [ ::pxappscommon::GenOutputName $name $modename ]

set ana2 [ vtkpxAnalyzeImageWriter [ pxvtable::vnewobj ]]
$ana2 SetInput $outimage
$ana2 SetImageHeader [ $ana GetImageHeader ]

$ana2 Save $fname

puts stderr "Segmentation saved to $fname"

$ana2 Delete
$ana Delete
$outimage Delete

exit

