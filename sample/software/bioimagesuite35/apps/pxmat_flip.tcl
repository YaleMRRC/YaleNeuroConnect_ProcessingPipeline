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

if { $num < 2 } {
    set scriptname [ file tail $argv0 ]
    puts stdout "\n$scriptname is part of BioImage Suite (www.bioimagesuite.org)\n"
    puts stdout "Syntax: $scriptname direction file1 file2 file3 ..."
    puts stdout "\t\tDirection 0=x, 1=y, 2=z"
    puts stdout "\t\tOutput filenames are generated from input filenames with the addition of \"_flip\" "
    puts stdout "\n"
    exit 0
}


lappend auto_path [ file dirname [ info script ]]; package require pxappscommon


set direction [ lindex $argv 0 ]
if { $direction < 0 } {
    set direction 0
} elseif { $direction > 2 } {
    set direction 2
}



proc ResliceImage { imagein imageout } {
    		
    global direction

    set flip [ vtkImageFlip [ pxvtable::vnewobj ]]
    $flip SetFilteredAxis $direction
    $flip SetInput $imagein
    $flip PreserveImageExtentOn
    $flip Update
    $imageout ShallowCopy [ $flip GetOutput ]
    puts stdout "Dim=[$imageout GetDimensions], Vox size=[ $imageout GetSpacing ]"

    catch { $flip   Delete }
}


set ana [ vtkpxAnalyzeImageSource  [ pxvtable::vnewobj ]]

set axislist [ list x y z ]
set outsuffix  "flip[lindex $axislist $direction ]"

for { set i 1 } { $i < $num } { incr i } {
    
    puts stdout "----------------------------------------------"
    set name [ lindex $argv $i ]

    $ana Load $name
    set or [ $ana GetOrientation ]

    puts stdout "\nRead $name [ [ $ana GetOutput ] GetDimensions ] ori=$or "

    set outp [ vtkImageData [ pxvtable::vnewobj ]]
    ResliceImage [ $ana GetOutput ] $outp

    set ana2 [ vtkpxAnalyzeImageWriter [ pxvtable::vnewobj ]]

    $ana2 SetInput $outp
    $ana2 SetImageHeader [ $ana GetImageHeader ]

    set fname [ ::pxappscommon::GenOutputName $name $outsuffix ]
    $ana2 Save $fname

    puts stdout "Resliced $name to $fname\n"
    $ana2 Delete
    $outp Delete
}

$ana Delete

exit

