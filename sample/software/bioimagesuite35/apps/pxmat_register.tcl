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





# --------------------------------------------------------------------------------------------------------
# 	$Id: pxmat_register.tcl,v 1.1 2004/01/15 15:08:41 xenios Exp xenios $	
set argc [llength $argv]
if { $argc <3 } {
    set scriptname [ file tail $argv0 ]
    puts stdout "\n$scriptname is part of BioImage Suite (www.bioimagesuite.org)\n"
    puts stdout "$scriptname is a script that computes either linear or linear+non-linear intensity based registrations"

    puts stdout "Syntax: $scriptname ref_image trg_image output_transformation \[transformmode=2\] \[resolution=1.5\] \[spacing=15\] \[iterations=15\] \[ step_size=1.0\] \[ smoothness=0.0\] \[ linearmode = 1 \] \[ autonormalize_intensities =1 \] \[ prior_xform = none \] \[ prior_weights = none \] \[minimum_spacing_ratio=4\]"
    puts stdout "\t\ttransformmode: rigid=3 similarity=2, affine=1, nonlinear=0, linearmode = 3,2,1 if transformmode=0"
    puts stdout "\n"
    exit 0
}
   
lappend auto_path [ file dirname [ info script ]]; package require pxappscommon
set filenametype 0
set linearmode   1
set autonormalize 1
# --------------------------------------------------------------------------------------------------------
proc DoNMI { image1 orient1 image2 orient2 output_xform xform_mode initialxform { resolution 1.5 } { spacing 15.0 } { iterations 15 } { stepsize 1 } { smoothness 0 } } {

    global transformmode
    global linearmode
    global autonormalize


    if { $xform_mode == "linear" } {
	set areg [ vtkpxLinearRegistration [ pxvtable::vnewobj ]]
	$areg DebugOn

	if { $linearmode == 3 } {
	    $areg SetTransformModeToRigid
	    puts stdout "Transform Mode = Rigid"
	} elseif { $linearmode == 2 }  {
	    $areg SetTransformModeToSimilarity
	    puts stdout "Transform Mode = Similarity"
	} else {
	    $areg SetTransformModeToAffine
	    puts stdout "Transform Mode = Affine"
	}

	$areg SetAutoNormalizeIntensities $autonormalize
	$areg SetSimilarityMeasure 5
	puts stderr "On To Setting Ref/Trg"
	$areg SetReferenceImage $image1
	$areg SetTransformImage $image2
	$areg SetReferenceOrientation $orient1
	$areg SetTransformOrientation $orient2
	$areg SetResolution $resolution
	$areg SetNumberOfLevels 3
	$areg SetNumberOfSteps  1
	$areg SetStepSize       $stepsize
	$areg SetOptimizationMethodToConjugateGradient
	$areg SetNumberOfIterations [ expr round(2 * $iterations) ]
	$areg DebugOff
	eval "$areg AddObserver ProgressEvent { set a   \[ $areg GetOutputStatus \]; if \{ \[ string length  \$a \] > 0  \} \{ puts -nonewline stdout \$a \} }"
	$areg Run
        puts stdout "DoNMI 1111111111111111111111111111111111111111111111111111111111111111111111"	
	$output_xform DeepCopy  [ $areg GetTransformation ]
        puts stdout "DoNMI 2222222222222222222222222222222222222222222222222222222222222222222222"
	$areg Delete
        puts stdout "DoNMI 3333333333333333333333333333333333333333333333333333333333333333333333"
    } else {
	set nreg [ vtkpxNonLinearRegistration [ pxvtable::vnewobj ]]

	$nreg SetSimilarityMeasure 5
	
	if { $initialxform !=0 } { 
	    $nreg SetInitialTransform $initialxform 
	    puts stdout "Using Initial Transformation"
	}
	$nreg DebugOn
	$nreg SetAutoNormalizeIntensities $autonormalize
	$nreg SetReferenceImage $image1
	$nreg SetTransformImage $image2 
	$nreg SetNumberOfSteps  1
	$nreg SetNumberOfLevels 3
	$nreg SetStepSize       $stepsize 
	$nreg SetLambda [ expr 0.01 * $smoothness ]
	$nreg SetResolution     $resolution
	$nreg SetControlPointSpacing $spacing
	$nreg SetControlPointSpacingRate 2.0
	$nreg SetOptimizationMethodToDefault
	$nreg SetNumberOfIterations [ expr round($iterations) ]
	$nreg DebugOff
	eval "$nreg AddObserver ProgressEvent { puts stdout  \[ $nreg GetOutputStatus \] }"
	
	$nreg Run
	$output_xform DeepCopy  [ $nreg GetTransformation ]
	$nreg Delete
    }

}
# --------------------------------------------------------------------------------------------------------
# Do Prior NMI
# --------------------------------------------------------------------------------------------------------

proc DoPriorNMI { image1 image2 output_xform priorxform priorweights { resolution 1.5 } { spacing 15.0 } { iterations 15 } { stepsize 1 } { smoothness 0 } } {

    global autonormalize

    set nreg [ vtkpxNonLinearPriorRegistration [ pxvtable::vnewobj ]]

    $nreg SetSimilarityMeasure 5
    $nreg SetPriorTransform $priorxform
    if { $priorweights !=0 } {
	$nreg SetPriorWeights $priorweights
    }

    $nreg SetAutoNormalizeIntensities $autonormalize   
    $nreg SetReferenceImage $image1
    $nreg SetTransformImage $image2 
    $nreg SetNumberOfSteps  1
    $nreg SetNumberOfLevels 1
    $nreg SetStepSize       $stepsize 
    $nreg SetLambda [ expr 0.01 * $smoothness ]
    $nreg SetResolution     $resolution
    $nreg SetControlPointSpacing $spacing
    $nreg SetControlPointSpacingRate 2.0
    $nreg SetOptimizationMethodToDefault
    $nreg SetNumberOfIterations $iterations

    eval "$nreg AddObserver ProgressEvent { puts stdout  \[ $nreg GetOutputStatus \] }"
    $nreg Run
    $output_xform DeepCopy  [ $nreg GetTransformation ]
    $nreg Delete
}

# --------------------------------------------------------------------------------------------------------
#   Main Program 
# ----------------------------------------------------------------------------------------------------

proc DoNMIAll { refimagename trnimagename output transformmode resolution spacing iterations stepsize smoothness priorxformname priorweightsname minimum_spacing_ratio} {
    
    set ut [ vtkpxTransformationUtil [ pxvtable::vnewobj ]]
    global linearmode

    puts stdout "\n----------------- Loading Reference Image ---------------------------\n"
    set ana [ vtkpxAnalyzeImageSource [ pxvtable::vnewobj ]]
    $ana Load $refimagename
    set img_ref [ $ana GetOutput ]
    puts stdout "Reference Image Read from $refimagename dimensions = [ $img_ref GetDimensions ]"

   #exception handling from here
    scan [$img_ref  GetSpacing] "%f %f %f" sp(0) sp(1) sp(2)
    set spacing_ratio_too_small 0
    for { set i 0 } { $i < 3} { incr i} {
	set spacing_ratio [ expr $spacing /$sp($i)] 
	puts stderr "spacing_ratio = $spacing_ratio, spacing = $sp($i)"
        if { $spacing_ratio < $minimum_spacing_ratio } {
	    set spacing_ratio_too_small 1
	}
    }
#    if { $spacing_ratio_too_small == 1 } {
#	puts stderr "Control point spacing is too small. Control point spacing must be at least 
#$minimum_spacing_ratio times as large as voxel spacing."
#       return 0
#    }
   #exception handling to here

    set ana2 [ vtkpxAnalyzeImageSource [ pxvtable::vnewobj ]]
    $ana2 Load $trnimagename
    set img_trn [ $ana2 GetOutput ]
    puts stdout "Target Image Read from $trnimagename dimensions = [ $img_trn GetDimensions ]"
    

    set orient1 [ $ana  GetOrientation ]
    set orient2 [ $ana2 GetOrientation ]

    if { $orient1 != $orient2  && $transformmode == 0 } {
	puts stderr "Cannot Register Different Orientation $orient1 $orient2"
    }
    
    if { $priorxformname == "none" } {

	puts stdout "\n----------------- Running Linear  ---------------------------\n"
	
	set xform [ vtkTransform [ pxvtable::vnewobj ]]
	$xform Identity 
	DoNMI  $img_ref $orient1 $img_trn $orient2  $xform  linear 0 $resolution $spacing $iterations 1 0
        puts stdout "DoNMIAll 22222222222" 	
	if { $transformmode > 0 } {
	    set fname "${output}.matr"
	    set ok [ $ut SaveAbstractTransform $xform $fname ]
	    if { $linearmode == 1 } {
		puts stdout "Affine Transformation saved in $fname ($ok) [ file size $fname ]"
	    } elseif { $linearmode == 2 } { 
		puts stdout "Similarity Transformation saved in $fname ($ok) [ file size $fname ]"
	    } else {
		puts stdout "Rigid Transformation saved in $fname ($ok) [ file size $fname ]"
	    }
	} else  {
	    puts stdout "\n----------------- Running Non-Linear  ---------------------------\n"
	    set xform2 [ vtkpxComboTransform [ pxvtable::vnewobj ] ]
	    DoNMI $img_ref $orient1 $img_trn $orient2 $xform2 nonlinear  $xform $resolution $spacing $iterations $stepsize $smoothness 
	    set fname "${output}.grd"
	    set ok [ $xform2 Save $fname  ]
	    puts stdout "Non Linear Transformation saved in $fname ($ok) [ file size $fname ]"
	    $xform2 Delete
	}
	$xform Delete
    } else {
	set prior [ vtkpxComboTransform [ pxvtable::vnewobj ] ]
	set ok [ $prior Load $priorxformname ]
	puts stdout "Prior Transform read from $priorxformname (ok=$ok)\n"

	if { $priorweightsname !="none" } {
	    set mot [ vtkpxLinearMotionCorrect  [ pxvtable::vnewobj ]]    
	    set priorweights [ vtkFloatArray [ pxvtable::vnewobj]]
	    set ok [ $mot LoadMotionParameters $priorweights $priorweightsname ]
	    puts stdout "Prior Weights read from $priorweightsname (ok=$ok)\n"
	    $mot Delete
	} else {
	    set priorweights 0
	}

	set xform2 [ vtkpxComboTransform [ pxvtable::vnewobj ] ]
	DoPriorNMI $img_ref $img_trn $xform2 $prior $priorweights  $resolution $spacing $iterations $stepsize $smoothness 
	set fname "${output}.grd"
	set ok [ $xform2 Save $fname  ]
	puts stdout "Non Linear Transformation (Prior) saved in $fname ($ok) [ file size $fname ]"
	$xform2 Delete
    }
	

    puts stdout "\n----------------- Done  ---------------------------\n"
   
    $ana Delete
    $ana2 Delete
    $ut Delete
    return 1
}

# --------------------------------------------------------------------------------------------------------

set argc [ llength $argv ]

#for { set i 0 } { $i < $argc } { incr i } {
#    puts stderr "\t\t $i / $argc \t\t [ lindex $argv $i ]"
#}

set refimg [ lindex $argv 0 ]
set tarimg [ lindex $argv 1 ]
set output [ file root [ lindex $argv 2 ] ]
set prior_xform 0

set transformmode 0
if { $argc > 3 } {
#    puts stderr "argv(3) = [ lindex $argv 3 ]"
    if {  [ lindex $argv 3 ] == 1 } {
	set transformmode 1 
    } elseif { [ lindex $argv 3 ] == 2 } {
	set transformmode 2
    } elseif { [ lindex $argv 3 ] == 3 } {
	set transformmode 3
    }
}
#puts stderr "Transform Mode = $transformmode \n\n"

if { $argc > 4 } {
    set resolution [ lindex $argv 4 ]
} else {
    set resolution 1.5
}

if { $argc > 5 } {
    set spacing [ lindex $argv 5 ]
} else {
    set spacing 15.0
}

if { $argc > 6 } {
    set iterations [ lindex $argv 6 ]
} else {
    set iterations 15
}


if { $argc > 7 } {
    set stepsize [ lindex $argv 7 ]
} else {
    set stepsize 1.0
}


if { $argc > 8 } {
    set smoothness [ lindex $argv 8 ]
} else {
    set smoothness 0.0
}

if { $transformmode == 0 } {
    if { $argc > 9 } {
	set linearmode [ lindex $argv 9 ]
    } else {
	set linearmode 1
    }
} else {
    set linearmode $transformmode
}

if { $argc > 10 } {
    set autonormalize [ expr [ lindex $argv 10 ] > 0 ]
}

#puts stderr "Linear Mode = $linearmode argc=$argc\n\n"

if { $argc > 11 } {
    set priorxform [ lindex $argv 11 ]
} else {
    set priorxform "none"
}

if { $argc > 12 } {
    set priorweights [ lindex $argv 12 ]
} else {
    set priorweights "none"
}

if { $argc > 13 } {
    set minimum_spacing_ratio [ lindex $argv 13 ]
} else {
    set minimum_spacing_ratio 4
}


set comment "Beginning ref=$refimg -> tar=$tarimg output=$output transformmode=$transformmode (linearmode=$linearmode) res=$resolution spa=$spacing it=$iterations stepsize=$stepsize smoothness=$smoothness priorxform=$priorxform priorweights=$priorweights numargs=[ llength $argv ]"
puts stdout $comment
set comment "$comment\n\ncommandline = pxmat_register" 
for { set c 0 } { $c < $argc } { incr c } {
    set comment "$comment [ lindex $argv $c ]"
}

set fout [ open ${output}.log w ]
puts $fout $comment
close $fout


DoNMIAll $refimg $tarimg  $output  $transformmode $resolution $spacing $iterations $stepsize $smoothness  $priorxform $priorweights $minimum_spacing_ratio

exit 0

