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


# 	$Id: pxmat_thresholdimage.tcl,v 1.1 2004/01/15 15:07:18 xenios Exp xenios $	





if { [ llength $argv ] < 2 } { 
    set scriptname [ file tail $argv0 ]
    puts stdout "\n$scriptname is part of BioImage Suite (www.bioimagesuite.org)\n"
    puts stdout "$scriptname is a script that thresholds an image to generate a binary output using a specific threshold"
    puts stdout "Syntax: $scriptname threshold  input_image1 input_image2 ..... "
    puts stdout "\t\t Output: 100=above threshold, 0=below"
    puts stdout "\t\t Output filenames are generated from input filenames with the addition of \"_binary\" "
    puts stdout "\n"
    exit
}

lappend auto_path [ file dirname [ info script ]]; package require pxappscommon

set numc [ llength $argv ]
set value       [ lindex $argv 0 ]


puts stdout "numc = $numc value=$value"

for { set i 1 } { $i < $numc } { incr i } {

    set ana1 [ vtkpxAnalyzeImageSource [ pxvtable::vnewobj ] ]
    set anaw [ vtkpxAnalyzeImageWriter [ pxvtable::vnewobj ] ]

    set reference [ lindex $argv $i ]
    $ana1 Load $reference
    set spa   [ [ $ana1 GetOutput ] GetSpacing ]

    set range [ [ [ [ $ana1 GetOutput ] GetPointData ] GetScalars ] GetRange ]

    puts stdout "Loaded image $i [ $ana1 GetFilePrefix ] dim [ [ $ana1 GetOutput ] GetDimensions ]  [ format "%.2fx%.2fx%.2f mm" [ lindex $spa 0 ] [ lindex $spa 1 ] [ lindex $spa 2  ]] range = $range"

    set threshold  [ vtkImageThreshold [ pxvtable::vnewobj ]  ]
    $threshold SetInput [ $ana1 GetOutput ]
    $threshold SetInValue  100.0
    $threshold SetOutValue   0.0
    $threshold ReplaceInOn
    $threshold ReplaceOutOn
    $threshold ThresholdBetween $value [ expr 0.001 + [ lindex $range 1 ] ]
    $threshold SetOutputScalarTypeToShort
    $threshold Update

    $anaw SetInput [ $threshold GetOutput ]
    $anaw SetImageHeader [ $ana1 GetImageHeader ]
    
    set outfname [ ::pxappscommon::GenOutputName $reference "binary" ]
    $anaw Save $outfname
    puts stdout "\t Thresholded image saved in [ $anaw GetFileName ] dimensions [ [ $threshold GetOutput ] GetDimensions ]\n"
    $threshold Delete
 
    $anaw Delete
    $ana1 Delete
}

exit

