#!/bin/sh
# the next line restarts using wish \
    exec vtk "$0" -- "$@"

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



if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    lappend auto_path [ file dirname [ info script ]]
    lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] base]
    lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] apps]
    lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] main]
}


package provide bis_optiondialog 1.0
package require  Itcl
package require bis_option 1.0
package require bis_common 1.0
package require bis_algorithm 1.0
package require Iwidgets 
package require pxitclobject 1.0
package require bis_datamanager 1.0


itcl::class bis_optiondialog {

    #
    #public
    #

    constructor { } { }
    destructor { $this CleanAll }

    # This Pointer
    public method GetThisPointer { } { return $this }

    # ------------------------------------------
    public method CreateGUI { base { dialog 1 } {  optionslist -1 }  }
    public method InitializeAsXMLDataElement { datamanager }
    public method SetCallback { clb } { set callbackfunction $clb }
    public method SetOptionsFromXMLDataElement  { eml }
    public method StoreOptionsInXMLDataElement  {  }

    # -----------------------------------------
    public method ShowWindow { }
    public method HideWindow { }
    public method SetTitle   { ttl }
    public method SetIcon   { ico }

    # -----------------------------------------------------------
    # vtk-like interface to Modify/access invidual option and inputs outputs
    # -----------------------------------------------------------
    public method SetOptionValue  { optionname value }
    public method SetOptionRange  { optionname value }
    public method GetOptionValue  { optionname }
    public method GetOption  { optionname }
    public method GetXMLElement   { } { return $xmlelement }
    public method GetBaseWidget   { } { return $basewidget }
    public method GetButtonBar   { } { return $buttonbar }
    # Enable/Disable Options
    # ----------------------
    public method DisableOption   { optionname } { return [ $this SetOptionStatus $optionname 0 ] }
    public method EnableOption    { optionname } { return [ $this SetOptionStatus $optionname 1 ] }
    public method SetOptionStatus { optionname opt } 

    #Internal tcl array for input files 
    protected variable OptionsArray
    protected variable StandardOptionsList ""
    protected variable AdvancedOptionsList ""
    protected variable options ""
    protected variable basewidget 0
    protected variable buttonbar  0

    # Status array one per option
    protected variable optionstatus
    protected variable isdialog 0
    protected variable title "Options Dialog"
    protected variable iconname 0

    # XML Stuff
    protected variable xmlelement 0
    protected variable callbackfunction 0
    public    method UpdateValues { args }

    public method   SetStateOfWidget { widget mode }



    #set until execution
    protected method   CreateOptionsArray { }
};

# -----------------------------------------------------------
#  VTK Like interface to options and outputs
# -----------------------------------------------------------
itcl::body bis_optiondialog::SetOptionValue { optionname value } {

    $OptionsArray($optionname) SetValue $value
}

itcl::body bis_optiondialog::SetOptionRange { optionname value } {
    $OptionsArray($optionname) SetValueRange $value
}

itcl::body bis_optiondialog::GetOptionValue { optionname } {

    return [ $OptionsArray($optionname) GetValue ]
}

itcl::body bis_optiondialog::GetOption { optionname } {

    return $OptionsArray($optionname) 
}



#----------------------------------------------------
#Generate InputsArray,OutputsArray, and OptionsArray
#----------------------------------------------------
itcl::body bis_optiondialog::CreateOptionsArray { } {

    array set OptionsArray {}
    set nlist ""
    for { set i 0 } { $i < [llength $options  ] } { incr i } {
	set lst [ lindex $options $i]
	set name [ lindex $lst  0]

	if { $name == "out" || $name == "inp" || $name == "i" || $name =="o" } {
	    puts stderr "Bad Option Name \"out\" -- this is reserved"
	    exit
	}

	if { [ regexp "out\[0-9\]+" $name  ] > 0 } {
	    puts stderr "Bad Option Name $name -- this matches a  reserved name"
	    exit
	}

	if { [ regexp "inp\[0-9\]+" $name  ] > 0 } {
	    puts stderr "Bad Option Name $name -- this matches a  reserved name"
	    exit
	}

	if { [ llength $lst ] ==7 } {
	    set p [ lindex $lst 6 ]
	    if { $p < 0 } {
		set p [ expr abs($p) + 1000000 ]
	    }
	    lappend nlist [ list $i $p $name ]
	}
    }

    set pluspr    0
    set minuspr -1

    set StandardOptionsList ""
    set AdvancedOptionsList ""

    set nlist [ lsort -integer  -index 1 $nlist ]
    for { set i 0 } { $i < [ llength $nlist ] } { incr i } {
	
	set ind [ lindex [ lindex $nlist $i ] 0 ]
	set lst [ lindex $options $ind ]
	set p   [ lindex $lst 6 ]

	set name [ lindex $lst 0 ]
	if { $p >= 0 } {
	    lset lst 6 $pluspr; incr pluspr
	    lappend StandardOptionsList $name
	} else {
	    lappend AdvancedOptionsList $name
	    if { $p > -10000 } {
		lset lst 6 $minuspr; set minuspr [ expr $minuspr -1 ]
	    }
	}

	set elem [ [ bis_option \#auto ] GetThisPointer ]
	set OptionsArray($name) $elem
	$OptionsArray($name) SetAllPropertiesAsList $lst

    }
}

# ------------------------------------------
#
# Easy Stuff !
#
# -----------------------------------------
itcl::body bis_optiondialog::ShowWindow { } {
    
    if { $basewidget !=0 && $isdialog > 0 } {
	if { [ winfo ismapped $basewidget ] == 1 } {
	    raise $basewidget
	} else {
	    wm deiconify $basewidget
	}
    }
} 

itcl::body bis_optiondialog::HideWindow { } {
    catch { wm withdraw $basewidget }
}

itcl::body bis_optiondialog::SetTitle   { ttl } {
    if { $basewidget !=0 && $isdialog > 0 } {
	wm title $basewidget $ttl
    }
    
}

itcl::body bis_optiondialog::SetIcon   { ico } {
    set iconname $icon
}

itcl::body bis_optiondialog::SetOptionStatus { optionname opt }  {

#    puts stderr "Setting $optionname = $opt"
    set optionstatus($optionname) $opt
    if { $basewidget ==0 } {
	return
    }

    set b [ $OptionsArray($optionname) GetBaseWidget ]
    if { $optionstatus($optionname) > 0 } {
	pack $b -side top -expand false -fill x
    } else {
	pack forget $b
    }
}



# ----------------------------------------------------------------------------------------
itcl::body bis_optiondialog::InitializeAsXMLDataElement { datamanager } {

    set tmp [ $datamanager GetAttributesList ]
    set n [ llength $tmp ]
    set alloptions ""
    for { set i 0 } { $i < $n } { incr i } {
	lappend alloptions [ lindex [ lindex $tmp $i ] 0 ]
    }
    #    puts $alloptions


    set fnamelist  [ $datamanager GetFilenamesList  ]
    set excludelist [ concat [  $datamanager GetAttributesZeroList ] [ $datamanager GetAttributeGUIList ] ]
    set booleanlist [ $datamanager GetAttributeBooleanList ]

    set n [ llength $alloptions ]
    set options ""
    set priority 1
    for { set i 0 } { $i < $n } { incr i } {
	
	set att [ lindex $alloptions $i ]
	set ind [ lsearch -exact $excludelist $att ]
	set dobool [ expr [ lsearch -exact $booleanlist $att ] > -1 ]
	set isfname [ expr [ lsearch -exact $fnamelist $att ] > -1 ]
	if { $ind == -1 } {
	    if { $dobool > 0 } {
		lappend options [ list  $att $att $att boolean 0 { 0 1 }  $priority ]
	    } elseif { $isfname > 0 } {
		if { $att == "Filename" } {
		    lappend options [ list $att $att $att { filename readfile } ""  pxitclimage  $priority ]
		} else {
		    lappend options [ list $att $att $att { filename readfile } ""  pxitcltransform  $priority ]
		}
	    } else {
		lappend options [ list $att $att $att string "" "" $priority ]
	    }
	    incr priority
	}
    }
}
# ----------------------------------------------------------------------------------------
itcl::body bis_optiondialog::UpdateValues { args } {

    set changed ""
    if { $xmlelement != 0 } {
	set changed [ $this StoreOptionsInXMLDataElement ]
    }

#    puts stderr "Changed in updvalues = $changed"

    if { $callbackfunction != "" && $callbackfunction !=0 } {
	set cmd "$callbackfunction $this $changed"
#	puts stderr "Calling callback $cmd"
	eval $cmd 
    }
    return $changed
}
# ----------------------------------------------------------------------------------------
itcl::body bis_optiondialog::CreateGUI { base { dialog 1 } {  optionslist -1 }  } {

    if { $options == "" && $optionslist == -1 } {
	puts stderr "Options undefined"
	return 0
    }

    if { $optionslist != -1 } {
	set options $optionslist
    }

    #    puts stderr "options=$options"

    $this CreateOptionsArray
    
    set basewidget $base.[ pxvtable::vnewobj ]
    if { $dialog > 0 } {
#	puts stderr "Creating toplevel $basewidget"
	toplevel $basewidget
	wm withdraw $basewidget
	eval "wm protocol $basewidget WM_DELETE_WINDOW { wm withdraw $basewidget  }"
	wm geometry $basewidget 500x420
	set isdialog 1
    } else {
	frame $basewidget
	set isdialog 0
	pack $basewidget -side top -expand true -fill both
    }

    

    set bbar [ iwidgets::buttonbox $basewidget.b -orient horizontal ]
    pack $bbar -side bottom -expand true -fill x

    set buttonbar $bbar
#    $inputbbox add add -text "Add..." -command [ itcl::code $this addinput ]
#    $inputbbox add remove -text "Remove" -command [ itcl::code $this removeinput ] -state disabled
#    $inputbbox add display -text "Display" -command [ itcl::code $this displayinput ] -state disabled   

#    set bbar [ frame $basewidget.b ]

    $bbar add update -text "Update" -command [ itcl::code  $this UpdateValues ]
    
    if { $isdialog > 0 } {
	$bbar add close -text "Close Window" -command [ itcl::code  $this HideWindow ]
    }
#    pack $bbar.l -side left -expand false 

    set w [ iwidgets::labeledframe $basewidget.sf  -labeltext "" ]
    set nlist [ concat $StandardOptionsList $AdvancedOptionsList ]
    set elemlist ""
    pack $w -side top -expand true -fill both
    set  wc [ $w childsite ]

#    puts stderr "nlist=$nlist"
    set alist ""
    for { set i 0 } { $i < [ llength $nlist ] } { incr i } {

	set name  [ lindex $nlist $i ]
	set opt $OptionsArray($name)
	set w2  $wc.[pxvtable::vnewobj ] 
	#puts stderr "Creating $name $w2"
	$opt configure -optionguiwidth 25
	$opt CreateGUIElement $w2 ""
	$opt HideHelpButton
	eval "$opt  SetGUICallbackFunction { $this UpdateValues } "
	pack $w2 -side top -expand true -fill x
	lappend alist  $w2.lab
    }

    eval "iwidgets::Labeledwidget::alignlabels $alist"

    return $basewidget
}


itcl::body bis_optiondialog::SetOptionsFromXMLDataElement  { eml } {
    
    set xmlelement $eml
    set names [array names OptionsArray]
    if { $names == "" } { return 0 }

    foreach n $names {
	set v [ $xmlelement GetAttribute $n ]
	$OptionsArray($n) SetValue $v
    }


    set v [ $xmlelement GetAttribute Type ]
    set n Filename
    switch -exact $v { 
	"Image"   { $OptionsArray($n) SetValueRange image }
	"Surface" { $OptionsArray($n) SetValueRange surface }
	"Landmarks" { $OptionsArray($n) SetValueRange landmarks }
	"Electrodes" { $OptionsArray($n) SetValueRange electrode }
    } 
}

itcl::body bis_optiondialog::StoreOptionsInXMLDataElement  { } {
    set names [array names OptionsArray]

    set changed ""

    foreach n $names {
	set v [ $OptionsArray($n) GetValue ]
	set a [ string first " " $v ]
	if { $a == -1 } {
	    set ln [ expr [ string length $v ] -1 ]
	    if { [ string range $v 0 0 ] == "\"" &&
		 [ string range $v $ln $ln ] == "\"" } {
		set v [ string range $v 1 [ expr $ln -1 ] ]
	    }
	}

	set ind [ string first "Filename" $n ]
	set v1 [ $xmlelement GetAttribute $n ]
	if { $ind > -1 &&  [ file tail $v ] == 0 } {
	    set v 0
	}
	if { $v != $v1 } {
	    lappend changed $n
	    $xmlelement SetAttribute $n $v
#	    puts stderr "Mapping [ $xmlelement GetName ] $n $v1 -> $v"
	}
    }
    return $changed
}


::itcl::body bis_optiondialog::SetStateOfWidget { widget state } {
    
    set children [ winfo children $widget ]
    set a [ llength $children ]
    if { $a == 0 } {
	set ok 0
	catch { $widget configure -state $state ; set ok 1 }
	if { $ok == 0 } {
	    catch {
		set tl [ file extension $widget ]
		if { $tl == ".menu" } {
		    set n [ $widget  index end ]
		    for { set i 0 } { $i <= $n } { incr i } {
			$widget entryconfigure $i -state $state	
		    }
		}
	    }
	}
	return 0
    } else {
	for { set i 0 } { $i < $a } { incr i } {
	    SetStateOfWidget [ lindex $children $i ] $state
	}
    }
}


proc bis_optiondialog_callback { args } {
    puts stderr "args = $args"
}

if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {

    frame .bot; pack .bot -side top -expand true
    set alg [ bis_datamanager \#auto ]
    $alg ImportMSBFile [ lindex $argv 0 ]
    
    set opt [ bis_optiondialog \#auto ]
    $opt InitializeAsXMLDataElement $alg
    $opt SetCallback bis_optiondialog_callback
    set b [ $opt CreateGUI .bot  ]
    $opt ShowWindow
    wm withdraw . 
}





