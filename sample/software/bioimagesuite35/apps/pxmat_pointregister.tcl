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
# 	$Id: pxmat_pointregister.tcl,v 1.1 2004/01/15 15:09:08 xenios Exp xenios $	



set argc [llength $argv]
if { $argc <3 } {
    set scriptname [ file tail $argv0 ]
    puts stdout "\n$scriptname is part of BioImage Suite (www.bioimagesuite.org)\n"
    puts stdout "$scriptname is a script that computes either linear or linear+non-linear point-based registrations"

    puts stdout "Syntax: $scriptname ref_surface trg_surface output_transformation \[transformmode=0\] \[ userpm =1 \] \[points=3000\] \[tstart=5.0\] \[ tend=2.0\] \[ smoothstart=5.0\] \[ smooth_end=1.0 \] \[ cps_start=30.0 \] \[ cps_end =15.0 \]  \[ prior_xform = none \] \[ prior_weights = none \] "
    puts stdout "\t\ttransformmode: rigid=3, similarity=2, affine=1, nonlinear=0"
    puts stdout "\t\tuserpm = 0,1 if 1 use RPM algorithm, if 0 use ICP"
    puts stdout "\n"
    exit 1
}
   
lappend auto_path [ file dirname [ info script ]]; package require pxappscommon

# --------------------------------------------------------------------------------------------------------
proc DoRPM { surface1 surface2 output_xform xform_mode initialxform numpoints tstart tend smoothstart smoothend cpsstart cpsend priorxform priorxformweights  outputweights  } {

    global transformmode
    global userpm

    puts stderr "Use RPM = $userpm\n"

    if { [ string length $initialxform] == 0 } {
	set initialxform 0
    }

    if { $xform_mode == "linear" } {
	set rpmxform [ vtkpxLinearRPMRegistration  [ pxvtable::vnewobj ]]
	$rpmxform DebugOn
	
	if { $transformmode == 3 } {
	    $rpmxform SetTransformModeToRigid
	} elseif { $transformmode == 2 } {
	    $rpmxform SetTransformModeToSimilarity
	} else {
	    $rpmxform SetTransformModeToAffine
	}
	

	$rpmxform SetAnnealRate 0.93
	$rpmxform SetInitialTemperature $tstart
	$rpmxform SetFinalTemperature   $tend

	if { $userpm == 1 } {
	    $rpmxform SetMatchModeToRPMFast
	} else {
	    $rpmxform SetMatchModeToICP
	}
	
	$rpmxform SetUseLabels  1
	$rpmxform SetUseWeightedLeastSquares 1
	$rpmxform SetFastThreshold 3.0

	if { $initialxform != 0 } {
	    puts stdout "Using Initial Transformation [ $initialxform GetClassName ]"
	    $rpmxform SetUseInitialTransform  1
	    $rpmxform SetInitialTransform     $initialxform 
	}
    } else {
	set rpmxform [ vtkpxBSplinePriorRPMRegistration  [ pxvtable::vnewobj ]]
	$rpmxform SetAnnealRate 0.93
	$rpmxform SetFastThreshold 3.0

	$rpmxform SetInitialControlPointSpacing  $cpsstart
	$rpmxform SetFinalControlPointSpacing   $cpsend

	$rpmxform SetInitialSmoothnessFactor $smoothstart
	$rpmxform SetFinalSmoothnessFactor $smoothend

	$rpmxform SetInitialTemperature $tstart
	$rpmxform SetFinalTemperature   $tend

	if { $userpm == 1 } {
	    $rpmxform SetMatchModeToRPMFast
	} else {
	    $rpmxform SetMatchModeToICP
	}

	$rpmxform SetUseLabels 1
	$rpmxform SetUseWeightedLeastSquares 1
	
	if { $priorxform != 0 } {
	    $rpmxform SetPriorTransform $priorxform
	    if { $priorxformweights !=0 } {
		$rpmxform SetPriorWeights $priorweights
	    }
	} elseif { $initialxform != 0 } {
	    puts stdout "Using Initial Transformation [ $initialxform GetClassName ]"
	    $rpmxform SetUseInitialTransform  1
	    $rpmxform SetInitialTransform     $initialxform 
	}
	
    }
    $rpmxform DebugOn    
    if { $numpoints < -1  } {
	if { $xform_mode != "linear" } {
	    $rpmxform SetPreferentialSampling 1
	}
	$rpmxform SetMaximumNumberOfLandmarks [ expr abs($numpoints) ]
    } else {
	$rpmxform SetMaximumNumberOfLandmarks $numpoints
    }
    $rpmxform DebugOff

    $rpmxform EnableFeedbackOn
    $rpmxform SetExtraDebug 1

    $rpmxform SetSource $surface1
    $rpmxform SetTarget $surface2

    $rpmxform DebugOn
    $rpmxform Run
    
    puts stdout "Copying a [ $output_xform GetClassName ] from [ [ $rpmxform GetCurrentTransformation ] GetClassName ]"
    $output_xform DeepCopy [ $rpmxform GetCurrentTransformation ]

    if { $xform_mode != "linear" && $outputweights !=0 } {
	$outputweights DeepCopy [ $rpmxform GetFinalWeights ]
    }
	
    $rpmxform Delete
}
# --------------------------------------------------------------------------------------------------------
#   Main Program 
# ----------------------------------------------------------------------------------------------------

proc DoRPMALL { refsurfacename trnsurfacename output transformmode numpoints tstart tend smoothstart smoothend cpsstart cpsend priorxformname priorweightsname  } {
    
    puts stdout "\n----------------- Loading Reference Surface ---------------------------\n"
    set ana [ vtkPolyDataReader [ pxvtable::vnewobj ]]
    $ana SetFileName $refsurfacename; $ana Update
    set sur_ref [ $ana GetOutput ]
    puts stdout "Reference Surface Read from $refsurfacename points = [ $sur_ref GetNumberOfPoints ], bbox = [ $sur_ref GetBounds ]"
    
    set ana2 [ vtkPolyDataReader [ pxvtable::vnewobj ]]
    $ana2 SetFileName $trnsurfacename; $ana2 Update
    set sur_trn [ $ana2 GetOutput ]
    puts stdout "Target Surface Read from $trnsurfacename points = [ $sur_trn GetNumberOfPoints ], bbox = [ $sur_trn GetBounds ]"
    
    set nfactor 1.0
    set tfactor 1.0
    if { $transformmode == 0 } {
	set nfactor 0.5
	set tfactor 3.0
    }
    set ut [ vtkpxTransformationUtil [ pxvtable::vnewobj ]]
    		
    set usepriorreg 0
    if { $priorxformname != "none" } {
	if { [ file extension $priorxformname ] == ".grd" } {
	    set usepriorreg 1
	}
    }

    set prior 0
    if { $priorxformname != "none" } {
	set prior  [ $ut LoadAbstractTransform $priorxformname ]
    }

    set xform [ vtkTransform [ pxvtable::vnewobj ]]
    $xform Identity 
      
    if { $usepriorreg == 0 } {

	set runlinear 1
	
	if { $prior !=0 && $prior !="" } {
	    puts stdout "Prior=$prior"
	    if { [ $prior IsA vtkTransform ] == 1 && $transformmode == 0 } {
		$xform DeepCopy $prior
		puts stdout "Copying initial transfor from $priorxformname"
		set runlinear 0
	    }
	}

	if { $runlinear == 1} {
	    puts stdout "\n----------------- Running Linear  ---------------------------\n"
	    DoRPM $sur_ref $sur_trn  $xform linear $prior [ expr round($nfactor*$numpoints) ] [ expr $tfactor*$tstart]  $tend $smoothstart $smoothend $cpsstart $cpsend 0 0 0 
	    catch { $prior Delete }
	}

	if { $runlinear == 1 } {
	    set fname "${output}.matr"
	    
	    set ok [ $ut SaveAbstractTransform $xform $fname ]
	    if { $transformmode == 1 } {
		puts stdout "Affine Transformation saved in $fname ($ok) [ file size $fname ]"
	    } elseif { $transformmode == 2 } {
		puts stdout "Similarity Transformation saved in $fname ($ok) [ file size $fname ]"
	    } else {
		puts stdout "Rigid Transformation saved in $fname ($ok) [ file size $fname ]"
	    }
	}

	if { $transformmode == 0 } {
	    puts stdout "\n----------------- Running Non-Linear  ---------------------------\n"
	    set xform2 [ vtkpxComboTransform [ pxvtable::vnewobj ] ]
	    set outputweights [ vtkFloatArray [ pxvtable::vnewobj ]]
	    
	    DoRPM $sur_ref $sur_trn  $xform2 nonlinear $xform $numpoints $tstart $tend $smoothstart $smoothend $cpsstart $cpsend 0 0 $outputweights 
	    set fname "${output}.grd"
	    set ok [ $xform2 Save $fname  ]
	    puts stdout "Non Linear Transformation saved in $fname ($ok) [ file size $fname ]"
	    
	    $xform2 Delete
	    $outputweights Delete
	}
	$xform Delete
    } else {
	
	if { $priorweightsname !="none" } {
	    set priorweights [ vtkFloatArray [ pxvtable::vnewobj]]
	    set mot [ vtkpxLinearMotionCorrect  [ pxvtable::vnewobj ]]    
	    set ok [ $mot LoadMotionParameters $priorweights $priorweightsname ]
	    puts stdout "Prior Weights read from $priorweightsname (ok=$ok)\n"
	    $mot Delete
	} else {
	    set priorweights 0
	}

	set xform2 [ vtkpxComboTransform [ pxvtable::vnewobj ] ]
	set outputweights [ vtkFloatArray [ pxvtable::vnewobj ]]
	
	DoRPM $sur_ref $sur_trn  $xform2 nonlinear 0 $numpoints $tstart $tend $smoothstart $smoothend $cpsstart $cpsend $prior $priorweights $outputweights

	set fname "${output}.grd"
	set ok [ $xform2 Save $fname  ]

	$xform2 Delete
	$outputweights Delete
    }
	

    puts stdout "\n----------------- Done  ---------------------------\n"

    $ut Delete
    $ana Delete
    $ana2 Delete
    return 1
}

# --------------------------------------------------------------------------------------------------------


set argc [ llength $argv ]
set refsur [ lindex $argv 0 ]
set tarsur [ lindex $argv 1 ]
set output [ file root [ lindex $argv 2 ] ]
set prior_xform 0

set transformmode 0
if { $argc > 3 } {
    if {  [ lindex $argv 3 ] == 1 } {
	set transformmode 1 
    } elseif { [ lindex $argv 3 ] == 2 } {
	set transformmode 2
    } elseif { [ lindex $argv 3 ] == 3 } {
	set transformmode 3
    }
} 

set userpm 1
if { $argc > 4 } {
    if {  [ lindex $argv 4 ] == 0 } {
	set userpm 0
    }
} 


if { $argc > 5 } {
    set numpoints [ lindex $argv 5 ]
} else {
    set numpoints 3000
}

if { $argc > 6 } {
    set tstart [ lindex $argv 6 ]
} else {
    set tstart 5
}

if { $argc > 7 } {
    set tend [ lindex $argv 7 ]
} else {
    set tend 2
}


if { $argc > 8 } {
    set smoothstart [ lindex $argv 8 ]
} else {
    set smoothstart 5.0
}


if { $argc > 9 } {
    set smoothend [ lindex $argv 9 ]
} else {
    set smoothend 1.0
}

if { $argc > 10 } {
    set cpsstart [ lindex $argv 10 ]
} else {
    set cpsstart 30
}


if { $argc > 11 } {
    set cpsend [ lindex $argv 11 ]
} else {
    set cpsend 15
}

if { $argc > 12 } {
    set priorxform [ lindex $argv 12 ]
} else {
    set priorxform "none"
}

if { $argc > 13 } {
    set priorweights [ lindex $argv 13 ]
} else {
    set priorweights "none"
}


set comment "Beginning ref=$refsur -> tar=$tarsur output=$output transformmode=$transformmode userpm=$userpm points=$numpoints temp=$tstart : $tend smooth=$smoothstart : $smoothend cps=$cpsstart : $cpsend priorxform=$priorxform priorweights=$priorweights numargs=[ llength $argv ]"
puts stdout $comment
set comment "$comment\n\ncommandline = pxmat_pointregister" 
for { set c 0 } { $c < $argc } { incr c } {
    set comment "$comment [ lindex $argv $c ]"
}

set fout [ open ${output}.log w ]
puts $fout $comment
close $fout


DoRPMALL $refsur $tarsur  $output  $transformmode $numpoints $tstart $tend $smoothstart $smoothend $cpsstart $cpsend $priorxform $priorweights"

puts stderr "Done OK"

exit 0

