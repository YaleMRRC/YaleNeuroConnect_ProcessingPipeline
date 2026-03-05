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

package provide pxitclobject 1.0

# 	$Id: pxitclobjectGUI.tcl,v 1.1 2002/08/03 13:36:49 papad Exp papad $	




package require  pxtclutil  1.0
package require Itcl
package require pxvtable 1.0

# --------------------------------------------------------------
#  abstract base GUI Class for pxitcltransform, pxitclimage etc.
# --------------------------------------------------------------
itcl::class pxitclobject {

    # --- begin variable def -----

    public variable filename  ""

    # --- end of variable def -----

    constructor { } {  }
    destructor  { } 


    # --- begin method def -----
    public method GetThisPointer { } { return $this }

    # Things that must be over-ridden by derived classes
    # --------------------------------------------------
    public method GetObject { } { return 0 }
    public method GetType { } { return "vtkObject" }
    public method GetFileName { } { return $filename }
    public method SetFileName { f } { $this configure -filename $f }
    public method GetDescription { } { return [ $this GetType ]}
    public method GetShortDescription { } { return [ $this GetType ]}
    public method UpdateStatus { }  { }
    public method Copy    { obj args } { }
    public method DeepCopy    { obj } { Copy $obj 1    }
    public method ShallowCopy { obj } { Copy $obj 0    }

    public method GetSize { } { return 0}

    # Essentially Release Memory
    public method Clear   { } { } 

    # Procedures to Load/Save 
    public method Load { args } { }
    public method Save { args } { }

    # Procedures to Add/Get comment
    public method AddComment { cmt } { } 
    public method GetComment {     } { return "no comment" } 
    public method CompareTo  { fname { thr 0.001 } } { 
	puts stdout "No test for this type of object -- $this to object from $fname ($thr)"
	return 0
    }
}


# --------------------------------------------------------------
#  abstract base GUI Class for pxitcltransformGUI pxitclimageGUI
# --------------------------------------------------------------

itcl::class pxitclobjectGUI {

    public    variable  itclobject 0
    protected variable  basewidget  0
    protected variable  initialized 0
    protected common    thisparam
    protected variable  owns_object 1
    public    variable  description Object
    public    variable  callback 0 
    public variable     buttonbar 0
    protected variable  numlines 3

    public variable  loadbutton 0
    public variable  savebutton 0
    public variable  clearbutton 0
    public variable  statusbar 0
    

    constructor { } {
	set thisparam($this,status) "vtkObject"
	set thisparam($this,shortfilename) "identity"
	set thisparam($this,descriptionbox) 0
    }

    destructor {	if { $owns_object == 1} {
	    catch { itcl::delete object $itclobject }
	}
    }

    public    method GetThisPointer { } { return $this }
    public    method GetObject { } { return $itclobject  }
    public    method Reset { } 
    public    method Initialize { basewidg } 
    public    method InitializeLite { basewidg args } 
    public    method Update { }
    public    method Info { }
    public    method LoadObject { } 
    public    method SaveObject { } 
    public    method ClearObject { } 

    public    method AddFunction { command name post }
    # -----------------------------------------
    # Function that must be overriden
    protected method CreateNewObject { } { puts stdout "Error!"}
    public    method SetObject { tr } { puts stdout "Error!" }

}
# ----------------------------------------------------------
itcl::body pxitclobjectGUI::Reset { } {

    if { $itclobject !=0 && $owns_transformation == 1} {
	itcl::delete object $itclobject
    }
    
    CreateNewObject
    set thisparam($this,shortfilename) [ $itclobject cget -filename ]
    set owns_object 1
    Update
}

itcl::body pxitclobjectGUI::Info { } {

    tk_messageBox -type ok -title "Object Info" -message  [ $itclobject GetDescription ] -parent $basewidget
}

itcl::body pxitclobjectGUI::Update { } {
    
    if { $thisparam($this,descriptionbox) !=0 } {

	set tbox $thisparam($this,descriptionbox)
	$tbox delete 1.0 end
	$tbox insert end [ $itclobject GetDescription ]
	$tbox see 1.0
    }
    set thisparam($this,shortfilename) [ file tail [ $itclobject cget -filename ]]
    set thisparam($this,classname) [ $itclobject GetType ]
    if { $basewidget !=0 } {
	set a [ $basewidget cget -labeltext ]
	if { $a != $description } {
	    $basewidget configure -labeltext  $description
	}
	if { $callback !=0 } {
	    eval $callback
	}
    }
}

itcl::body pxitclobjectGUI::LoadObject { } {
    $itclobject Load "" $description
    Update
}

itcl::body pxitclobjectGUI::SaveObject { } {
    $itclobject Save "" $description
    Update
}

itcl::body pxitclobjectGUI::ClearObject { } {
    $itclobject Clear
    Update
}


itcl::body pxitclobjectGUI::Initialize { basewidg } {

    if { $initialized == 1 } { 
	return $basewidget 
    }
    global tcl_platform

    set basewidget [  iwidgets::Labeledframe $basewidg -labelpos n -labeltext $description ]
    set base [ $basewidget childsite ]

    frame $base.mid

    if { $tcl_platform(platform) == "windows" } {
	set thisparam($this,descriptionbox) [ text $base.top -width 35 -height $numlines -borderwidth 2 -relief raised -font { fixed 8 }]
    } else {
	set thisparam($this,descriptionbox) [ text $base.top -width 35 -height $numlines -borderwidth 2 -relief raised -font { fixed 10 }]
    }
    
    $base.top configure -bg white -fg black

    iwidgets::entryfield $base.mid.1 -textvariable [ itcl::scope thisparam($this,shortfilename) ] -width 50 -labeltext "Nm:"
    iwidgets::entryfield $base.mid.2 -textvariable [ itcl::scope thisparam($this,classname) ] -width 10 -labeltext "St: "

    [ $base.mid.2 component entry  ] configure -bg white -fg black
    [ $base.mid.1 component entry  ] configure -bg white -fg black

    set statusbar $base.mid.2
    [ $base.mid.2  component entry ] configure -state disabled
    pack $base.mid.2 -side right -expand false 
    pack $base.mid.1 -side left -expand true -fill x
    
    set buttonbar [ frame $base.bot ]
    eval "button $buttonbar.0l -text Load -command { $this LoadObject }"
    set loadbutton $buttonbar.0l
    eval "button $buttonbar.0s -text Save -command { $this SaveObject }"
    set savebutton $buttonbar.0s
    eval "button $buttonbar.0cl -text Clear -command { $this ClearObject }"
    set clearbutton $buttonbar.0cl    
    pack  $buttonbar.0l $buttonbar.0s    -side left -fill x -expand f
    pack  $buttonbar.0cl   -side right -fill x -expand f

    pack  $base.mid $base.top $base.bot -side top -expand f -fill x -padx 5 -pady 2
    set initialized 1
    return $basewidget
}

itcl::body pxitclobjectGUI::InitializeLite { basewidg args } {

    if { $initialized == 1 } { 
	return $basewidget 
    }

    set packmode 0
    if { [ llength $args ] > 0 } {
	set packmode [ lindex $args 0 ] 
    }

    set basewidget [  iwidgets::Labeledframe $basewidg -labelpos n -labeltext $description ]
    set base [ $basewidget childsite ]
    pack $basewidg -side top -expand true -fill x

    frame $base.top; pack $base.top
    set buttonbar [ frame $base.bottom ]

    iwidgets::entryfield $base.top.1 -textvariable [ itcl::scope thisparam($this,shortfilename) ] -width 30 -labeltext ""
    [ $base.top.1 component entry ] configure -bg white -fg black
    
    if { $packmode > 2 } {
	iwidgets::entryfield $base.top.2 -textvariable [ itcl::scope thisparam($this,classname) ] -width 6 -labeltext "St: "
	[ $base.top.2  component entry ] configure -state disabled
	set packmode 2
	pack $base.top.2  -side right -expand false
    }
    pack $base.top.1  -side left -expand true -fill x 

    if { $packmode == 0 } {
	pack $buttonbar -side right -expand f -padx 0
	pack $base.top -side left -expand f -fill x
	eval "button $buttonbar.3 -text Load -command { $this LoadObject }"
	set loadbutton $buttonbar.3
	eval "button $buttonbar.4 -text Save -command { $this SaveObject }"
	set savebutton $buttonbar.4
	eval "button $buttonbar.45 -text Clear -command { $this ClearObject }"
	set clearbutton $buttonbar.45    

	eval "button $buttonbar.5 -text \"I\" -command { $this Info }"
	pack $buttonbar.3 $buttonbar.4 $buttonbar.45 $buttonbar.5 -side left -expand f 
    } elseif { $packmode == 1 } {
	pack $base.top $buttonbar -side top -expand true -fill x 
	eval "button $buttonbar.3 -text Load -command { $this LoadObject }"
	set loadbutton $buttonbar.3
	eval "button $buttonbar.4 -text Save -command { $this SaveObject }"
	set savebutton $buttonbar.4
	eval "button $buttonbar.5 -text Clear -command { $this ClearObject }"
	set clearbutton  $buttonbar.5
	eval "button $buttonbar.6 -text Info -command { $this Info }"
	pack $buttonbar.3 $buttonbar.4 $buttonbar.5 $buttonbar.6 -side top -expand f 
    } else {
	pack $base.top $buttonbar -side top -expand true -fill x 
	eval "button $buttonbar.3 -text Load -command { $this LoadObject } -padx 1"
	set loadbutton $buttonbar.3
	eval "button $buttonbar.4 -text Save -command { $this SaveObject } -padx 1"
	set savebutton $buttonbar.4
	eval "button $buttonbar.45 -text Clear -command { $this ClearObject } -padx 1"
	set clearbutton $buttonbar.45    

	eval "button $buttonbar.5 -text \"Info\" -command { $this Info }"
	pack $buttonbar.3 $buttonbar.4 $buttonbar.45 $buttonbar.5 -side left -expand false
    }


    set initialized 1

    return $basewidget
}


itcl::body pxitclobjectGUI::AddFunction { command name post } {

    if { $initialized == 0  } {
	return 0
    }
    set a $buttonbar.[pxvtable::vnewobj ]
    eval  "button $a -text \"$name\" -command { $command \[ $this GetObject \] $post } -padx 1 "
    pack $a -side left -fill x -expand f -padx 0
}


# --------------------------------------------------------------
#  abstract base GUI Class for pxitclmutltitransformGUI pxitclmutltiimageGUI
# --------------------------------------------------------------

itcl::class pxitclmultiObjectGUI {

    public    variable  itclobjectlist "" 
    public    variable  currentobject 0
    protected variable  objectGUI 0
    protected variable  basewidget  0
    protected variable  initialized 0
    protected common    thisparam
    public    variable  description "Object"
    public    variable  callback  ""
    public    variable  listbox 0
    public    variable  enableadd 1
    public    variable  enabledelete 1
    public    variable  enabledeleteall 0
    public    variable  enableupdown 0
    protected variable  objectindex 0

    constructor { } {
    }
    
    destructor {
	set l [ llength $itclobjectlist ]
	for { set a 0 } { $a < $l } { incr a } {
	    catch { itcl::delete object [ lindex $itclobjectlist $a ] }
	}
    }
    
    public    method GetThisPointer { } { return $this }

    public    method Initialize { basewidg } 
    public    method InitializeLite { basewidg } 
    public    method Update { } { $objectGUI Update } 
  
    public    method AddObject { descr }    
    public    method SetObject { { index -1 } }
    public    method GetObject { {  index -1 } }     
    public    method DeleteObject { index }
    public    method DeleteAllObjects { { force 0 } { addone 1 } }
    public    method AddFunction { command name post } { $objectGUI AddFunction $command $name $post }
    public    method CallbackFunction { }
    public    method GetCurrentObject { }
    public    method CurrentObjectModified { }
    public    method GetNumberOfObjects { } { return [ llength $itclobjectlist ] }
    public    method GetNextObjectIndex { } { return $objectindex }
    public    method MoveCurrentObject { direction }
    public    method SingleObjectGUIUpdate { args } { $this CallbackFunction }

    # -----------------------------------------
    # Function that must be overriden
    protected method CreateNewObject { } { puts stdout "Error!"}
    protected method CreateNewObjectGUI { widget } { puts stdout "Error!"}
    public    method AddInternalObject {  }    
    public    method DeleteInternalObject {  }    
    public    method GetObjectGUI { } { return $objectGUI }
    
}

itcl::body  pxitclmultiObjectGUI::GetObject { {  index -1 } } {

    if { $initialized == 0 } { 	return 0  }
    
    if { $index == - 1} {
	set index [ $listbox index [ $listbox getcurselection ]  ]
    }

    return [ [ lindex $itclobjectlist $index ] GetThisPointer ]
}

itcl::body pxitclmultiObjectGUI::SetObject { { index -1 } } {
    
    if { $initialized == 0 } { 	return 0  }

    set ln [ llength $itclobjectlist  ]

    if { $index == - 1 } { set index [ $listbox curselection ]    }
    if { $index < 0 || $index >= $ln } { set index $currentobject } 


    # Disable callback now
    $objectGUI configure -callback 0

    set currentobject $index    
    $objectGUI configure -description [ $listbox get $currentobject ]
    $listbox selection clear 0 [ expr $ln -1 ]
    $listbox selection set $index $index
    $objectGUI SetObject [ lindex $itclobjectlist $index ]

    $this CallbackFunction

    # renable callback
    eval "$objectGUI configure -callback   { $this SingleObjectGUIUpdate }"
    return $index 
}

itcl::body pxitclmultiObjectGUI::AddInternalObject { } {

    set a  [ GetNextObjectIndex ] 
    set b  [ string range $description 0 4 ]
    set desc "${b}.${a}"
    return [ [ AddObject $desc ] GetThisPointer ]
}




itcl::body pxitclmultiObjectGUI::DeleteInternalObject { } {

    set name [ $listbox get $currentobject ]
    set a  [ llength $itclobjectlist ]
    if { $a == 1 } {
	::pxtclutil::Warning "Cannot delete $name. This is the only object available!"
	return 0
    }

    set ok [ ::pxtclutil::Question "Are you sure you want to delete $name?" ]
    if { $ok == 0 } {
	return 0
    }

    DeleteObject $currentobject
}

itcl::body pxitclmultiObjectGUI::AddObject { descr } {

    if { $initialized == 0 } { return 0 }

    incr objectindex
    set new_obj [ $this CreateNewObject ]    
    $listbox insert end $descr
    lappend itclobjectlist $new_obj
    set index [ expr [ llength $itclobjectlist ]  -1 ]
    SetObject $index
    return [ $new_obj GetThisPointer ]
}




itcl::body pxitclmultiObjectGUI::DeleteAllObjects { { force 0 } { addone 1 } } {

    if { $force == 0 } {
	set ok [ ::pxtclutil::Question "Are you sure you want to delete all objects?" ]
	if { $ok == 0 } {
	    return 0
	}
    }
    
    if { $initialized == 0 } { return 0 }
    set ln [ llength $itclobjectlist  ]
    for { set i 0 } { $i < $ln } { incr i } {
	catch { itcl::delete object [ lindex $itclobjectlist $index ] }
    }
    set itclobjectlist ""
    $listbox delete 0 end
    if { $addone ==1 } {
	$this AddInternalObject
    }
}

itcl::body pxitclmultiObjectGUI::DeleteObject { index } {
    
    if { $initialized == 0 } { return 0 }
    
    set ln [ llength $itclobjectlist  ]
    
    if { $index < 0 || $index >= $ln } { return 0 } 

    catch { itcl::delete object [ lindex $itclobjectlist $index ] }
    set itclobjectlist [ lreplace $itclobjectlist $index $index ]

    $listbox delete $index $index

    if { $index == $currentobject } {
	SetObject 0
    } else {
	SetObject $currentobject
    }
}

itcl::body pxitclmultiObjectGUI::Initialize { basewidg } {
    
    if { $initialized == 1 } { 
	return $basewidget 
    }
    
    set basewidget [ iwidgets::Labeledframe $basewidg -labelpos n -labeltext $description ]
    set base [ $basewidget childsite ]
    
    frame $base.left; 
    frame $base.right;
    pack $base.left -side left -expand false -fill y
    pack $base.right -side right -expand true  -fill both

    set objectGUI [ $this CreateNewObjectGUI $base.right ]
    eval "$objectGUI configure -callback   { $this SingleObjectGUIUpdate }"

    set listbox [ iwidgets::scrolledlistbox $base.left.slb -vscrollmode dynamic -hscrollmode none -selectmode single -labelpos nw -visibleitems 10x8 ]
    eval "$listbox configure -selectioncommand { $this SetObject -1 }"
    $listbox configure -selectmode single
    $listbox configure -exportselection 0


    if { $enableadd == 1 || $enabledelete == 1 || $enabledeleteall == 1} {
	frame $base.left.bot; pack $base.left.bot -side bottom -fill x -expand f -pady 0

	if { $enableadd == 1 } {
	    eval "button $base.left.bot.add -text Add -command { $this AddInternalObject }"
	    pack $base.left.bot.add  -side left -expand f -fill x -padx 1
	}

	if { $enabledelete == 1 } {
	    eval "button $base.left.bot.delete -text Delete -command { $this DeleteInternalObject }"
	    pack $base.left.bot.delete  -side left -expand f -fill x -padx 1
	}

	if { $enabledeleteall == 1 } {
	    eval "button $base.left.bot.deleteall -text \"Del All\" -command { $this DeleteAllObjects }"
	    pack $base.left.bot.deleteall  -side left -expand f -fill x -padx 1
	}


    }

    if { $enableupdown == 1 } {
	set w [ frame $base.left.bot2 ] ; pack $w -side bottom -fill x -expand f -pady 0
	eval "button $w.1 -text Up -command { $this MoveCurrentObject -1 }"
	eval "button $w.2 -text Down -command { $this MoveCurrentObject 1 }"
	pack $w.1 $w.2 -side left -expand t -fill x -padx 1
    }


    eval "bind $listbox <ButtonRelease-1> { $this CallbackFunction }"
    pack $listbox -side top -fill x -padx 5 -pady 0



    set initialized 1
    return $basewidget
}

itcl::body pxitclmultiObjectGUI::CallbackFunction { } {    
    if { [ $this GetNumberOfObjects ] > 0  } {
	if { $callback !="" } {
	    return [ eval $callback ] 
	}
    }
    return 0
}
	
itcl::body pxitclmultiObjectGUI::GetCurrentObject { } {
    
 
    return [ lindex $itclobjectlist $currentobject ]
}
		
    
itcl::body pxitclmultiObjectGUI::CurrentObjectModified { } {
    if { [ $this GetNumberOfObjects ] > 0 }  {
	$objectGUI Update
    }
}


itcl::body pxitclmultiObjectGUI::MoveCurrentObject { direction } {

    if { $direction !=1 } {
	set direction -1
    }

    set myindex $currentobject
    set numelements [ expr [ llength $itclobjectlist ] -1 ]


    # Can't go up
    if { $direction == -1 && $myindex == 0 } {	return  0 }
    # Can't go down
    if { $direction == 1 && $myindex == $numelements } {	return  0  }

    set newindex [ expr $myindex + $direction ]

    #puts stderr "myindex=$myindex , numelements = $numelements newindex = $newindex , itclobjectlist = $itclobjectlist\n\n"

    set newobject   [ lindex $itclobjectlist $newindex ]
    set curobject [  lindex $itclobjectlist $myindex ]

    #puts stderr "curobject=$curobject , newobject = $newobject\n\n"



    if { $direction == -1 } {
	set min $newindex
	set max [ expr $myindex +1 ]
    } else {
	set min $myindex
	set max [ expr $newindex +1 ]
    }

    set oldlist $itclobjectlist
    set oldtaglist ""
    for { set i 0 } { $i < [ llength $oldlist ] } { incr i } {
	lappend oldtaglist [ $listbox get $i $i  ]
    }
    
    $listbox delete 0 end

    set itclobjectlist ""
    
    for { set i 0 } { $i < $min  } { incr i } {
	#puts stderr "Adding $i (0:$min) [ lindex $oldlist $i ]\n"
	lappend itclobjectlist [ lindex $oldlist $i ]
	$listbox insert end [ lindex $oldtaglist $i ]
    }

    if { $direction == 1 } {
	lappend itclobjectlist  $newobject
	lappend itclobjectlist  $curobject
	$listbox insert end [ lindex $oldtaglist $newindex ]
	$listbox insert end [ lindex $oldtaglist $myindex ]
	#puts stderr "Adding dir= 1 $newobject $curobject"
    } else {
	lappend itclobjectlist  $curobject
	lappend itclobjectlist  $newobject
	$listbox insert end [ lindex $oldtaglist $myindex ]
	$listbox insert end [ lindex $oldtaglist $newindex ]
	#puts stderr "Adding dir= -1  $curobject $newobject"
    }

    for { set i $max } { $i <= $numelements   } { incr i } {
#	puts stderr "Adding $i ($max:$numelements) [ lindex $oldlist $i ]\n"
	lappend itclobjectlist [ lindex $oldlist $i ]
	$listbox insert end [ lindex $oldtaglist $i ]
    }

    set oldlist ""
    set oldtaglist ""
    
    $this SetObject $newindex
    return 1
}
    
# -------------------------------------------------------------------------

itcl::body pxitclmultiObjectGUI::InitializeLite { basewidg } {
    
    if { $initialized == 1 } { 
	return $basewidget 
    }
    
    set basewidget [ iwidgets::Labeledframe $basewidg -labelpos n -labeltext $description ]
    set base [ $basewidget childsite ]
    
    set w1 [ frame $base.top ]
    set w2 [ frame $base.right ]
    pack $w2 -side bottom -expand true  -fill x
    pack $w1 -side top -expand true -fill x

    set objectGUI [ $this CreateNewObjectGUI $w2 ]
    eval "$objectGUI configure -callback   { $this SingleObjectGUIUpdate }"


    frame $w1.right; pack $w1.right -side right -expand false 
    frame $w1.left;  pack $w1.left  -side left  -expand true -fill both

    set listbox [ iwidgets::scrolledlistbox $w1.left.slb -vscrollmode dynamic -hscrollmode dynamic -selectmode single -labelpos nw -visibleitems 10x8 ] 
    [ $listbox component listbox ] configure -bg white -fg black
    eval "$listbox configure -selectioncommand { $this SetObject -1 }"
    $listbox configure -selectmode single
    $listbox configure -exportselection 0

    if { $enableadd == 1 || $enabledelete == 1 || $enabledeleteall == 1} {

	if { $enableadd == 1 } {
	    eval "button $w1.right.add -text Add -command { $this AddInternalObject }"
	    pack $w1.right.add  -side top -expand f -fill x -padx 1
	}

	if { $enabledelete == 1 } {
	    eval "button $w1.right.delete -text Delete -command { $this DeleteInternalObject }"
	    pack $w1.right.delete  -side top -expand f -fill x -padx 1
	}

	if { $enabledeleteall == 1 } {
	    eval "button $w1.right.deleteall -text \"Del All\" -command { $this DeleteAllObjects }"
	    pack $w1.right.deleteall  -side top -expand f -fill x -padx 1
	}


    }

    if { $enableupdown == 1 } {
	eval "button $w1.right.1 -text Up -command { $this MoveCurrentObject -1 }"
	eval "button $w1.right.2 -text Down -command { $this MoveCurrentObject 1 }"
	pack $w1.right.1 $w1.right.2 -side top -expand t -fill x -padx 1
    }


    eval "bind $listbox <ButtonRelease-1> { $this CallbackFunction }"
    pack $listbox -side top -fill x -padx 5 -pady 2 -expand true


    set initialized 1
    return $basewidget
}

