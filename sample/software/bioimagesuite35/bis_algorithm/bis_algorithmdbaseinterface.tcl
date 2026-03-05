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

package provide bis_algorithmdbaseinterface 1.0

package require Itcl
package require Iwidgets 
package require vtkpxcontrib  1.1

# This loads the database library
pxtclvtkpxcontrib::LoadLibraries { vtkbisDatabaseTCL }


itcl::class bis_algorithmdbaseinterface {
    private common    thisparam
    protected variable basewidget 0
    protected variable dbase      0
    protected variable connector  0
    protected variable algorithm  0
    protected variable algorithmname ""
    protected variable querybox   0
    protected variable dialogmode 0
    protected variable notebook   0

    
    constructor { } { $this Initialize }
    destructor  { }

    # This pointer
    public method GetThisPointer { } { return $this }

    # Algorithm Stuff
    public method SetAlgorithm { a } { }
    public method GetAlgorithm { } { return $algorithm }
    public method UpdateFromAlgorithm { } 

    # GUI Stuff
    public method Reset { { ask 0 } }
    public method CreateGUI { base { dlg 0 } }
    public method QueryEntryGUI { mode }
    public method AddEntryGUI { }
    public method HandleSelect { mode }
    public method ShowWindow { md }
    public method HideWindow { }
    public method PrintTable { }
    public method SetSQLDebugMode { }
    public method ClearTable { }

    # Initialize Code
    protected method Initialize { }
    
    # Public Methods for handling dbase
    public method Connect    { { sqlitefile "" } }
    public method Disconnect { }
    public method AddEntry { name description }
    public method FindPreset { psetname }

};

# -------------------------------------------------------------------------------------------
# Initialize 
# -------------------------------------------------------------------------------------------
itcl::body bis_algorithmdbaseinterface::Initialize { } {

    $this Reset 0
    set thisparam($this,algorithname) "Alg: None"
    set thisparam($this,dbasefilename) "Dbase: Not Connected"
    set thisparam($this,debugdbase)    0
    set thisparam($this,connected)     0
    $this Connect 
}
# -------------------------------------------------------------------------------------------

itcl::body bis_algorithmdbaseinterface::Reset { {  ask 0 } } {
    if { $ask == 1 } {
	set ok [ tk_messageBox -type yesno -message "Reseting filenames" -icon question ]
	if { $ok == "no" } { return }
    }

    if { $ask !=2 } {
	set thisparam($this,addname) ""
	set thisparam($this,adddesc) ""
    }

    set thisparam($this,queryname) ""
    set thisparam($this,querydesc) ""
    set thisparam($this,querydate) ""
    set thisparam($this,queryparam) ""

}

itcl::body bis_algorithmdbaseinterface::SetAlgorithm { a } { 

    set algorithm $a

    set tmp [ string range  [ $algorithm info class ] 2 end ]
    set algorithmname  $tmp
    set thisparam($this,algorithmname)  "Alg: [ $algorithm GetGUIName ] ($algorithmname)"


    if { $basewidget !=0 } {
	return [ $this QueryEntryGUI all ]
    }
    return 1

}

# -------------------------------------------------------------------------------------------
::itcl::body bis_algorithmdbaseinterface::UpdateFromAlgorithm { }  {

    set v [ $algorithm GetOptionValue "pset" ] 
    set thisparam($this,addname) ""
    set thisparam($this,adddesc) ""

    if { [ string length $v ] < 1 } {
	return
    }
    
    set l [ split $v "," ]

    set thisparam($this,addname) [ lindex $l 0 ]
    if { [ llength $v ] > 1 } {
	set thisparam($this,adddesc) [ lindex $l 1 ]
    }

}

# -------------------------------------------------------------------------------------------
#   GUI Stuff
# -------------------------------------------------------------------------------------------
::itcl::body bis_algorithmdbaseinterface::ShowWindow { md } {

    if { $dialogmode == 0 || $basewidget == 0 } {
	return 
    }


#    puts stderr "md=$md"
    if { $md == "store" } {
	set md 1
    } else {
	set md 0
    }
    $notebook view $md
    
    

    if { [ winfo ismapped $basewidget ] == 1 } {
	wm withdraw $basewidget
    }
    wm deiconify $basewidget
    return $basewidget
}
# ----------------------------------------------------------
::itcl::body bis_algorithmdbaseinterface::HideWindow { } {

    if { $dialogmode == 0 || $basewidget == 0 } { return }
    catch { wm withdraw $basewidget }
}
# ----------------------------------------------------------
itcl::body bis_algorithmdbaseinterface::CreateGUI { base { dlg 0 } } {

    if { $basewidget !=0 } {
	return $basewidget
    }


    if { $dlg == 1 } {
	set basewidget [ toplevel $base.[pxvtable::vnewobj ] ]
	wm withdraw $basewidget
	wm title $basewidget "Parameter Query Tool"
	wm geometry $basewidget 500x400
	set dialogmode 1
    } else {
	set basewidget $base
	set dialogmode 0
    }


    set nt [ iwidgets::tabnotebook $basewidget.[ pxvtable::vnewobj ]  -tabpos n ]
    set notebook $nt
    pack $nt -side top -expand true -fill both -pady 1
    # Page Query
    # ----------------------------------------------------------------------
    set page [ $nt add -label "Query Database"]
    
    iwidgets::entryfield $page.1 -labeltext "Preset Name:" -textvariable [ itcl::scope thisparam($this,queryname) ]
    iwidgets::entryfield $page.2 -labeltext "Description:" -textvariable [ itcl::scope thisparam($this,querydesc) ]
    iwidgets::entryfield $page.3 -labeltext "Date:" -textvariable [ itcl::scope thisparam($this,querydate) ]
    iwidgets::entryfield $page.4 -labeltext "Parameters:" -textvariable [ itcl::scope thisparam($this,queryparam) ]
    pack $page.1  $page.2 $page.3 $page.4 -side top -expand false -fill x
    iwidgets::Labeledwidget::alignlabels $page.1 $page.2 $page.3 $page.4
    
    iwidgets::buttonbox $page.btop 
    eval "$page.btop add querybtn -text \"Search for Param. Set\" -command { $this QueryEntryGUI search }"
    eval "$page.btop add showbtn  -text \"Show All\" -command { $this QueryEntryGUI all }"
    eval "$page.btop add clearbtn  -text \"Clear Entries\" -command { $this Reset 2 }"
    pack $page.btop -expand false -fill x -side top

    iwidgets::buttonbox $page.bb2
    pack $page.bb2 -side bottom -expand false -fill x -padx 10 -pady 2

    eval "$page.bb2 add 1 -text \" Select\"        -command  { $this HandleSelect 0 }"
    eval "$page.bb2 add 2 -text \" Set Algorithm\" -command  { $this HandleSelect 1 }"

    
    iwidgets::scrolledlistbox $page.slb -vscrollmode dynamic -selectmode single 
    pack $page.slb -expand yes -fill x -side top
    $page.slb insert 0 ""
    set querybox $page.slb

   
    $nt view "Query Database"


    # -------------------------------------------------------------------
    set page [ $nt add -label "Store Current Parameters"]
        
    
    label $page.0   -text "Please do not use commas \",\" as part of the name or the description" -bg black -fg white
    pack $page.0 -side top -expand false -fill x
    iwidgets::entryfield $page.name -labeltext "Preset Name:"  -textvariable [ itcl::scope thisparam($this,addname) ]
    iwidgets::entryfield $page.addr -labeltext "Description:" -textvariable [ itcl::scope thisparam($this,adddesc) ]
    pack $page.name $page.addr -side top -expand false -fill x
    iwidgets::Labeledwidget::alignlabels $page.name $page.addr
    iwidgets::buttonbox $page.bb 
    eval "$page.bb add OK -text \"Store Current Param. Set\" -command { $this AddEntryGUI }"
    pack $page.bb -expand false -fill x -side bottom


    # -------------------------------------------------------------------
    set bot [ $nt add -label "Debug"]

    frame $bot.1
    frame $bot.3
    entry $bot.1.1 -width 30  -textvariable [ itcl::scope thisparam($this,algorithmname) ] -relief sunken  -bg black -fg white 
    entry $bot.1.2 -width 30  -textvariable [ itcl::scope thisparam($this,dbasefilename) ] -relief sunken  -bg black -fg white 
    pack $bot.1 $bot.3 -side top -expand false -fill x
    pack $bot.1.1 $bot.1.2 -side top -expand true -fill x -padx 0

    eval "checkbutton $bot.3.1 -variable [ itcl::scope thisparam($this,debugdbase)  ] -text \"Debug SQL\" -command { $this SetSQLDebugMode }" 
    eval "button $bot.3.2 -text \"Show Table\" -command { $this PrintTable } -padx 5"
    eval "button $bot.3.3 -text \"Clear Table\" -command { $this ClearTable } -padx 5"
    pack $bot.3.1 $bot.3.2 $bot.3.3 -side left -expand false -fill x
    

    if { $algorithm !=0 } {
	 $this QueryEntryGUI all 
    }

    return $basewidget
}
# ------------------------- GUI Callbacks ---------------------------------
itcl::body bis_algorithmdbaseinterface::QueryEntryGUI { mode } {
    if { $basewidget == 0 } {	return 0  }
    if { $thisparam($this,connected) == 0 } {	return 0    }

    if { $mode == "all" } {
	set out [ $dbase QueryAll $algorithmname ]
	$this Reset 2
    } else {

	set p1 "%$thisparam($this,queryname)%"
	set p2 "%$thisparam($this,querydesc)%" 
	set p3 "%$thisparam($this,querydate)%"
	set p4 "%$thisparam($this,queryparam)%"

	set out [ $dbase SearchItem $algorithmname $p1 $p2 $p3 $p4 0 ]
    }

    $querybox delete 0 end 
    if { $out == "" } {
	return
    }

    set lst [ split $out "\n" ]
    for { set i 0 } { $i < [ llength $lst ] } { incr i } {
	if { $thisparam($this,debugdbase) > 0 } {
	    puts stdout "Item $i = *[lindex $lst $i ]*"
	}
	if { [ string length [ lindex $lst $i ] ] > 2 } {
	    $querybox insert end [ lindex $lst $i ]
	}
    }
}

itcl::body bis_algorithmdbaseinterface::AddEntryGUI { } {
    if { $basewidget == 0 } {	return 0  }

    if { $thisparam($this,addname) == "" } {
	tk_messageBox -type ok -message "Empty name" -title "Failed to Store Preset" -icon error
	return 0
    }

    if { $thisparam($this,adddesc) == "" } {
	set thisparam($this,adddesc) "none" 
    }

    return [ $this AddEntry  $thisparam($this,addname) $thisparam($this,adddesc) ]
}

itcl::body bis_algorithmdbaseinterface::HandleSelect { mode } {
    if { $basewidget == 0 } {	return 0  }

    set test [ $querybox getcurselection]

    set lst [ split $test "," ]
    set thisparam($this,queryname)  [ lindex $lst 1 ]
    set thisparam($this,querydesc)  [ lindex $lst 2 ]
    set thisparam($this,querydate)  [ lindex $lst 3 ]
    set thisparam($this,queryparam) [ lindex $lst 4 ]


    if { $mode == 1 } {
	$algorithm SetParametersFromString "[ lindex $lst 4 ]"
	$algorithm SetOptionValue "pset" "[ lindex $lst 1 ],[ lindex $lst 2 ]"
	$this UpdateFromAlgorithm
    }

}

# ------------------------- Non GUI Callbacks ---------------------------------
itcl::body bis_algorithmdbaseinterface::Connect    { { sqlitefile "" } } {

    if { $thisparam($this,connected) == 1 } {	return 0    }

    if { $sqlitefile == "" } {
	global env
	set fn ".bioimagesuite3"
	catch { set fn $env(BIODBASE) }
	set fn [ file join $env(HOME) $fn ]
    } else {
	set fn $sqlitefile
    }
    set connector [ vtkbisDatabase New ]
    $connector InitializeSQLite "$fn" 
    set ok [ $connector Connect ]

    if { $ok < 1 } {
	$connector Delete
	return 0
    }

    set thisparam($this,dbasefilename) "Dbase: $fn"
    if { $thisparam($this,debugdbase) > 0 } {
	$connector DebugOn
    } else {
	$connector DebugOff
    }
    set thisparam($this,connected) 1

    set dbase [ vtkbisAlgorithmTable New ]
    $dbase SetConnector $connector
    $dbase CreateTable
    return 1
}

itcl::body bis_algorithmdbaseinterface::Disconnect { } {

    if { $thisparam($this,connected) == 1 } {
	return 0
    }
    
    catch { $connector Disconnect }
    set thisparam($this,connected) 0
    set thisparam($this,dbasefilename) "Dbase: Not Connected"
}

itcl::body bis_algorithmdbaseinterface::AddEntry { name description } { 

    if { $thisparam($this,connected)  == 0 } {
	puts stderr "Not Connected to base"
	return 0
    }

    set p(1) $algorithmname
    set p(2) $name
    set p(3) $description
    set p(4) [  clock format [ clock seconds ] ]
    set p(5) [ $algorithm GetCommandLine paramset ]

    set txt [ $dbase SearchItem $p(1) $p(2) "" "" "" 1 ]
    if { [ string length $txt ] > 0 } {
	set ok [ tk_messageBox -type yesno -message "There is an existing preset with the same name ($name). Would you like to ovverride this?\n (Full text=$txt) " -icon question ]
	if { $ok == "no" } {
	    return 0
	} else {
	    $dbase DeleteItem $p(1) $p(2)
	}
    }

    for { set i 1 } { $i < 5 } { incr i } {
	#puts -nonewline stdout "$i\tMapping $p($i) to "
	regsub -all "," $p($i)  ";" p($i)
	#	puts stdout "to $p($i)"
    }

    $dbase AddItem $p(1) $p(2) $p(3) $p(4) $p(5)
    return [ $this QueryEntryGUI all  ]

}

itcl::body bis_algorithmdbaseinterface::FindPreset { psetname } {

    if { $thisparam($this,connected)  == 0 } {
	return 0
    }

    set out [ $dbase SearchItem $algorithmname $psetname "" "" ""   1 ]
    if { $out == "" } {
	return ""
    } 
    if { $thisparam($this,debugdbase) > 0 } {
	puts stderr "Search output = *$out*"
    }

    set lst [ split $out "\n" ]
    if { $thisparam($this,debugdbase) > 0 } {
	puts stdout "Returning $lst"
    }

    set elem [ split [ lindex $lst 0 ] "," ]
    if { $thisparam($this,debugdbase) > 0 } {
	puts stderr "Search elem = *$elem*"
    }
    
    set out [ lindex $elem 4 ]

    return $out
}

# --------------------------------------------------------------------

itcl::body bis_algorithmdbaseinterface::SetSQLDebugMode { } {

    if { $thisparam($this,connected)  == 0 } {
	return
    }
    
    if { $thisparam($this,debugdbase) > 0 } {
	$connector DebugOn
    } else {
	$connector DebugOff
    }
}
# --------------------------------------------------------------------
itcl::body bis_algorithmdbaseinterface::PrintTable { } {

    if { $thisparam($this,connected) == 0 } {	return 0    }

    set out [ $dbase QueryAll $algorithmname ]

    set lst [ split $out "\n" ]

    puts stdout "\n\n\n         Whole Table for $algorithmname \n"
    
    for { set i 0 } { $i < [ llength $lst ] } { incr i } {
	if { [ string length [ lindex $lst $i ] ] > 1 } {
	    puts stdout "$i \t *[ lindex $lst $i ]*"
	}
    }
    puts stdout "\n\n"
}

itcl::body bis_algorithmdbaseinterface::ClearTable { } {

    if { $thisparam($this,connected) == 0 } {	return 0    }

    set ok [ tk_messageBox -type yesno -message "Are you sure you want to delete all parameters for algorithm $algorithmname?" -icon question ]
    if { $ok == "no" } {
	return
    }

    $dbase DeleteAll $algorithmname
}

