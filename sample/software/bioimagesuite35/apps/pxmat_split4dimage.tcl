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





if { [ llength $argv ] < 1 } { 
    set scriptname [ file tail $argv0 ]
    puts stdout "\n$scriptname is part of BioImage Suite (www.bioimagesuite.org)\n"

    puts stdout "$scriptname is a script that extracts all 3D volumes from a  4D image"
    puts stdout "Syntax: $scriptname image \[ begin =1 \] \[ end = maximum number of frames \]"
    puts stdout "\t\t output = image_001.hdr .. image_002.hdr etc."
    puts stdout "\n"
    exit
}

lappend auto_path [ file dirname [ info script ]]; package require pxappscommon

# set outname  [ ::pxappscommon::GenOutputName [ lindex $argv 0 ] "" ] 
# puts "outname==$outname"
# set outname [ file root $outname ]
# puts "outnameroot==$outname"
# set extension .nii.gz

# exit

set ana [ vtkpxAnalyzeImageSource [ pxvtable::vnewobj ]]
$ana Load [ lindex $argv 0 ]

set img [ $ana GetOutput ]
set nf  [ $img GetNumberOfScalarComponents ]
set orient [ $ana GetOrientation ]

set beginframe 1
set endframe   $nf

if { [ llength $argv ] >1 } {
    set beginframe [ lindex $argv 1 ]
    if { $beginframe < 1 } { 
	set beginframe 1 
    } elseif { $beginframe > $nf } {
	set beginframe $nf
    }
}       

if { [ llength $argv ] >2 } {
    set endframe [ lindex $argv 2 ]
    if { $endframe < $beginframe } { 
	set endframe $beginframe 
    } elseif { $endframe > $nf } {
	set endframe $nf
    }
}       

puts stdout "\nOriginal Image Read [ [ $ana GetImageHeader ] GetHeaderDescription 0 ]\n\t frames=$nf, extracting $beginframe:$endframe\n"

set w [ vtkpxAnalyzeImageWriter [ pxvtable::vnewobj ]]
set extr [ vtkImageExtractComponents [ pxvtable::vnewobj ]]
$extr SetInput $img

set bg [ expr $beginframe -1 ]

for { set i $bg } { $i < $endframe } { incr i } {
    set j [ expr $i +1 ]
    $extr SetComponents $i
    $extr Modified
    $extr Update

    $w SetInput [ $extr GetOutput ]
    $w SetImageHeader [ $ana GetImageHeader ]
    $w Modified

    set numout [ format "%03d" [ expr $i +1 ] ]
    set fname  [ ::pxappscommon::GenOutputName [ lindex $argv 0 ] $numout  ]
    $w Save $fname
    puts stdout "\t Frame [ expr $i+1 ] saved in $fname [ [ $w GetImageHeader ] GetHeaderDescription -1 ]\n"
}

$w Delete
$extr Delete
$ana Delete

exit

