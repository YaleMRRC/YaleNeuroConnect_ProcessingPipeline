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





# 	$Id: pxtclruncommand.tcl,v 1.1 2004/03/12 14:49:02 xenios Exp xenios $	

package provide pxtclruncommand 1.0

package require  labelframe 1.0
package require  pxtclutil  1.0
package require  pxvtable   1.0
package require  Itcl       


itcl::class pxtclruncommand {

    protected variable basewidget 0
    public variable callback 0
    public variable progresscallback 0
    public variable message "Algorithm Completed"
    protected variable lasttitle ""

    protected common thisparam

    constructor { } { 
	set thisparam($this,command) "ls -l"
    }

    public method GetThisPointer { } { return $this }
    public method Initialize { widget inside standalone }
    public method Run  { args } 
    public method Log  { } 
    public method Stop { } 
    public method List { }
    public method Hide { } {wm withdraw $basewidget}
    public method Show { } {wm deiconify $basewidget}
    public method SetCallback { func } { set callback $func }
    public method SetProgressCallback { func } { set progresscallback $func }

    public method SetCommand { cmd } {
	set thisparam($this,command) $cmd 
    }
}

itcl::body pxtclruncommand::Initialize { widget inside standalone } {

    set basewidget $widget

    if { $inside == 0 } {
	toplevel $basewidget
	if { $standalone == 0 } {
	    wm withdraw $basewidget
	}
    } else {
	frame $basewidget 
    }

    set w $basewidget

    frame $w.c; frame $w.exec
    pack $w.c    -side top -fill x -expand f
    pack $w.exec -side top -fill x -expand f

    entry $w.c.command -textvariable [ itcl::scope thisparam($this,command) ] -width 50 -relief sunken 
    pack $w.c.command  -side top -fill x -expand t -padx 5

    set w [LabelFrame:create $basewidget.log -text "Log" -expand true -fill both]
    pack $basewidget.log -side top -fill both -expand t

    set cmd "text $w.log -width 80 -height 10  -borderwidth 2 -relief raised -setgrid true  -yscrollcommand {$w.scroll set}"
    eval $cmd
    set thisparam($this,gui_log) $w.log
    
    set cmd "scrollbar $w.scroll -command { $w.log yview} "
    eval $cmd

    pack $w.scroll -side right -fill y
    pack $w.log -side left -fill both -expand true
    
    frame $basewidget.buttonbar  -bg white -bd 4
    pack $basewidget.buttonbar -side bottom -fill x -expand f
    set w  $basewidget.buttonbar 

    set thisparam($this,gui_runbutton) [ button $w.run   -text "Run!" ]
    eval "$thisparam($this,gui_runbutton) configure  -command { $this Run  } "
    set thisparam($this,gui_stopbutton) [ button $w.stop  -text "Stop!" -state disabled ]
    eval "$thisparam($this,gui_stopbutton) configure -command { $this Stop  } "

    if { $standalone == 0 } {
	set cmd "button $w.close -text Close -command { wm withdraw $basewidget }";  eval $cmd
    } else {
	set cmd "button $w.close -text Close -command { wm withdraw $basewidget }";  eval $cmd
	#set cmd "button $w.close -text Exit -command { pxtkexit }";  eval $cmd
    }


    
    pack $w.run $w.stop  $w.close -fill x -side left -expand t -padx 20
    
    set thisparam($this,gui_closebutton) $w.close 


    eval "wm protocol $basewidget WM_DELETE_WINDOW { wm withdraw $basewidget }"
    wm title $basewidget "External Command Console"
    return $basewidget
}


itcl::body pxtclruncommand::Run { args } {
	

    if [catch {  set thisparam($this,gui_input) [ open "| $thisparam($this,command) 2>@1 " ] } ] {
	pxtclutil::Warning "Error, please check all the parameters.\n"
	$thisparam($this,gui_log) insert end "thisparam($this,gui_input)\n"
    } else {
	$thisparam($this,gui_log) delete 1.0 end
	fileevent $thisparam($this,gui_input) readable [ list $this Log ]
    }
    $thisparam($this,gui_stopbutton) configure -state normal
    $thisparam($this,gui_runbutton) configure -state disabled



    if { [ llength $args ] > 0 } {
	set lasttitle [ lindex $args 0 ]
    } else {
	set lasttitle $thisparam($this,command)
	if { [ string length $lasttitle ] > 25 } {
	    set lasttitle "[ string range $lasttitle 0 25 ]..."
	}   
    }
    wm title $basewidget "Console :: $lasttitle "
    
}

itcl::body pxtclruncommand::Log {  } {
	

    if [eof $thisparam($this,gui_input)] {
	Stop
	wm title $basewidget "Console :: $lasttitle COMPLETED"
 	if { $callback !=0  } { 
	    eval $callback
	    set progresscallback 0
	} else {
	    ::pxtclutil::Info $message
	}
    } else {
	gets $thisparam($this,gui_input) line
	$thisparam($this,gui_log) insert end "$line\n"
	$thisparam($this,gui_log) see end
 	if { $progresscallback !=0  } { 
	    eval "$progresscallback $line"
	} 
    }
}

# Stop the program and fix up the button

itcl::body pxtclruncommand::Stop {  } {
	
    catch {close $thisparam($this,gui_input)}
    $thisparam($this,gui_stopbutton) configure -state disabled
    $thisparam($this,gui_runbutton) configure -state normal
    wm title $basewidget "Console :: $lasttitle STOPPED"
}



