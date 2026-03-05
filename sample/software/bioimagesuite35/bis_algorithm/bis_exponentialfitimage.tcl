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

package provide bis_exponentialfitimage 1.0
package require bis_imagetoimagealgorithm 1.0


itcl::class bis_exponentialfitimage {

    inherit bis_imagetoimagealgorithm

     constructor { } {	 $this Initialize  }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Exponentia Fit Image" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_exponentialfitimage::Initialize { } {

    PrintDebug "bis_exponentialfitimage::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ mode  "Gen t-values automatically or use list" "Use List"  boolean 0 { 0 1 } 1 }
	{ t0    "First t-value" "T0" real  15.0   { 0.0 50000.0 }  1 }
	{ dt    "T-spacing" "DT" real  15.0   { 0.0 50000.0 }  2 }
	{ tlist  "List of t-values" "T-List"  string "" { "" }  3 }
	{ t2  "Output T2 Instead of R2" "Output T2" boolean   0  { 0 1 } 25 }
	{ reverse  "Reverse Order of T-times" "Reverse t-list" boolean   0  { 0 1 } 30 }
	{ maxt2    "Maximum t2 value to output" "Max T2" real  500.0   { 0.0 10000.0 }  -102 }
	{ reciprocalt    "Use 1/t instead of t -- useful for fitting exp(- t_i*T) instead of exp(-T/t_i) sequences" "ReciprocalT" boolean 0   { 0 1 }  -105 }
	{ threshold    "Do not fit if intensity is below this * max" "Threshold" real  0.05   { 0.0 1.0 }  -103 }
    }

    set defaultsuffix { "_t2" }

    set outputs {
	{ density_image "Density Image"  pxitclimage  "" 120 }
    }
    
    set scriptname bis_exponentialfitimage
    set completionstatus "Done"

    #
    #document
    #
    
    set description "Computes a T2-fit (or other decaying exponential) from a 4D image"
    set description2 ""
    set backwardcompatibility "Reimplemented from pxitclexpfit.tcl"
    set category "Image Processing-4D"
    $this InitializeImageToImageAlgorithm
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_exponentialfitimage::Execute {  } {

    PrintDebug "bis_exponentialfitimage::Execute"

    set mode      [ $OptionsArray(mode) GetValue ]
    set t0        [ $OptionsArray(t0)      GetValue ]
    set dt        [ $OptionsArray(dt)    GetValue ]
    set tlist     [ $OptionsArray(tlist)    GetValue ]
    set t2        [ $OptionsArray(t2)    GetValue ]
    set maxt2     [ $OptionsArray(maxt2)    GetValue ]
    set reverse   [ $OptionsArray(reverse)    GetValue ]
    set reciprocal [ $OptionsArray(reciprocalt) GetValue ]
    set threshold [ $OptionsArray(threshold)    GetValue ]
    set image_in  [ $this GetInput ]


    set nc [ [ $image_in GetImage ]  GetNumberOfScalarComponents ]
    if { $nc < 3 } {
	set errormessage "Not enough frames for for mono-exponential fitting $nc <3 "
	return 0
    }

    set fl [ vtkFloatArray [ pxvtable::vnewobj ]]
    $fl SetNumberOfComponents 1
    $fl SetNumberOfTuples $nc

    if { $reverse == 1 } {
	set t0 [ expr $t0 + $dt * ($nc -1 ) ]
	set dt [ expr -1.0 *$dt  ]
	if { [ llength $tlist ] > 1  } {
	    set old $tlist
	    set tlist ""
	    set i [ llength $old ]
	    while {$i > 0 } {
		lappend tlist [lindex $old [incr i -1] ]
	    }
	}
    }
    


    if { $mode == 0 } {
	for { set i 0 } { $i < $nc } { incr i } {
	    if { $reciprocal == 0 } {
		$fl SetComponent $i 0 [ expr $t0 + $i * $dt ] 
	    } else {
		$fl SetComponent $i 0 [ expr 1.0/($t0 + $i * $dt) ]
	    }
	}
    } else {
	if { [ llength $tlist ] < $nc } {
	    set errormessage "Not Enough t-values specified in list"
	    $fl Delete
	    return 0
	}
	for { set i 0 } { $i < $nc } { incr i } {
	    if { $reciprocal == 0 } {
		$fl SetComponent $i 0 [ lindex $tlist $i ]
	    } else {
		$fl SetComponent $i 0 [ expr 1.0/[ lindex $tlist $i ] ]
	    }
	}
    }

    puts -nonewline stdout "TES (reciprocal=$reciprocal) = "
    for { set i 0 } { $i < $nc } { incr i } {
	puts -nonewline stdout "$i->[ $fl GetComponent $i 0 ] "
    }
    puts stdout ""
    
    set fit [ vtkpxLogExponentialFit  [ pxvtable::vnewobj ]]
    $fit SetInput [ $image_in GetImage ] 
    $fit SetEchoTrain $fl
    $fit SetMaxT2Value $maxt2
    $fit SetIntensityThreshold $threshold

    $this SetFilterCallbacks $fit "Mono-exponential fitting"
    $fit Update

    set densityimage [ $OutputsArray(density_image) GetObject ] 
    $densityimage  ShallowCopyImage [ $fit GetDensityMap ]
    $densityimage  CopyImageHeader  [ $image_in GetImageHeader ]

    set outimage [ $OutputsArray(output_image) GetObject ]
    if { $t2 > 0 } { 
	$outimage  ShallowCopyImage [ $fit GetOutput ]
    } else {
	$outimage  ShallowCopyImage [ $fit GetR2Map ]
    }

    puts -nonewline stdout "Density range [ [ [ [ $densityimage GetImage ] GetPointData ] GetScalars ] GetRange ]\t"
    puts stdout "T2/R2 range [ [ [ [ $outimage GetImage ] GetPointData ] GetScalars ] GetRange ]"

    $outimage CopyImageHeader [ $image_in GetImageHeader ]
    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0


    $fit Delete

    $fl Delete

    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_exponentialfitimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_exponentialfitimage [pxvtable::vnewobj]]
    $alg MainFunction 
}





