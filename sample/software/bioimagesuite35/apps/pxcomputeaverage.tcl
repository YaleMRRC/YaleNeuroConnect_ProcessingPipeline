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

set imglist ""
set output  ""


set argc [llength $argv]
if { $argc < 3 } {
    set scriptname [ file tail $argv0 ]
    puts stderr "\n$scriptname is part of BioImage Suite (www.bioimagesuite.org)\n"
    puts stderr "$scriptname is a script that computes the mean and standard deviation of a set of images"
    puts stderr "Syntax: $scriptname output_stem image1 image2 .... \n"
    exit
}

lappend auto_path [ file dirname [ info script ]]; package require pxappscommon

    

set outputstem [ file root [ lindex $argv 0 ]]

# --------------------------------------------------------------------------------------------------------

proc TestImages {  } {

    global argv

    for { set i 1 } { $i < [ llength $argv ] } { incr i } {

	set refimgname [ lindex $argv $i ]
	set a "[ file root $refimgname ].hdr"
	set b "[ file root $refimgname ].img"
	set ok1 [ file exists $a ] ;   set sz1 -1 ; catch { set sz1 [ file size $a ] }
	set ok2 [ file exists $b ] ;   set sz2 -1 ; catch { set sz2 [ file size $b ] }
	if { $ok2 ==0 } {
	    set b "[ file root $refimgname ].img.gz"
	    set ok2 [ file exists $b ] ;   set sz2 -1 ; catch { set sz2 [ file size $b ] }
	}

	if { $ok1 > 0 && $ok2 > 0 } {
	    puts stderr "+++++ Image $i  $a,[file tail $b ] ($sz1,$sz2)  ok"
	} else {
	    puts stderr "\n*********** Missing Image $a,$b ($sz1,$sz2)"
	    exit
	}
    }
}

TestImages 



set combo [  vtkpxAverageImages [ pxvtable::vnewobj ]]
$combo SetMedian 0
$combo ComputeStandardDeviationOn
$combo IgnoreFlagOff

set imageheader [ vtkbisImageHeader [ pxvtable::vnewobj ]]

for { set i 1 } { $i < [ llength $argv ] } { incr i } {

    set ana [ vtkpxAnalyzeImageSource [ pxvtable::vnewobj ]]
    set fname [ lindex $argv $i ]
    $ana Load $fname
    puts stderr "++++ Image $i Loaded from $fname ( [ [ $ana GetOutput ] GetDimensions ])"

    if { $i == 1 } {
	set orientation [ $ana GetOrientation ]
	$imageheader CopyHeader [ $ana GetHeader ]
    }


    $combo AddInput [ $ana GetOutput ]

    $ana Delete
}

$combo  Update
set outname  ${outputstem}_mean.hdr
set outnames  ${outputstem}_stdev.hdr

set anaw [ vtkpxAnalyzeImageWriter [ pxvtable::vnewobj ]]    
$anaw SetCompression 0
$anaw SetInput [ $combo GetOutput ]
$anaw SetImageHeader $imageheader
$anaw Save $outname

puts stderr "\n++++ Mean saved in $outname"
    
$anaw SetInput [ $combo GetOutputStandardDeviation ]
$anaw Save $outnames

puts stderr "++++ Standard Deviation saved in $outnames\n"
$anaw Delete
$combo Delete
$imageheader Delete
exit

