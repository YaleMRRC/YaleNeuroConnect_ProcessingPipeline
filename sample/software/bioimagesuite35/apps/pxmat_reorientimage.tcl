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






# 	$Id: pxmat_reorientimage.tcl,v 1.1 2004/01/15 15:08:25 xenios Exp xenios $	





if { [ llength $argv ] < 3 } { 
    set scriptname [ file tail $argv0 ]
    puts stdout "\n$scriptname is part of BioImage Suite (www.bioimagesuite.org)\n"
    puts stdout "$scriptname  is a script that reorients an image to a given orientation"
    puts stdout "Syntax : $scriptname input_image  output_image output_orientation"
    puts stdout "\t\t output_orientation = 0 axial 1 coronal 2 sagittal"
    puts stdout "\n"
    exit
}

lappend auto_path [ file dirname [ info script ]]; package require pxappscommon
set orientlist [ list "axial" "coronal" "sagittal" "other" ]

set reference     [ lindex $argv 0 ]
set outname       [ lindex $argv 1 ]
set output_orientation  [ lindex $argv 2 ]

if { $output_orientation < 1 } {
    set output_orientation 0 
} elseif { $output_orientation >= 2 } {
    set output_orientation 2 
} else { 
    set output_orientation 1
}

set ana1 [ vtkpxAnalyzeImageSource [ pxvtable::vnewobj ] ]
$ana1 Load $reference

set inori [ $ana1 GetOrientation ]
if { $inori <= 0 } { 
    set inori 0 
} elseif { $inori >= 2 } {
    set inori 2
} else {
    set inori 1
}

puts stdout "Loaded image [ [ $ana1 GetImageHeader ] GetHeaderDescription 0 ]"

set img [ vtkImageData [ pxvtable::vnewobj ]]

set ut [ vtkpxUtil [ pxvtable::vnewobj ]]
$ut ReOrientImage $img [ $ana1 GetOutput ] [ $ana1 GetOrientation ] $output_orientation

set head [ $ana1 GetImageHeader ]
$head SetOrientation $output_orientation


set anaw [ vtkpxAnalyzeImageWriter [ pxvtable::vnewobj ]]
$anaw SetInput $img
$anaw SetImageHeader $head
$anaw Save $outname

set head [ $anaw GetImageHeader ]

puts stdout "\nOutput saved  [ $head GetHeaderDescription 0 ]"
 
$anaw Delete
$ana1 Delete
$ut Delete

exit

