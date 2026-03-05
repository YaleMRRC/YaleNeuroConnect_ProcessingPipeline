#!/bin/sh
# the next line restarts using wish \
    exec vtk "$0" "$@"

#BIOIMAGESUITE_LICENSE  ---------------------------------------------------------------------------------
#BIOIMAGESUITE_LICENSE  This file is part of the BioImage Suite Software Package.
#BIOIMAGESUITE_LICENSE  
#BIOIMAGESUITE_LICENSE  X. Papademetris, M. Jackowski, R.T. Constable, and L.H  Staib. 
#BIOIMAGESUITE_LICENSE  BioImage Suite: An integrated medical image analysis suite, Section
#BIOIMAGESUITE_LICENSE  of Bioimaging Sciences, Dept. of Diagnostic Radiology, Yale School of
#BIOIMAGESUITE_LICENSE  Medicine, http://www.bioimagesuite.org.
#BIOIMAGESUITE_LICENSE  
#BIOIMAGESUITE_LICENSE  All rights reserved. This file may not be edited/copied/redistributed
#BIOIMAGESUITE_LICENSE  without the explicit permission of the authors.
#BIOIMAGESUITE_LICENSE  
#BIOIMAGESUITE_LICENSE  -----------------------------------------------------------------------------------

set num $argc 

if { $num < 4 } {
    set scriptname [ file tail $argv0 ]
    puts stdout "\n$scriptname is part of BioImage Suite (www.bioimagesuite.org)\n"
    puts stdout "Usage: $scriptname REF INPUT FSLMAT OUTNAME (optional)MODE "
    exit 0
}

if { [ file exists [ lindex $argv 0 ] ] == 0 } {
    puts stdout "File: [ lindex $argv 0 ] does not exist"
    exit 0
}

if { [ file exists [ lindex $argv 1 ] ] == 0 } {
    puts stdout "File: [ lindex $argv 1 ] does not exist"
    exit 0
}

if { [ file exists [ lindex $argv 2 ] ] == 0 } {
    puts stdout "File: [ lindex $argv 2 ] does not exist"
    exit 0
}

set mode 0
if { $num == 5 } {
    set mode [ lindex $argv 4 ]
}
#mode=0 both anat and func are LPS (BIS standard)
#mode=1 anat is LPS (BIS standard) and func is RAS (FSL standard)
#mode=2 anat is RAS (FSL standard) and func is LPS (BIS standard)
#mode=3 both anat and func are RAS (FSL standard)

lappend auto_path [ file dirname [ info script ]]; 

package require pxappscommon 1.0
package require vtkpxcontrib 1.0
package require pxvtable 1.0
package require pxitclimage  1.0

set img1 [ pxitclimage \#auto ]
$img1 Load [ lindex $argv 0 ]
set spa1 [ [ $img1 GetObject ] GetSpacing ]
set dim1 [ [ $img1 GetObject ] GetDimensions ]

set img2 [ pxitclimage \#auto ]
$img2 Load [ lindex $argv 1 ]
set spa2 [ [ $img2 GetObject ] GetSpacing ]
set dim2 [ [ $img2 GetObject ] GetDimensions ]

set ut [ vtkpxTransformationUtil [ pxvtable::vnewobj ] ]    
set xform2 [ vtkMatrix4x4 [ pxvtable::vnewobj ] ]
 $ut LoadMatrix  $xform2 [ lindex $argv 2 ] 

#xform1=flipx based on ref
#xform2=bbr output
#xform3=flipx based on input

set xform1 [ vtkMatrix4x4 [ pxvtable::vnewobj ] ]
$xform1 Identity

if { $mode==1 } {
    $xform1 SetElement 0 0 -1
    $xform1 SetElement 0 3 [ expr [ lindex $spa1 0 ] * [ lindex $dim1 0 ] - [ lindex $spa1 0 ] ]
    $xform1 SetElement 1 1 -1
    $xform1 SetElement 1 3 [ expr [ lindex $spa1 1 ] * [ lindex $dim1 1 ] - [ lindex $spa1 1 ] ]
    $xform1 SetElement 2 2 -1
    $xform1 SetElement 2 3 [ expr [ lindex $spa1 2 ] * [ lindex $dim1 2 ] - [ lindex $spa1 2 ] ]
} elseif { $mode==0 } {
    $xform1 SetElement 0 0 -1
    $xform1 SetElement 0 3 [ expr [ lindex $spa1 0 ] * [ lindex $dim1 0 ] - [ lindex $spa1 0 ] ]
} elseif { $mode==2 } {
    $xform1 SetElement 1 1 -1
    $xform1 SetElement 1 3 [ expr [ lindex $spa1 1 ] * [ lindex $dim1 1 ] - [ lindex $spa1 1 ] ]
}

set xform3 [ vtkMatrix4x4 [ pxvtable::vnewobj ] ]
$xform3 Identity

if { $mode >2 } {
    $xform3 SetElement 0 0 -1
    $xform3 SetElement 0 3 [ expr [ lindex $spa2 0 ] * [ lindex $dim2 0 ] - [ lindex $spa2 0 ] ]
    $xform3 SetElement 1 1 -1
    $xform3 SetElement 1 3 [ expr [ lindex $spa2 1 ] * [ lindex $dim2 1 ] - [ lindex $spa2 1 ] ]
    $xform3 SetElement 2 2 -1
    $xform3 SetElement 2 3 [ expr [ lindex $spa2 2 ] * [ lindex $dim2 2 ] - [ lindex $spa2 2 ] ]
} else {
    $xform3 SetElement 0 0 -1
    $xform3 SetElement 0 3 [ expr [ lindex $spa2 0 ] * [ lindex $dim2 0 ] - [ lindex $spa2 0 ] ]
}

set out [ vtkMatrix4x4 [ pxvtable::vnewobj ] ]
$out Identity
$out Multiply4x4 $xform1 $xform2 $out
$out Multiply4x4 $out $xform3 $out

$out Invert

$ut SaveMatrix $xform1 xform1.matr
$ut SaveMatrix $xform2 xform2.matr
$ut SaveMatrix $xform3 xform3.matr

$ut SaveMatrix $out [ lindex $argv 3 ]

exit





