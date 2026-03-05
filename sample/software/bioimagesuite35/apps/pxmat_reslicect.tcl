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







# 	$Id: pxmat_reslicect.tcl,v 1.1 2004/01/15 15:07:53 xenios Exp xenios $	

if { [ llength $argv ] < 3 } { 
    puts stdout "pxmat_reslicect is a script that reslices an image (typically ct) to have proper uniformly thick slices"
    puts stdout "\npxmat_reslicect.tcl reference_image zlevels spacing\n"
    puts stdout "\nNote: zlevels is the name of a text file that contains the z-coordinates of each slice one number per line"
    exit
}

lappend auto_path [ file dirname [ info script ]]; package require pxappscommon

set inputname       [ lindex $argv 0 ]
set outname         "[ file root $inputname  ]_fixed"
set zlevels         [ lindex $argv 1 ]
set spacing         [ lindex $argv 2 ]

set ana1 [ vtkpxAnalyzeImageSource [ pxvtable::vnewobj ]]
$ana1 Load $inputname

set d [ lindex [ [ $ana1 GetOutput ] GetDimensions ] 2 ]
set zlev [ vtkFloatArray [ pxvtable::vnewobj ]]
$zlev SetNumberOfTuples $d

set fileid [open $zlevels r]

set zlist ""

for { set i 0 } { $i < $d } { incr i } {
    gets $fileid line
    lappend zlist $line
}
close $fileid

set sortlist [ lsort -real $zlist ]

puts stderr "Sorting from ( $zlist) to ($sortlist)"

set nt [ llength $sortlist ]

for { set i 0 } { $i < $nt } { incr i } {
    
    set line [ lindex $sortlist $i ]
    if { $i == 0 } {
	set offset $line
    }
    $zlev SetComponent $i 0 [ expr ($line-$offset) ]
    puts stdout "Z-coordinate for slice $i = [ $zlev GetComponent $i 0 ]  ($line)"
}


set recon [ vtkpxImageCorrectNonUniformZ [ pxvtable::vnewobj ]]
$recon SetInput [ $ana1 GetOutput ]
$recon SetSpacing $spacing
$recon SetZLevels $zlev
$recon Update

set anaw [ vtkpxAnalyzeImageWriter [ pxvtable::vnewobj ]]
$anaw SetInput [ $recon GetOutput ]
$anaw SetImageHeader [ $ana1 GetImageHeader ]
$anaw Save $outname

puts stdout "Saved in [ $anaw GetFileName ] dimensions [ [ $recon GetOutput ] GetDimensions ]"
 
$anaw Delete
$recon Delete
$ana1 Delete
$zlev Delete


exit

