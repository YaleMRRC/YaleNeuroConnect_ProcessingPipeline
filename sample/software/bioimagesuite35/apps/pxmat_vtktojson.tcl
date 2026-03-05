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
    puts stdout "\n This program converts vtk surfaces to three.js json format \n\n"
    puts stdout "$argv0 original.vtk output.json\n";
}

set f [ file join [ file dirname [ info script ]] pxappscommon.tcl ]
if { [ file exists $f  ] } {
    puts stdout "$f exists"
    lappend auto_path [ file dirname [ info script ]];
}
package require pxappscommon

set oname [ lindex $argv 1 ]
if { [ file extension $oname ] !=".json"  } {
    set oname "${oname}.json"
}

set surutil [ vtkpxSurfaceUtil New ]
set cmap [ vtkLookupTable New ]
set numc 64
$surutil DefaultObjectMapLookupTable $cmap $numc 0 


set r [ vtkPolyDataReader New ]
$r SetFileName [ lindex $argv 0 ]
$r Update

set tri [ vtkTriangleFilter New ]
$tri SetInput [ $r GetOutput ]
$tri Update

set norm [ vtkPolyDataNormals New ]
$norm SplittingOff
$norm SetInput [ $tri GetOutput ]
$norm Update

set poly [ $norm GetOutput ]
set np [ $poly GetNumberOfPoints ]
set tri [ [ $poly GetPolys ] GetData ]
set npoly [ expr [ $tri GetNumberOfTuples ] /4 ]

set dat(1) [ [ $poly GetPointData ] GetScalars ]



set dat(2) [ [ $poly GetPointData ] GetNormals ]
set nc(1) 0
set nc(2) 0
catch { set nc(1) [ $dat(1) GetNumberOfComponents ] }
catch { set nc(2) [ $dat(2) GetNumberOfComponents ] }

puts stdout "Loaded [ lindex $argv 0 ] np=$np, nc=$nc(1) $nc(2)"



set fout [ open $oname w ]
puts $fout "\{"
puts $fout "\t\"metadata\": {"
puts $fout "\t \"formatVersion\" : 3"
#puts $fout "\t \"vertices\" : $np,"
#puts $fout "\t \"faces\" : $npoly,"
#puts $fout "\t \"uvs\" : 0,"
#puts $fout "\t \"materials\" : 0"
puts $fout "\t\},"
puts $fout "\t\"materials\": \[ \],"

puts $fout "\t\"uvs\": \[ \],"
puts -nonewline $fout "\t\"vertices\": \["

set a ""
#if { $np > 10 } { set np 10 }
for { set i 0 } { $i < $np } { incr i } {
    set pt [ $poly GetPoint $i ]
    puts -nonewline $fout [ format "%s%.1f,%.1f,%.1f" $a [ lindex $pt 0 ] [ lindex  $pt 1 ] [ lindex $pt 2 ] ]
    set a ","
}
puts $fout "\],";


set ignore 1
if { $nc(2) > 0 && $ignore==0} {
    set a ""
    puts -nonewline $fout "\t\"normals\": \[ "
    for { set i 0 } { $i < $np } { incr i } {
	set pt [ $dat(2) GetTuple3 $i ]
	puts -nonewline $fout [ format "%s%.2f,%.2f,%.2f" $a [ lindex $pt 0 ] [ lindex  $pt 1 ] [ lindex $pt 2 ] ]
	set a ","
    }
    puts $fout "\],";
}

set a ""
set docolors 1
if { $docolors > 0 } {
    puts -nonewline $fout "\t\"colors\": \[ "
    for { set i 0 } { $i < $numc } { incr i } {
	set v [ $cmap GetTableValue $i ]
	set r [ expr int([ lindex $v 0 ]*255.0) ]
	set g [ expr int([lindex $v 1 ]*255.0) ]
	set b [ expr int([lindex $v 2 ]*255.0) ]
	set cl [ expr $r * 65536+$g*256+$b ]
#	puts "Color $i -> $v -> $r,$g,$b -> $cl"
	puts -nonewline $fout [ format "%s%.0f" $a $cl ]
	set a ","
    }
    puts $fout "\],";
}
    

set a ""
puts -nonewline $fout "\t\"faces\": \["
set index 0
for { set j 0 } { $j < $npoly  } { incr j } {
    set c0 [ $tri GetComponent $index 0 ]
    set c1 [ $tri GetComponent [ expr $index+1 ] 0 ]
    set c2 [ $tri GetComponent [ expr $index+2 ] 0 ]
    set c3 [ $tri GetComponent [ expr $index+3 ] 0 ]
    set index [ expr $index +4 ]
#    set b [ format "%s 64,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f" $a $c1 $c2 $c3 $c1 $c1 $c2 $c3 ]
    if { $nc(1) == 1 && $nc(2)==3 } {
	set ind [ expr int($c1) ]
	set c4  [ expr int([ $dat(1) GetComponent $ind 0 ]) % 12 ]
#	puts "c4 = $c4, $ind"
	set b [ format "%s 64,%.0f,%.0f,%.0f, %.0f" $a $c1 $c2 $c3  $c4]
    } else {
	set b [ format "%s 0,%.0f,%.0f,%.0f" $a $c1 $c2 $c3  ]
    }
    puts -nonewline $fout $b
    if { [ expr $j % 10000] ==0 } {
	puts "j=$j b=$b"
    }
    
    set a ","
}
puts $fout "\]";
puts $fout "}\n";


close $fout
puts stdout "Output saved in $oname ([ file size $oname ])"
exit		      
									 
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

exit

    

