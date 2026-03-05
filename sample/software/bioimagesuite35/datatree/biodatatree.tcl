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

# 	$Id: pxitclbrainregister.tcl,v 1.3 2003/02/26 16:29:58 papad Exp $	

# This is the main application

lappend auto_path [file dirname [info script]]
package require pxitclchellypackages 1.0
package require dsitcltree 1.0
package require pxitclbrainregister 1.0
package require pxitclbraintreegadget 1.0



wm withdraw .
set breg [ pxitclbrainregister \#auto 0 ]
$breg configure -enable_multi2gadget 0
$breg configure -enable_multigadget 0
$breg configure -enable_csigadget 1
$breg configure -enable_fmrigadget 0
$breg configure -enable_electrodecontrol 1
$breg configure -enable_electrodecontrol2 1
$breg configure -enable_vvlink 1
$breg configure -donotcreatemenu 1
$breg configure -appname "BioImage Suite::Datatree Tool"

$breg Initialize .[pxvtable::vnewobj ]
    
[ [ $breg GetOrthoViewer ref ] GetViewer ] SetEnableRendering 1
[ [ $breg GetOrthoViewer ref ] GetViewer ] UpdateDisplay
[ [ $breg GetOrthoViewer trn ] GetViewer ] SetEnableRendering 1
[ [ $breg GetOrthoViewer trn ] GetViewer ] UpdateDisplay

set viewer1 [ $breg GetOrthoViewer ref ]
set viewer2 [ $breg GetOrthoViewer trn ]

set numberoftools 1

set  surgerytool [ [  pxitclsurgerygadget \#auto $viewer1 $viewer2 ] GetThisPointer ]
set  basewidget  [ $breg GetBaseWidget ]

wm geometry $basewidget  930x700

#get the usenew flag 
#if an input of -new is given as the first arg
#use the new datatree

if { [lindex $argv 0] == "-new" } {
    set usenew 1 
    set inputTree [lindex $argv 1]
} else { 
    set usenew 0
    set inputTree [lindex $argv 0]
}

$surgerytool configure -electrodecontrol  [ $breg cget -electrode_control  ]
$surgerytool configure -electrodecontrol2 [ $breg cget -electrode_control2 ]
$surgerytool configure -useNew $usenew
$surgerytool Initialize $basewidget

set chellyMain [  [ $surgerytool cget -chellyMain ] GetThisPointer ]

set toolmenu [ $chellyMain cget -toolsmenu ]
$toolmenu add separator
$breg CreateChildMenus 0 0  $toolmenu


set mb2 [ $breg cget -functionalmenu ]

if { $numberoftools > 1 } {
    set  surgerytool2 [ [  pxitclsurgerygadget \#auto $viewer1 $viewer2 ] GetThisPointer ]
    $surgerytool2 configure -electrodecontrol [ $breg cget -electrode_control ]
    $surgerytool2 configure -overlaycontrol   [ $breg cget -overlaytool ]
    $surgerytool2     Initialize $basewidget.[pxvtable::vnewobj ]
}

$breg HideViewers

set argc [llength $argv]

if { $argc > 0 } {
    if { [ file exist $inputTree ] } { 
	$chellyMain mdLoadTree $inputTree 
    } else {
	puts "Cannot load $inputTree. File does not exist"
    }
}

update idletasks

