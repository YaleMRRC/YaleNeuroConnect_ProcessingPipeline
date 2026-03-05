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


puts stdout "This is obsolete"
puts stdout "Use bis_computecorrelations.tcl instead"
exit

set num $argc 

if { $num < 2 } {
    set scriptname [ file tail $argv0 ]
    puts stdout "\n$scriptname is part of BioImage Suite (www.bioimagesuite.org)\n"
    puts stdout "Usage: $scriptname 4DImage measuresfile"

    puts stdout "Measures File Example\n------------------------"
    puts stdout "\#Individual Subject Measures"
    puts stdout "\#Number of Subjects\n4"
    puts stdout "\#Number of Measures\n2"
    puts stdout "\#Data (either , or tab-delimited)"
    puts stdout "Subject IQ Weight"
    puts stdout "1314	100 100"
    puts stdout "1361	110 200"
    puts stdout "1518	120 200"
    puts stdout "2205	130 121"
    puts stdout "------------------------"
    exit 0
}


lappend auto_path [ file dirname [ info script ]]; package require pxappscommon
package require bis_seedcorrelation 1.0


proc TextFileToImage { textfile } {

    set fileid [open $textfile r]
	
    gets $fileid line
    set line [ string trim $line ]
    
    if { [ string compare $line "#Individual Subject Measures" ] != 0 } {
	puts stderr "Bad Data File\n"
	close $fileid
	exit
    }
    
    set numsubjects 1
    set nummeasures 1
    gets $fileid line;     gets $fileid numsubjects
    gets $fileid line;     gets $fileid nummeasures
    
    puts stdout "Reading textfile = $textfile, numsubjects=$numsubjects, nummeasures=$nummeasures"

    gets $fileid line

    set img [ vtkImageData New ]
    $img SetDimensions $nummeasures 1 1
    $img SetNumberOfScalarComponents $numsubjects
    $img SetScalarTypeToFloat
    $img AllocateScalars
    
    set numcols [ expr $nummeasures +1 ]
    gets $fileid line

    set subjectlist ""
    set measurelist ""

    set ln [ string trim $line ]
    regsub -all " +" $ln "\t" ln
    regsub -all "\t" $ln "|" ln
    regsub -all ","  $ln "|" ln
    set tmp  [ split $ln | ]	
    if { [ llength $tmp ] != $numcols } {
	puts stderr "Not Engough Measure names specified (numcols=$numcols) ($ln,$tmp)"
	close $fileid
	exit
    }
    for { set i 1 } { $i < $numcols } { incr i } {
	lappend measurelist [ lindex $tmp $i ]
    }


    for { set i 0 } { $i < $numsubjects } { incr i } {
	gets $fileid line
	set ln [ string trim $line ]
	regsub -all " +" $ln "\t" ln
	regsub -all "\t" $ln "|" ln
	regsub -all ","  $ln "|" ln
	set tmp  [ split $ln | ]	
	#	puts stdout "ln=$ln, tmp=$tmp"
	if { [ llength $tmp ] != $numcols } {
	    puts stderr "Bad Line for subject [ expr $i +1 ], number of columns = [ llength $tmp ] != $numcols "
	    close $fileid
	    exit
	}
	for { set j 1 } { $j < $numcols } { incr j } {
	    $img SetScalarComponentFromDouble [ expr $j -1 ] 0 0 $i [ expr double([ lindex $tmp $j ]) ]
	}
	lappend subjectlist [ lindex $tmp 0 ]
    }
    close $fileid

    puts stdout "Verifying ...."

    puts -nonewline stdout " \t :"
    for { set j 0 } { $j < $nummeasures } { incr j } {
	puts -nonewline stdout " [ lindex $measurelist $j ]\t"
    }
    puts stdout ""

    for { set i 0 } { $i < $numsubjects } { incr i } {
	puts -nonewline stdout "Subject [ lindex $subjectlist $i ] \t"
	for { set j 0 } { $j < $nummeasures } { incr j } {
	    puts -nonewline stdout "[ $img GetScalarComponentAsDouble $j 0 0 $i ]\t"
	}
	puts stdout ""
    }


    set ref [ pxitclimage \#auto ]
    $ref ShallowCopyImage $img
    $img Delete
    return [ list $ref $measurelist ]
}

# ---------------------------------------------------------------------------------------------------------

set rlist [ TextFileToImage [ lindex $argv 1 ] ]
if { $rlist == 0 } {
    exit
}

set roimean [ lindex $rlist 0 ]
set measurelist [ lindex $rlist 1 ]



set ref [ pxitclimage \#auto ]
$ref Load [ lindex $argv 0 ]
puts stdout "\n\n4D Image loaded = [ $ref GetDescription ]\n"

if { [ llength $argv ] > 2 } {
    set threshold [ lindex $argv 2 ]
} else {
    set threshold 0.05
}


set corr [ bis_seedcorrelation \#auto ]
$corr InitializeFromContainer 0 
$corr SetInput $ref
$corr SetSecondInput $roimean
$corr SetOptionValue usemask 0
$corr Execute


set outname [ lindex $argv 0 ]
set ext [ file extension $outname ]
set outname [ file rootname $outname ]
if { $ext == ".gz" } {
    set outname [ file rootname $outname ]
}

set tmp [ pxitclimage \#auto ]

set outimage [ $corr GetOutput ]

for { set i 0 } { $i < [ [ $outimage GetImage ] GetNumberOfScalarComponents ] } { incr i } {

    set extr [ vtkImageExtractComponents New ]
    $extr SetInput [ $outimage GetImage ]
    $extr SetComponents $i
    $extr Update

    $tmp ShallowCopyImage [ $extr GetOutput ]
    $tmp CopyImageHeader  [ $outimage GetImageHeader ]
    set name "${outname}_[ lindex $measurelist $i ].nii.gz"
    set ok [ $tmp Save $name ]
    if { $ok > 0 } {
	puts stdout "\t\t Correlation with [ lindex $measurelist $i ] saved in $name"
    }
    $extr Delete
}


itcl::delete obj $corr
itcl::delete obj $roimean
itcl::delete obj $ref
itcl::delete obj $tmp

exit






