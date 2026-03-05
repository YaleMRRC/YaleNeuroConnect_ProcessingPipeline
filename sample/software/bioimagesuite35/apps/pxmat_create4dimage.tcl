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





if { [ llength $argv ] < 2 } { 
    set scriptname [ file tail $argv0 ]
    puts stdout "\n$scriptname is part of BioImage Suite (www.bioimagesuite.org)\n"

    puts stdout "$scriptname is a script that combines a number of 3D volumes into 4D image (all images in analyze.hdr .img format)"
    puts stdout "Syntax: $scriptname image1 image2 ... imagen"
    puts stdout "\t\t output = image1_4D.hdr"
    puts stdout "\n"
    exit
}

lappend auto_path [ file dirname [ info script ]]; package require pxappscommon

set appnd [ vtkImageAppendComponents [ pxvtable::vnewobj ]]

for { set i 0 } { $i < [ llength $argv ] } { incr  i } {

    set ana($i) [ vtkpxAnalyzeImageSource [ pxvtable::vnewobj ]]
    $ana($i) Load [ lindex $argv $i ]
    puts stdout "Loaded image [ expr $i +1 ] :  [ $ana($i) GetFilePrefix ] dim [ [ $ana($i) GetOutput ] GetDimensions ] [ [ $ana($i) GetOutput ] GetNumberOfScalarComponents ]"
    $appnd AddInput [ $ana($i) GetOutput ]
}

$appnd Update

set outname [ ::pxappscommon::GenOutputName [ lindex $argv 0 ] "4D" ]

set anaw [ vtkpxAnalyzeImageWriter [ pxvtable::vnewobj ]]
$anaw SetInput [ $appnd GetOutput ]
$anaw SetImageHeader [ $ana(0) GetImageHeader ]
$anaw Save $outname

set img [ $appnd GetOutput ]

puts stdout "\n Output [ [ $anaw GetImageHeader ] GetHeaderDescription 0 ]"

$anaw Delete
$appnd Delete
for { set i 0 } { $i < [ llength $argv ] } { incr  i } {
    $ana($i) Delete
}

exit



