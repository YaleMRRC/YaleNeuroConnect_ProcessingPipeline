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






set argc [llength $argv]
if { $argc != 2 } {
    puts stderr "Usage  pxroitoroi.tcl  descript.txt outdirectory\n"
    exit
}

set textfile [ lindex $argv 0 ]
set outdir [ lindex $argv 1 ]

set outlist ""

if { [ file exists $textfile ] ==0 || [ file readable $textfile ] == 0 } {
    puts stderr "Bad Input File $textfile"
    exit
}
lappend auto_path [ file dirname [ info script ]]; package require pxappscommon
wm withdraw .

catch { file mkdir  $outdir }


# ---------------------------------------------------------------------------------

proc SaveSingle { img name value outdir } {
    set thresholdF  [  vtkImageThreshold [ pxvtable::vnewobj ] ]
    $thresholdF ThresholdBetween  [ expr $value -0.1 ] [ expr  $value  +0.1 ]
    $thresholdF SetInValue    68
    $thresholdF SetOutValue 0
    $thresholdF ReplaceOutOn
    $thresholdF ReplaceInOn
    $thresholdF SetInput $img
    $thresholdF Update

    if { [ string length $name ] > 17 } {
	set name2 [ string range $name 0 16 ]
    } else {
	set name2 $name
    }

    set done 0
    while { $done == 0 } {
	set ind [ string first " " $name2 ]
	if { $ind == - 1 } {
	    set ind [ string first "\t" $name2 ]
	}
	if { $ind >= 0 } {
	    set name2 [ string replace $name2 $ind $ind "_" ]
	} else {
	    set done 1
	}
    }

    set head [ vtkbisImageHeader [ pxvtable::vnewobj ]]
    $head CreateHeader [ $thresholdF GetOutput ] 0
    $head SetVOIValue 68
    $head SetDBName   $name2

    set anaw [ vtkpxAnalyzeImageWriter [ pxvtable::vnewobj ]]
    $anaw SetInput [ $thresholdF GetOutput ]
    $anaw SetImageHeader $head

    set fname [ file join $outdir $name2 ].hdr

    $anaw Save $fname

    puts stderr "Thresholding for $name between  [ expr $value -0.1 ] and [ expr  $value  +0.1 ] --> $fname"
    $anaw Delete
    $head Delete
    $thresholdF Delete
    return [ file tail [ file rootname $fname ]]
}

# ---------------------------------------------------------------------------------

set fileid [open $textfile r]
set inlist ""
while { [ gets $fileid line ] >=0 } {
    lappend inlist $line
}
close $fileid


set ananame [ file rootname $textfile].hdr

set anar [ vtkpxAnalyzeImageSource [ pxvtable::vnewobj ]]
$anar Load $ananame

set inpimg [ $anar GetOutput ]
puts stderr "Loaded [ [ $anar GetImageHeader ] GetHeaderDescription 0 ]"
puts stderr "inlist = $inlist"

for { set i 0 } { $i < [ llength $inlist ] } { incr i } {

    set name [ lindex $inlist $i ]
#    puts stderr "Examining $name"
    if { [ string first "\[" $name ] == -1 } {
	# Not a comment
	set ind [ string first " " $name ]
	if { $ind == -1 } {
	    set ind [ string first "\t" $name ]
	}
	set len [ string length $line ]
#	puts stderr "ind = $ind"
	if { $ind > 0 } {
	    set val [ string range $name 0 [ expr $ind -1 ] ]
	    set name2 [ string trim [ string range $name $ind end ] ]
#	    puts stderr "Value = $val, name = $name2"
	    set newname [ SaveSingle $inpimg $name2 $val $outdir ]
	    lappend outlist $newname
	}
    }
}

puts stderr "outlist = $outlist"

set name [ file join $outdir [ file rootname [ file tail $textfile ] ].vois ]
set fout [ open $name w ]
for { set i 0 } { $i < [ llength $outlist ] } { incr i } {
    puts $fout [ lindex $outlist $i ]
}
close $fout
puts stderr "Saved output in $name "

exit
    
