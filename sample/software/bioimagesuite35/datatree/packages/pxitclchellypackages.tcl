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

package provide pxitclchellypackages 1.0

set dname [  file dirname [ info script ] ]
lappend auto_path $dname



set datatreebioimagesuitepath  [ file join [ file join [ file dirname [ info script ]] .. ] .. ]

if { [ file exists [ file join ${datatreebioimagesuitepath} [ file join base vtkpxcontrib.tcl ]] ] != 1 } {

    # Not in the source tree so try some options
    # if the environment variable BIOIMAGESUITEDIR is set it is used

    set datatreebioimagesuitepath /usr/local/bioimagesuite
    if { $tcl_platform(platform) == "windows" } { 
	set datatreebioimagesuitepath "c:/yale/bioimagesuite"
    }
    
    set fn ""
    catch { set fn $env(BIOIMAGESUITEDIR) }
    
    if { $fn != "" } {
	set datatreebioimagesuitepath $env(BIOIMAGESUITEDIR)
    }
}

if { [ file pathtype $datatreebioimagesuitepath ] == "relative" } {
    set  datatreebioimagesuitepath [ file join [ pwd ] $datatreebioimagesuitepath ]
    regsub -all  "/./" $datatreebioimagesuitepath "/" datatreebioimagesuitepath
}

#puts stderr "BioImage Suite Path=$datatreebioimagesuitepath"

lappend auto_path [ file join $datatreebioimagesuitepath base ]
lappend auto_path [ file join $datatreebioimagesuitepath main ]

unset dname
#unset datatreebioimagesuitepath



