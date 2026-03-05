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





# 	$Id: pxmat_surfaceinfo.tcl,v 1.2 2004/01/15 15:07:37 xenios Exp xenios $	




if { [ llength $argv ] < 1 } { 
    set scriptname [ file tail $argv0 ]
    puts stdout "\n$scriptname is part of BioImage Suite (www.bioimagesuite.org)\n"
    puts stdout "$scriptname is a script that prints information about .vtk surface files"
    puts stdout "Syntax: $scriptname \[ surface1 \] \[ surface2 \] ..."
    puts stdout "\n"
    exit
}


lappend auto_path [ file dirname [ info script ]]; package require pxappscommon
set num [  llength $argv ]

set ana [ vtkPolyDataReader [ pxvtable::vnewobj ]]

for { set i 0 } { $i < $num } { incr i } {
    $ana SetFileName [ lindex $argv $i ]
    $ana Modified
    $ana Update

    set sur [ $ana GetOutput ]

    set np [ $sur GetNumberOfPoints ]
    set nc [ $sur GetNumberOfCells  ]
    set bd [ $sur GetBounds ]

    set scalardata "no point scalars"
    set celldata   "no cell  scalars"
    set testscal 0

    catch {
	set scal [ [  $sur GetPointData ] GetScalars ]
	set ns [ $scal GetNumberOfTuples ]
	set nc [ $scal GetNumberOfComponents ]
	set range [ $scal GetRange ]
	set scalardata  "$ns point-scalars ($nc components) range=[lindex $range 0 ]:[lindex $range 1 ]"
	set testscal 1
    }

    catch {
	set scal [ [  $sur GetCellData ] GetScalars ]
	set ns [ $scal GetNumberOfTuples ]
	set nc [ $scal GetNumberOfComponents ]
	set range [ $scal GetRange ]
	set celldata  "$ns cell-scalars ($nc components) range=[lindex $range 0 ]:[lindex $range 1 ]"
	set testscal 0
    }

    puts stdout "[ lindex $argv $i ] : $np points $nc cells (bounds=$bd) ($scalardata,$celldata)"

    set histline ""
    if { $testscal > 0 } {
	set thrFilter [ vtkThresholdPoints [ pxvtable::vnewobj ]]
	for { set j [ lindex $range 0 ] } { $j <= [ lindex $range 1 ]} { incr j } {
	    $thrFilter SetInput $sur
	    $thrFilter ThresholdBetween [ expr $j-0.1 ] [ expr $j+0.1 ]
	    $thrFilter Update
	    set histline "$histline \t $j \t [ [ $thrFilter GetOutput ] GetNumberOfPoints ]\n"
	}
	$thrFilter Delete 
	puts stdout $histline
    }
}

$ana Delete
exit 0

