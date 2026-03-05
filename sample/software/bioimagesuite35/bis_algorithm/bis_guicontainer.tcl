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

package provide bis_guicontainer 1.0
package require bis_algorithm 1.0


itcl::class bis_guicontainer {

    inherit bis_algorithm

    constructor { } {	$this InitializeGUIContainer  }

    # Create Input/Output GUI Controls for Objects in standalone mode
    protected method InitializeGUIContainer { }

    # Create GUI Stuff etc.
    public method CreateGUI { parent { callafter 0 } { callbefore 0 } }
    public    method DelayedCreateGUI   { }
    protected method CreateContainedAlgorithmsGUIs { nt }

    # Invokation Stuff
    protected    variable fullyinitialized 0
    protected    variable buttonbar 0


    # Method to add logo label to something 
    public method AddToMenuButton { mb args}
    public method ShowWindow { args }
    public method HideWindow { }
    public method SetTitle { title }
    
    # Method to create embedded controls -- nt = notebook to add tab in
    public method CreateInputOutputControl { nt } { }
    protected method CreateMainNotebook { name } 

    public method TabCommand { } { }
    protected method InitializeComponents {  }
    protected method AddComponentsToMenuButton { mb }


    protected variable componentnamelist ""
    protected variable componentlist ""
    protected variable extratablist  ""
    protected variable dualImageList [ list ]

}




itcl::body bis_guicontainer::InitializeGUIContainer { } {

    PrintDebug "bis_guicontainer::Initialize" 

    set scriptname bis_guicontainer
    set category "Graphical-User-Interface-Module"
    set description "Abstract Clss for Containing a variety of algorithms."
    set backwardcompatibility "Attempt to maintain compatibility with controls as expected in pxitclbaseimageviewer.tcl. "
    set authors "xenophon.papademetris@yale.edu."

    $this AddDefaultOptions
}
#------------------------------------------------------------------------------------------
::itcl::body bis_guicontainer::InitializeComponents {  } {

    set n [ llength $componentnamelist ]
    for { set i 0 } { $i < $n } { incr i } {
	
	set ln [ lindex $componentnamelist $i ]

	if { $ln !=0 && [ llength $ln ] == 1  } {
	    eval "package require $ln"
	    set alg [ [ $ln \#auto ] GetThisPointer ]
	    $alg InitializeFromContainer [ $this GetThisPointer ]
	    lappend componentlist $alg
	}
    }
}


#------------------------------------------------------------------------------------------
::itcl::body bis_guicontainer::AddComponentsToMenuButton { mb} {


    set l [ llength $componentlist ]
    set ln [ llength $componentnamelist ]
    set index 0
    set cascindex 0

    set pnt [ $this GetThisPointer ]

    set spl [  split $pnt ":" ]
    set pnt [ lindex $spl [ expr [ llength $spl ] -1 ] ]
    #    puts stderr "To $pnt from $spl"
    set current $mb


    for { set i 0 } { $i < $ln } { incr i } {
	set tp [ lindex $componentnamelist $i ]	
	if { [ llength $tp ] > 1  } {
	    set mname $mb.${pnt}${cascindex}
	    set newm [ menu $mname -tearoff 0  ] 
	    incr cascindex
	    $mb add cascade -underline [ lindex $tp 0 ] -label [ lindex $tp 1] -menu $newm
	    set current $newm
	} elseif { $tp == 0 } {
	    eval "$mb add separator"
	    set current $mb
	} elseif { $index < $l } {
	    set alg [ lindex $componentlist $index ]
	    set n [ $alg GetGUIName ]
	    eval "$current add command -command {$this ShowWindow \"$n\" \"$alg\" } -label \"$n\" "
	    incr index
	}
    }
}


#------------------------------------------------------------------------------------------

::itcl::body bis_guicontainer::AddToMenuButton { mb args} {
    

    for { set i 0 } { $i < [ llength $extratablist ] } { incr i } {
	set n [ lindex $extratablist $i ]
	eval "$mb add command -command {$this ShowWindow \"$n\"  } -label \"$n\" "
    }
    if { [ llength $extratablist ] > 0 } {
	$mb add separator
    }
    $this AddComponentsToMenuButton $mb

} 



::itcl::body bis_guicontainer::CreateGUI { basew { callafter 0 } { callbefore 0 } } {

    if { $fullyinitialized == 1 } {
	return
    }

    set callbackbefore $callbefore
    set callbackafter  $callafter
    set progressbar($this) 0
    set progress_lab($this) "Status"
    set progress_val($this) 0

    set basewidget $basew
    set fullyinitialized 0
    $this InitializeComponents
}

::itcl::body bis_guicontainer::DelayedCreateGUI { } {


    if { $fullyinitialized == 1 } {
	return 1
    }

    if { $basewidget == 0 } {
	return 0
    }

    set tp [ toplevel $basewidget ];  wm withdraw $tp
    eval "wm protocol $basewidget WM_DELETE_WINDOW { wm withdraw $basewidget  }"


    set buttonbar [ frame $basewidget.bt ]
    set bbt [ frame $basewidget.bt2 -bg black -height 5 ]
    

    pack $buttonbar $bbt -side bottom -expand false -fill x 
    
    eval "button $buttonbar.close   -text Close -command { wm withdraw $basewidget }"
    pack $buttonbar.close -side right

    set nt [ $this CreateMainNotebook  $basewidget.nt ]
    set maintabnotebook $nt
    pack $nt -side top -expand true -fill both
    update idletasks

    $this CreateInputOutputControl $nt
    $this CreateContainedAlgorithmsGUIs $nt

    update idletasks
    set canvas [ [ $nt component tabset ] component canvas ]
    #    set l [ AddLogoLabel $canvas ]
    #    pack $l -side bottom -expand false -fill x



    set fullyinitialized 1
    return 1
}
# -----------------------------------------------------------------------------
::itcl::body bis_guicontainer::CreateMainNotebook { name } {

    set nt [ iwidgets::tabnotebook $name -tabpos w  -margin 2 -backdrop gray -raiseselect true -width 500]
    return $nt
}
# -----------------------------------------------------------------------------
::itcl::body bis_guicontainer::CreateContainedAlgorithmsGUIs { nt } {

    set l [ llength $componentlist ]
    for { set i 0 } { $i < $l } { incr i } {
	set alg [ lindex $componentlist $i ]
	
	set n [ $alg GetGUIName ]

	set w [ $nt add -label $n -command [ itcl::code $this TabCommand ] ]	
	
	set isdual 0 ; catch { set isdual [ $alg IsDualImage ] }
	if { $isdual } { 
	    lappend dualImageList $alg 
	}
	
	$alg SetGUIMode managed
	$alg CreateGUI $w
    }

}
# -----------------------------------------------------------------------------


::itcl::body bis_guicontainer::ShowWindow { args } {

    if { $basewidget == 0 } { 
	return 
    }

    if { $fullyinitialized == 0 } {
	PrintDebug "From Show Window Calling DelayedCreateGUI $fullyinitialized"
	$this DelayedCreateGUI
    }
  
    if { $maintabnotebook !=0 && [ llength $args ] > 0 } {
	$maintabnotebook view [ lindex $args 0 ]
    }



    catch  {
	if { [ winfo ismapped $basewidget ] == 1 } {
	    wm withdraw $basewidget
	}
	wm deiconify $basewidget
    }
    return $basewidget
}
# ----------------------------------------------------------
::itcl::body bis_guicontainer::HideWindow { } {
    catch { wm withdraw $basewidget }
}
# ----------------------------------------------------------
::itcl::body bis_guicontainer::SetTitle { title } {
    catch {  wm title $basewidget $title }
}
# ----------------------------------------------------------

