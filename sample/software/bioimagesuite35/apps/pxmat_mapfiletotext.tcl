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




if { $argc < 2 } {
    puts stdout "\n\n"
    puts stdout "$argv0 original_map.vtk map.txt\n";
}

set f [ file join [ file dirname [ info script ]] pxappscommon.tcl ]
if { [ file exists $f  ] } {
    puts stdout "$f exists"
    lappend auto_path [ file dirname [ info script ]];
}
package require pxappscommon


set r [ vtkPolyDataReader New ]
$r SetFileName [ lindex $argv 0 ]
$r Update

set poly [ $r GetOutput ]
set np [ $poly GetNumberOfPoints ]
set dat [ [ $poly GetPointData ] GetScalars ]
set nc [ $dat GetNumberOfComponents ]

puts stdout "Loaded [ lindex $argv 0 ] np=$np, nc=$nc"

set oname [ lindex $argv 1 ]
set fout [ open $oname w ]
puts $fout "#MapFile\n$np\n$nc"
puts $fout "#MNI_X MNI_Y MNI_Z attrib1 ... attribN"
for { set i 0 } { $i < $np } { incr i } {
    set pt [ $poly GetPoint $i ]
    set mnix [ expr (180 -  [ lindex $pt 0 ])-90 ]
    set mniy [ expr (216 -  [ lindex $pt 1 ])-126 ]
    set mniz [ expr [ lindex $pt 2 ]-72 ]

    puts -nonewline $fout [ format "%.1f %.1f %.1f " $mnix $mniy $mniz ]
    for { set j 0 } { $j < $nc } { incr j } {
	puts -nonewline $fout [ format "%.0f " [ $dat GetComponent $i $j ] ]
    }
    puts $fout ""
}
close $fout
puts stdout "Output saved in $oname ([ file size $oname ])"
exit

    

