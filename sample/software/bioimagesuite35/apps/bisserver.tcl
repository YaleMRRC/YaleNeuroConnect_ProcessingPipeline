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




if { [ llength $argv ] < 1 } { 
    set scriptname [ file tail $argv0 ]
    puts stdout "\n$scriptname is part of BioImage Suite (www.bioimagesuite.org)\n"
    puts stdout "$scriptname is a test OpenIGTLink test client that receives points\n"
    puts stdout "Syntax: $scriptname port"
    puts stdout "\n"
    exit
}

lappend auto_path [ file dirname [ info script ]]; package require pxappscommon

set cursor_xform [ vtkTransform [ pxvtable::vnewobj ]]
set current_image [ vtkImageData [ pxvtable::vnewobj ]]
set port   [ lindex $argv 0 ]
set igtlserver 0
set igtllasttransformtime 0
set igtllastimagetime 0


# -------------------------------------------------------------------------------------
proc ServerCallbackHandleData { mode } {

    global igtlserver
    global igtllasttransformtime
    global igtllastimagetime
    global cursor_xform
    global current_image

    set status 0

    if { $mode == 0 } {
	set tr [ $igtlserver GetLastReceivedTransform ]

	$cursor_xform Identity;
	$cursor_xform Concatenate $tr

	set tx [ $tr GetPosition ]

	set cursor_x [ expr double([ lindex $tx 0 ])]
	set cursor_y [ expr double([ lindex $tx 1 ])]
	set cursor_z [ expr double([ lindex $tx 2 ])]
	set pointstatus  [ format "(%.2f %.2f %.2f)" $cursor_x $cursor_y $cursor_z ]
	set status 1
	set igtllasttransformtime  [ $igtlserver GetLastReceivedTransformTime ] 
	puts stdout "Received point $pointstatus"
    } elseif { $mode ==1 } {
	$current_image ShallowCopy  [ $igtlserver GetLastReceivedImage ]
	set imagestatus  "[ $current_image GetDimensions ], [ $current_image GetSpacing ]"
	puts stdout "Received image $imagestatus"
	set igtllastimagetime  [ $igtlserver GetLastReceivedImageTime ]
	set status 1
    }

    return $status
    
}
# ---------------------------------------------------------------------
proc ServerCallback { } {
    
    global igtlserver
    global igtllasttransformtime
    global igtllastimagetime


    if { $igtllastimagetime < [ $igtlserver GetLastReceivedImageTime ] } {
	 ServerCallbackHandleData 1
    }
    
    if { $igtllasttransformtime < [ $igtlserver GetLastReceivedTransformTime ] } {
	 ServerCallbackHandleData 0
    }
}



# ---------------------------------------------------------------------
proc ServerEventLoop { } {

    global igtlserver
    global igtllasttransformtime
    global igtllastimagetime
    global port


    set con [ $igtlserver GetIsServerConnected ]
    set act [ $igtlserver GetIsServerActive    ]

    if { $con == 1 } {
	set st " **** STATUS: Server connected"
    } elseif { $act ==1 } {
	set st "**** STATUS: Server listening Port=$port"
    } else {
	if { [ $igtlserver GetThreadActive ] == 0 } {
	    puts stderr "Connection closed ... exiting\n"
	    exit
	}
    }
    
    if { $st != "" } {
	set serverstatus "$st (img=$igtllastimagetime, tr=$igtllasttransformtime)"
	#	puts stdout "$serverstatus"
    }

    set dl 1
    # If needed start this ....
    if { $con == 1 && $act == 1 } {
	$igtlserver BeginReceivingDataInThread
	ServerCallback
    }

    after $dl ServerEventLoop
    return     
}

# ---------------------------------------------------------------------

proc CreateServer { } { 

    global igtlserver
    global igtllasttransformtime
    global igtllastimagetime
    global port
    

    set igtlserver [ vtkpxOpenIGTLinkServer [ pxvtable::vnewobj ]]
    set ok [ $igtlserver InitializeConnection $port ]

    if { $ok == 0 } {
	puts stderr "Failed to Create OpenIGTLink Server on port $port"
	exit
    } else {
	puts stdout "Server Initialized on $port" 
    }

    while { [ $igtlserver GetThreadActive ] == 0 } { 
	puts stderr "Waiting for thread to become active"
    }


    set igtllasttransformtime      [ $igtlserver GetLastReceivedTransformTime ] 
    set igtllastimagetime          [ $igtlserver GetLastReceivedImageTime ]
    ServerEventLoop
}


CreateServer


vwait forever

