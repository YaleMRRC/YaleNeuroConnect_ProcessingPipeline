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




if { $argc < 1 } {
    puts stdout "\n\n"
    puts stdout "$argv0 matrix1.nii.gz matrix2.hdr ..\n";
}

set f [ file join [ file dirname [ info script ]] pxappscommon.tcl ]
if { [ file exists $f  ] } {
    puts stdout "$f exists"
    lappend auto_path [ file dirname [ info script ]];
}
package require pxappscommon

set numc [ llength $argv ]
puts stdout "\n ----------- Beginning matrix to text for $numc files ------------------------"
set ana [ vtkpxAnalyzeImageSource New ]
 
for { set f 0 } { $f < $numc } { incr f } {
   
    set fname [ lindex $argv $f ]
    $ana SetForceStandardOrientation 0
    $ana Load $fname
    set dim [ [ $ana GetOutput ] GetDimensions ]
    
    puts stdout "Loaded $fname dim=$dim"
    if { [ lindex $dim 2 ] !=1 || [ lindex $dim 0 ] != [ lindex $dim 1 ] } {
	puts "Not a 2D matrix file"
    } else {
	set img [ $ana GetOutput ]
	set oname [ file rootname $fname ]
	if { [ file extension $oname ]==".nii" } {
	    set oname [ file rootname $oname ]
	}
	set oname "${oname}.txt"
	set fout [ open $oname w ]
	puts $fout "#ConnectionFile\n[lindex $dim 0]"
	set np [ lindex $dim 0 ]
	
	for { set j 0 } { $j < $np } { incr j } {
	    for { set i 0 } { $i < $np } { incr i } {
		puts -nonewline $fout [ format "%.2f " [ $img GetScalarComponentAsDouble $i $j 0 0 ] ]
	    }
	    puts $fout ""
	}
	close $fout
	puts stdout "\t\t Output saved in $oname ([ file size $oname ])"
    }
}
$ana Delete
exit

    

