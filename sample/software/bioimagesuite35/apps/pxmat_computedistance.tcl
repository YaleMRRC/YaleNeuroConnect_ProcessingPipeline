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





# 	$Id: pxmat_computedistance.tcl,v 1.1 2004/01/15 15:11:37 xenios Exp xenios $	





if { [ llength $argv ] < 6 } { 
    set scriptname [ file tail $argv0 ]
    puts stdout "\n$scriptname is part of BioImage Suite (www.bioimagesuite.org)\n"
    puts stdout "$scriptname is a script that prints the distance between two surfaces after a transformation"
    puts stdout "Syntax: $scriptname  pointset1.vtk  pointset2.vtk transform.grd matchmode temperature numpoints"
    puts stdout "\t\t matchmode = 0 = ICP, 1=Mixture, 2=RPM (Use 0 for nearest neighbor), temperature is used if matchmode !=0, number of points = number of points to use for distance computation"
    puts stdout "\n"
    exit
}

lappend auto_path [ file dirname [ info script ]]; package require pxappscommon

vtkPolyDataReader p1
p1 SetFileName [ lindex $argv 0 ]
p1 Update

vtkPolyDataReader p2
p2 SetFileName [ lindex $argv 1 ]
p2 Update

set sur(0) [ p1 GetOutput ]
set nam(0) [ lindex $argv 0 ]
set sur(1) [ p2 GetOutput ]
set nam(1) [ lindex $argv 1 ]

vtkpxTransformationUtil ut
set trn [ ut LoadAbstractTransform [ lindex $argv 2 ]]

set matchmode [ lindex $argv 3 ]
set temperature [ lindex $argv 4 ]
set numpoints [ lindex $argv 5 ]


puts stdout "Surface 1  [ file tail $nam(0) ] pts = [ $sur(0) GetNumberOfPoints ]"
puts stdout "Surface 2  [ file tail $nam(1) ] pts = [ $sur(1) GetNumberOfPoints ]"
puts stdout "Transformation loaded from [ lindex $argv 2 ],  [ $trn GetClassName ]"
puts stdout "MatchMode= $matchmode, Temperature = $temperature, numpoints=$numpoints"

vtkpxRPMCorrespondenceFinder rpm

rpm SetSource $sur(0)
rpm SetTarget $sur(1)
rpm DebugOn
rpm SetMaximumNumberOfLandmarks $numpoints
rpm SetMatchMode $matchmode
rpm SetUseLabels 1
rpm SetFastThreshold 3.0
#rpm SetNoScaling 1
rpm Initialize

rpm WarpAndUpdateCorrespondence $trn $temperature
rpm ComputeDistance "[ file tail [ lindex $argv 2 ] ] \t $matchmode"

exit 0



