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

package provide bis_option 1.0

#
# bis_option.tcl
#

if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    lappend auto_path [ file dirname [ info script ]]
    lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] base]
    lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] apps]
}

package require Itcl
package require Iwidgets
package require bis_common

itcl::class bis_option {

        # This is a static array to store GUI input
        private   common   thisparam

	constructor { } {
	    set thisparam($this,value) 0
	    set thisparam($this,listbox) 0
	    set thisparam($this,selectiondialog) 0
	    set thisparam($this,textbox) 0
	}

	# More GUI Stuff
	protected variable callbackfunction 0
	
	# This is the command line switch (e.g. -h) 
	protected variable commandswitch     "-h"
	protected variable description       "Print a help message for this algorithm"
	protected variable shortdescription  "Help Message"
	
	# Created Possible List
	# The following static arrays contain all valid options
	protected common optiontypelist [ list listofvalues boolean real integer string filename comment multiplevalues ] 
	protected common optiontypehintlist { scale triplescale entrywidget radiobuttons optionmenu checkbutton default readfile writefile directory comment }

	# These are the actual option settings for this class
	private variable optiontype     "real"
	private variable optiontypehint "default"
	
	# Some public stuff for the GUI
	public variable optionguiwidth -1
	
	# This is the default value for the option
	protected variable defaultvalue 0

	# a list of either { min,max} or allowed entries
	protected variable valuerange  { 0 10 }
	protected variable valuerangewidget 0 
	protected variable valuewidget 0
	protected variable labeledwidget 0

	public method GetValueWidget { } { return $valuewidget }
	public method GetLabeledWidget { } { return $labeledwidget }


	# this is the basewidget
	protected variable basewidget 0
	# this is needed by comment elements
	protected variable labelwidget 0 

        # oneoff { positive value (normal)  negative value (experimental) } higher is better
	protected variable priority  0   

        # switch for input value automatic correction 
	# If this is on, input value is clamped.
	# If this is off, return code is 0(NG) or 1(OK).
        protected   common autocorrection 1

	# Basic Class Interface
	# Setting and Getting of Member Variables
  	public method SetCommandSwitch    { a } { set commandswitch $a }
  	public method GetCommandSwitch    {   } { return $commandswitch  }

  	public method SetDescription      { a } { set description $a }
  	public method GetDescription      {   } { return $description }

  	public method SetShortDescription { a } { set shortdescription $a }
  	public method GetShortDescription {  } { return $shortdescription}

	# Option Type -- full implementation below
  	public method SetOptionType       { optiontype { optionhint default }}
  	public method GetOptionType       {   } { return  $optiontype }

	#
  	public method SetDefaultValue     { a } 
  	public method GetDefaultValue     {   } { return $defaultvalue }

	# Get Widget
	public method GetBaseWidget { } { return $basewidget }

	# Get Slicer XML Description
	public method GetSlicerXMLDescription { }
	public method GetLONIXMLDescription { }
	public method GetJSONString { }

	# Value Range
  	public method SetValueRange       { a } 
  	public method GetValueRange       {   } { return $valuerange }

  	public method SetPriority         { a } { set priority $a }
  	public method GetPriority         {   } { return $priority }

  	public method SetAutoCorrection        { a } { set autocorrection $a }
  	public method GetAutoCorrection        {   } { return $autocorrection }

	public method SetAllPropertiesAsList { il  } 


	public method SetAllProperties    { i_cmdswitch i_description i_shortdescription i_opttype i_defvalue i_val i_priority } {
	    SetCommandSwitch    $i_cmdswitch
	    SetDescription      $i_description
	    SetShortDescription $i_shortdescription
	    SetOptionType   [ lindex    $i_opttype 0 ]

	    set optiontypehint "default"
	    set optionguiwidth  -1
	    
	    if { [ llength $i_opttype ] > 1 } {
		set optiontypehint  [ lindex    $i_opttype 1 ]
		if { [ llength $i_opttype ] > 2 } {
		    set optionguiwidth  [ lindex    $i_opttype 2 ]
		}
	    }
	    SetValueRange       [ string trim $i_val ]
	    SetDefaultValue     [ string trim $i_defvalue ]
	    SetPriority         $i_priority
	    SetValue            [ $this GetDefaultValue ]
	}

	# 
	public method PrintSelf     { }

	public method GetCmdLineString { } { 
	    return [ list ${commandswitch}.arg $defaultvalue $description ] 	
	}

	# Get Set Value
	
  	public method GetValue     {   } { 
	    set thisparam($this,value) [CheckValue  $thisparam($this,value) ]
	    return $thisparam($this,value) 
	}

	public method SetValue { inpval } { 
	    set thisparam($this,value) [CheckValue $inpval ]
	    if { $optiontype == "comment" &&  $labelwidget!=0 } {
		#$labelwidget configure -text $thisparam($this,value)
		$thisparam($this,textbox) configure -state normal
		$thisparam($this,textbox) delete 1.0 end
		$thisparam($this,textbox) insert end $thisparam($this,value)
		$thisparam($this,textbox) configure -state disabled
	    }
	}


	public method SetValueIfCurrentIsTheDefault { inpval } { 
	    if { $thisparam($this,value) == $defaultvalue } {
		set thisparam($this,value) [CheckValue $inpval]
	    }
	}


	public method UpdateFromGUI { } 
	#
	public method CheckValue { inpval }
	protected method CheckValueByRange { inpval }
	protected method CheckValueByListOfValues { inpval }
	protected method CheckValueByMultipleValues { inpval }

	public method SetCommandLine { name } 

	# returns a string for a logfile
	# public method GetLogElement { }   

	# GUI Stuff
	# parent widget must not exists, it will be created by this method
	# it must be packed on return
	public method CreateGUIElement { parentwidget { callback "" } }
	public method SetGUICallbackFunction { cl } {  set callbackfunction $cl }
	public method GUICallbackFunction { }

	public method GUIQuickHelp { }
	protected method CreateGUIElementList { parentwidget  }
	protected method CreateGUIElementRange { parentwidget  }
	protected method CreateGUIElementMultiple { parentwidget  }
	protected method CreateGUIElementString { parentwidget  }
	protected method CreateGUIElementBoolean { parentwidget  }
	protected method CreateGUIElementFilename { parentwidget  }
	protected method CreateGUIElementComment { parentwidget  }
	

	# Method Get FileName
	public method GetFileName { }

	# Method Get Multiple Selection
	public method GetMultipleSelection { }


	# boolean -- checkbutton
	# listofvalues -- option menu
	# multiple values -- string + popup dialog i.e. like filename
	# real/integer  -- textentry

	# It does proper scoping
	#Instead of
	#set option  [ bis_option #auto ]
	#use	set option [ [ bis_option #auto ] GetThisPointer ]
	public method GetThisPointer { } { return $this }

	# Help Button (Hide)
	# 

	protected variable helpbutton 0
	protected variable helpmessage "default"

	public method SetHelpMessage { msg } {  set helpmessage $msg }
	public method HideHelpButton { } {     catch { pack forget $helpbutton }	}


	# selection dialog

    }
#----------------------------------------------------
itcl::body bis_option::PrintSelf { } {
    puts stdout "commandswitch    =  [$this GetCommandSwitch]"
    puts stdout "description      =  [$this GetDescription]"
    puts stdout "shortdescription =  [$this GetShortDescription]"
    puts stdout "optiontype       =  [$this GetOptionType]"
    puts stdout "defaultvalue     =  [$this GetDefaultValue]"
    puts stdout "value            =  [$this GetValue]"
    puts stdout "valuerange       =  [$this GetValueRange]"
    puts stdout "priority         =  [$this GetPriority]"
    puts stdout "\n"
}

#----------------------------------------------------
itcl::body bis_option::GetSlicerXMLDescription { } {


    set base "\t<name>[ $this GetCommandSwitch]</name>\n"
    set base "$base\t<label>[ $this GetShortDescription]</label>\n"
    set base "$base\t<longflag>--[ $this GetCommandSwitch]</longflag>\n"
    set base "$base\t<description>[ $this GetDescription ]</description>\n"
    set base "$base\t<default>[ $this GetDefaultValue ]</default>\n"

    set range "\t<constraints>\n"
    set range "$range\t\t<minimum>[ lindex [ $this GetValueRange ] 0 ]</minimum>\n"
    set range "$range\t\t<maximum>[ lindex [ $this GetValueRange ] 1 ]</maximum>\n"
    set range "$range\t</constraints>"

    set elrange ""
    for { set i 0 } { $i < [ llength [ $this GetValueRange ] ] } { incr i } {
	set elrange "$elrange\t\t<element>[ lindex  [ $this GetValueRange ] $i ]</element>\n"
    }
    
    # ---------------------------------------------
    switch $optiontype {
	integer { 
	    set line "<integer>\n$base$range</integer>\n"
	}
	real    { 
	    set line "<double>\n$base$range\n</double>\n"
	}
	boolean {
	    set line "<string-enumeration>\n$base$elrange</string-enumeration>"
	}
	listofvalues { 
	    set line "<string-enumeration>\n$base$elrange</string-enumeration>"
	}
	filename { 
	    if { $optiontypehint == "writefile" } {
		set tmp "<channel>output</channel>\n"
	    } else {
		set tmp "<channel>input</channel>\n"
	    }
	    set line "<file>\n$base\t$tmp</file>\n"
	}
	default {
	    set line "<file>\n$base</file>\n"
	}
    }
    # ---------------------------------------------
}

# -------------------------------------------------------------------------------------------------------------
itcl::body bis_option::GetJSONString { } {

    set val [ $this GetValueRange] 
    set v1 [ ::bis_common::CleanString $description]
    set v2 [ ::bis_common::CleanString $shortdescription]

    set txt "\t\t\"$commandswitch\": \{\n"
    append txt "\t\t\t\"description\": $v1,\n"
    append txt "\t\t\t\"shortdescription\": $v2,\n"
    append txt "\t\t\t\"optiontype\": [ ::bis_common::CleanString $optiontype],\n"
    append txt "\t\t\t\"optiontypehint\": [ ::bis_common::CleanString $optiontypehint],\n"
    append txt "\t\t\t\"optionguiwidth\": [ ::bis_common::CleanString $optionguiwidth],\n"
    append txt "\t\t\t\"defaultvalue\": [ ::bis_common::CleanString $defaultvalue],\n"
    append txt "\t\t\t\"valuerange\": [ ::bis_common::CleanString $val],\n"
    append txt "\t\t\t\"priority\": [ ::bis_common::CleanString [$this GetPriority]]\n"
    append txt "\t\t\}"
    return $txt
}

# -------------------------------------------------------------------------------------------------------------

itcl::body bis_option::GetLONIXMLDescription { } {

    set mode 0
    if { $optiontype=="filename" } {
	set mode 1
	if { $optiontypehint == "directory" } {
	    set mode 2
	}
    }
    
    set line "\t\t\t<input name=\"[ $this GetShortDescription ]\" "
#    append line  "id=\"bis_option_[$this GetCommandSwitch ]\" "
    append line  "description=\"[ $this GetDescription ]\" "
    append line  "enabled=\"true\" "
    append line  "required=\"false\" "
    append line  "switchedSpaced=\"true\" "
    append line  "switch=\"-[$this GetCommandSwitch ]\">\n"

     
    if { $mode == 1 } {
	append line "\t\t\t\t<format type=\"File\" cardinality=\"1\" />\n"
    } elseif { $mode == 2 } {
	append line "\t\t\t\t<format type=\"Directory\" cardinality=\"1\"/>\n"
    } elseif { $optiontype == "listofvalues" } {
	append line "\t\t\t\t<format type=\"String\" cardinality=\"1\"/>\n"
    } elseif { $optiontype == "integer" || $optiontype == "real" || $optiontype == "boolean" } {
	append line "\t\t\t\t<format type=\"Number\" cardinality=\"1\"/>\n"
    } else {
	append line "\t\t\t\t<format type=\"String\" cardinality=\"1\"/>\n"
    }
    append line "\t\t\t</input>\n"
    return $line
}

#----------------------------------------------------
#Check the value 
#----------------------------------------------------
itcl::body bis_option::SetDefaultValue     { a }  {
    set defaultvalue $a
}

itcl::body bis_option::CheckValue { inpval  } {
    
    set type  $optiontype 
    if { $type == "string" || $type == "comment" } {
	return $inpval
    }

    if { $type == "filename" } {
	if { $inpval == "" || $inpval == "0" } {
	    return $inpval
	}
	return [ file normalize $inpval ]
    }

    set ret 1
    switch $type {
	integer {
	    set ret [CheckValueByRange $inpval]
	}
	real {
	    set ret [CheckValueByRange $inpval]
	}
	listofvalues {
	    set ret [CheckValueByListOfValues  $inpval]
	}
	multiplevalues {
	    set ret [CheckValueByMultipleValues  $inpval]
	}
	boolean {
	    set ret [CheckValueByListOfValues  $inpval]
	}
    }
    return $ret
}


#----------------------------------------------------
#Check the value in the specified range {min,max}
#----------------------------------------------------
itcl::body bis_option::CheckValueByRange { inpval } {

    set min [lindex  $valuerange 0 ]
    set max [lindex  $valuerange 1 ]
    if { $autocorrection == 1 } {
	if { $inpval  < $min }  {
	    return $min
	} elseif { $inpval > $max } {
	    return $max
	}
	return $inpval
    } else {
	#returns  1:ok,0:ng (autocorrection off)
	if { $inpval  < $min }  {
	    return 0
	} elseif { $inpval > $max } {
	    return 0
	}
	return 1
    }
}

#----------------------------------------------------
#Check the value in the specified list
#----------------------------------------------------
itcl::body bis_option::CheckValueByListOfValues { inpval } {
    
    if { $autocorrection == 1 } {
	if { [ lsearch -exact $valuerange $inpval ] >=0 } {
	    return $inpval
	}
	return [ lindex $valuerange 0 ]
    } else {
	#returns  1:ok,0:ng (autocorrection off)
	if { [ lsearch -exact $valuerange $inpval ] >=0 } {
	    return 1
	}
	return  0
    }
}

# ----------------------------------------------------------------------------
itcl::body bis_option::CheckValueByMultipleValues { inpval } {
    
    set goodvalues ""
    if { $autocorrection == 1 } {
	if { [ llength $inpval ] == 0 } { return $inpval }

	for { set i 0 } { $i < [ llength $inpval ] } { incr i } {
	    if { [ lsearch -exact $valuerange [ lindex $inpval $i ] ] >=0  } {
		lappend goodvalues [ lindex $inpval $i ]
	    }
	}
	if { $goodvalues != "" } {
	    return $goodvalues
	}
	return [ lindex $valuerange 0 ]
    } else {
	#returns  1:ok,0:ng (autocorrection off)
	if { [ llength $inpval ] == 0 } { return 1 }
	set ok 1
	for { set i 0 } { $i < [ llength $inpval ] } { incr i } {
	    if { [ lsearch -exact $valuerange [ lindex $inpval $i ] ] ==-1 } {
		return 0
	    }
	}
	return 1
    }
}

# ----------------------------------------------------------------------------

itcl::body bis_option::SetCommandLine { name } {
    set  CommandLine $name
    puts stdout "Command Line = $CommandLine"
}

itcl::body bis_option::SetOptionType { i_optiontype { i_optionhint default } } {
    if { [ lsearch $optiontypelist $i_optiontype ] == - 1 } {
	return 0
    }
    
    set optiontype $i_optiontype

    if { [ lsearch -exact $optiontypehintlist $i_optionhint ] == - 1 } {
	set optiontypehint "default"
    } else {
        set optiontypehint  $i_optionhint 
    }
    
    if { $optiontype == "boolean" } {
	set valuerange { 0 1 }
    }

    return 1
}
# --------------------------------------------------------------------------------------
itcl::body bis_option::SetAllPropertiesAsList { il } {

    if { [ llength $il ] < 7 } {
	return 0
    }

    SetAllProperties [ lindex $il 0 ] [ lindex $il 1 ] [ lindex $il 2 ] [ lindex $il 3 ] [ lindex $il 4 ] [ lindex $il 5 ] [ lindex $il 6 ] 
    return [ llength $il ]
}

itcl::body bis_option::SetValueRange { a }  {

    if { $optiontype == "filename" } {

	if { [ string match -nocase "*image*" $a ] > 0 } {
	    set valuerange { 
		{"Analyze/NIFT1 Files" { .hdr .hdr.gz .nii .nii.gz }}
		{"VTK Files" {.vt*}}
		{"All Files" {*}}}
	} elseif { [ string match -nocase "*transform*" $a ] > 0 } {
	    set valuerange { 
		{"Matrix/Grid Files" {".matr" ".grd" ".grd.gz" } }
		{"Grid/Combo Transform Files"  {".grd" ".grd.gz" }}
		{"VTK Displacement Fields" {.vtk}} 
		{"PolySimilarity Transforms" {.psim}} 
		{"Matrix Files" {.matr}} 
		{"Thin Plate Spline Transforms" {.tps}} 
		{"All Files" {*}}}
	} elseif { [ string match -nocase "*surface*" $a ] > 0 } {
	    set valuerange { 
		{"VTK Surface" {.vtk .vsp}} 
		{"All Files" {*}}}
	} elseif { [ string match -nocase "*landmarks*" $a ] > 0 } {
	    set valuerange { 
		{"Landmark Files" {.land .vtk}} 
		{"All Files" {*}}}
	} elseif { [ string match -nocase "*electrode*" $a ] > 0 } {
	    set valuerange { 
		{"Electrode Grid Files" {.mgrid}} 
		{"All Files" {*}}}
	} elseif { [ string match -nocase "*textfile*" $a ] > 0 } {
	    set valuerange { 
		{"Text Files" {.txt}} 
		{"All Files" {*}}}
	} elseif { [ string match -nocase "*datatree*" $a ] > 0 } {
	    set valuerange { 
		{"XMLTree Files" { .xmltree  .tre .msb}}
		{"All Files" {*}}}
	} elseif { [ string match -nocase "*allfiles*" $a ] > 0 } {
	    set valuerange { 
		{"All Files" {*}}}
	} else {
	    set valuerange "{ $a }"
	}

	return
    }

    if { $optiontype != "real" && $optiontype != "integer" } {
	set valuerange $a
	return
    }
    if { [llength $a ] < 2 } { return 0}
    set minv [ lindex $a 0 ]
    set maxv [ lindex $a 1 ]
    if { $maxv < $minv } {
	set maxv $minv
	set minv [ lindex $a 1 ]
    }

    set valuerange [ list $minv $maxv ]

    if { $valuerangewidget !=0 } {
	$valuerangewidget configure -from $minv -to $maxv
    }
    
    if { $thisparam($this,value) < $minv } {
	set thisparam($this,value) $minv
    } elseif { $thisparam($this,value) > $maxv } {
	set thisparam($this,value) $maxv
    }

    return $valuerange
}
# --------------------------------------------------------------------------------------
#           GUI Stuff
# --------------------------------------------------------------------------------------

itcl::body bis_option::CreateGUIElement { parentwidget { callback "" } } {

    set callbackfunction $callback
    frame $parentwidget

    switch $optiontype {
	integer { set f [ $this CreateGUIElementRange $parentwidget.lab ] }
	real    { set f [ $this CreateGUIElementRange $parentwidget.lab ] }
	listofvalues { set f [ $this CreateGUIElementList $parentwidget.lab ] }
	multiplevalues { set f [ $this CreateGUIElementMultiple $parentwidget.lab ] }
	boolean { set f [ $this CreateGUIElementBoolean $parentwidget.lab ] }
	filename { set f [ $this CreateGUIElementFilename $parentwidget.lab ] }
	comment { set f [ $this CreateGUIElementComment $parentwidget.lab ] }
	default { set f [ $this CreateGUIElementString $parentwidget.lab ] }
    }

    eval "button $parentwidget.2 -text \"?\" -command { $this GUIQuickHelp }"
#    if { $optiontype != "comment" } {
	pack $parentwidget.2 -side right -padx 0 -expand false
#    }
    pack $f -side left -expand true -fill x
    set helpbutton $parentwidget.2


    set basewidget $parentwidget
    return $parentwidget
}

itcl::body bis_option::UpdateFromGUI { } {
    $this GUICallbackFunction 
}

itcl::body bis_option::GUIQuickHelp {  } {

    if { $optiontype == "comment"  } {
	tk_messageBox -type ok -message "$description \n  [  $this GetDefaultValue ]\n[ $this GetValueRange ]" -title "Quick Help -$commandswitch" -icon info
    } elseif { $helpmessage == "default" } {
	tk_messageBox -type ok -message "$description\n(default = [  $this GetDefaultValue ])\n(allowed = [ $this GetValueRange ])" -title "Quick Help -$commandswitch" -icon info
    } else {
	tk_messageBox -type ok -message "$helpmessage" -title "Quick Help" -icon info	
    }
}

itcl::body bis_option::GUICallbackFunction {  } {

    if { $callbackfunction != "" && $callbackfunction !=0 } {
	set cmd "$callbackfunction $this $thisparam($this,value) "
	eval $cmd 
    }
}

itcl::body bis_option::CreateGUIElementList { parentwidget  } {

    set base [ [ iwidgets::labeledwidget $parentwidget  -labeltext "${shortdescription}:"  ] childsite ]

    

    set n [ llength $valuerange ]
    if { $optiontypehint == "radiobuttons" } {
	for { set i 0 } { $i < $n } { incr i }  {
	    set v [ lindex $valuerange $i ]
	    radiobutton $base.$i -variable [itcl::scope thisparam($this,value)] -value $v -text $v 
	    eval "$base.$i configure -command { $this GUICallbackFunction }"
	    pack $base.$i -side left
	}
    } else {
	eval "tk_optionMenu ${base}.opt [ itcl::scope thisparam($this,value) ] $valuerange"
	pack ${base}.opt  -side left -expand t -fill x

	for { set i 0 } { $i < $n } { incr i } { 
	    eval "$base.opt.menu entryconfigure $i -command { $this GUICallbackFunction }"
	}
    }
    return $parentwidget
}


# ------------------------------------------------------------------------
itcl::body bis_option::CreateGUIElementMultiple { base  } {

#    puts stderr "In multiple $shortdescription base=$base"
    set valuewidget  $base
    iwidgets::entryfield $base -labeltext "${shortdescription}:"   -textvariable [ itcl::scope thisparam($this,value) ] -relief sunken  
    set labeledwidget $base

 #   if { $optionguiwidth > 0 } { 
#	$base configure -width $optionguiwidth
#    }
    eval "bind [ $base component entry ] <KeyRelease-Return> { $this GUICallbackFunction }"

    set cs [ $base childsite ]
    eval "button $cs.2 -text \"Select\" -command { $this GetMultipleSelection }"
    pack $cs.2 -side right 
    return $base
}
# -----------------------------------------------------------------------------------------------------
	
itcl::body bis_option::CreateGUIElementRange { parentwidget  } {

    # here check hint ... triplescale, scale, or entrywidget (default)

    set minv   [ lindex $valuerange 0 ]
    set maxv   [ lindex $valuerange 1 ]

    if { $minv < [ expr 0.05*$maxv ]  && $minv >= 0.0 && $maxv < 10.1 } {
	set resol [ expr 0.025* $maxv ]
	set interv [ expr 0.001*$maxv ]
    } else {
	set resol  [ expr 0.01*($maxv-$minv) ]
	set interv [ expr 0.001*($maxv-$minv) ]
    }

    if { $optiontype == "integer" } {
	set interv [ expr int($interv) ]
	if { $interv < 1 } {
	    set interv 1
	}
	set minv [ expr int($minv) ]
	set maxv [ expr int($maxv) ]
	if { $resol <1 } {
	    set resol 1
	}
    } elseif { $optiontype == "real" } {

    }

    switch $optiontypehint  {
	"triplescale" {
	    set base [ [ iwidgets::labeledwidget $parentwidget  -labeltext "${shortdescription}:"  ] childsite ]
	    scale  $base.scale -orient horizontal  -from $minv -to $maxv -resolution $resol \
		-showvalue 1  -variable [ itcl::scope thisparam($this,value) ]
	    set labeledwidget $parentwidget

	    if { $optionguiwidth < 0 } { set optionguiwidth 100  }
	    $base.scale configure -length $optionguiwidth

	    eval "bind $base.scale <ButtonRelease> { $this GUICallbackFunction }"

	    if { $minv == $maxv } {
		set entw 3 
	    } else {
		set entw [ expr int((log(($maxv-$minv)/$resol))/log(10)) + 3 ]
	    }
	    
	    if { $entw <3 } { 
		set entw  3
	    }

	    entry  $base.en  -textvariable [ itcl::scope thisparam($this,value) ] -relief sunken -width $entw
	    set valuewidget  $base.en
	    eval "bind $base.en <KeyRelease-Return> {$this GUICallbackFunction }"
	    pack $base.en    -side right -expand f
	    pack $base.scale -side left -expand t -fill x
	}
	"scale" {
	    set base [ [ iwidgets::labeledwidget $parentwidget  -labeltext "${shortdescription}:"  ] childsite ]

	    scale  $base.scale -orient horizontal  -from $minv -to $maxv -resolution $resol \
		-showvalue 1  -variable [ itcl::scope thisparam($this,value) ]
	    if { $optionguiwidth < 0 } { set optionguiwidth 100  }
	    $base.scale configure -length $optionguiwidth
	    set valuewidget  $base.scale
	    set valuerangewidget $base.scale
	    eval "bind $base.scale <ButtonRelease> { $this GUICallbackFunction }"
	    pack $base.scale -side left -expand t -fill x
	}
	"default" {
	    iwidgets::entryfield $parentwidget -labeltext "${shortdescription}:"  -validate $optiontype -textvariable [ itcl::scope thisparam($this,value) ] -relief sunken 
	    set valuewidget  $parentwidget
	    if { $optionguiwidth < 0 } { 
		catch {		set optionguiwidth [ expr int((log(($maxv-$minv)/$resol))/log(10)) + 3 ]   }
		if { $optionguiwidth < 3 } {
		    set optionguiwidth 3
		}
	    }

	    $parentwidget configure -width $optionguiwidth
	    eval "bind [ $parentwidget component entry ] <KeyRelease-Return> { $this GUICallbackFunction }"
	    #eval "bind [ $parentwidget component entry ] <Leave> { $this GUICallbackFunction }"

	}
    }



    return $parentwidget
}

itcl::body bis_option::CreateGUIElementString { base  } {
    iwidgets::entryfield $base -labeltext "${shortdescription}:"   -textvariable [ itcl::scope thisparam($this,value) ] -relief sunken 

    set valuewidget  $base
    if { $optionguiwidth > 0 } { 
	$base configure -width $optionguiwidth
    }
    eval "bind [ $base component entry ] <KeyRelease-Return> { $this GUICallbackFunction }"
    return $base
}

itcl::body bis_option::CreateGUIElementComment { base  } {

    set basea [ [ iwidgets::labeledwidget $base  -labeltext ""  ] childsite ]
    #entry $basea.o -textvariable [ itcl::scope thisparam($this,value)] -relief raised -state disabled -background black -foreground white
    set thisparam($this,textbox) [ text $basea.o -bg black -fg white ]


    if { $optionguiwidth > 0 } { 
	#	puts stderr "Option width=$optionguiwidth"
	if { $optionguiwidth <= 25 } {
	    $thisparam($this,textbox) configure -width 25 -height 1
	} else {
	    set  numlines [ expr $optionguiwidth / 25 ]
	    $thisparam($this,textbox) configure -width 25 -height [ expr $numlines +1 ] -wrap word
	}
    } else {
	$thisparam($this,textbox) configure -width 25 -height 0
	#-height 1 
    }
    $thisparam($this,textbox) insert end $thisparam($this,value)
    $thisparam($this,textbox) configure -state disabled
    pack $basea.o -side right -expand true -fill both
    set labelwidget $basea.o
    return $base
}

itcl::body bis_option::CreateGUIElementFilename { base  } {
    set valuewidget  $base
    iwidgets::entryfield $base -labeltext "${shortdescription}:"   -textvariable [ itcl::scope thisparam($this,value) ] -relief sunken  
    set labeledwidget $base

    if { $optionguiwidth > 0 } { 
	$base configure -width $optionguiwidth
    }
    eval "bind [ $base component entry ] <KeyRelease-Return> { $this GUICallbackFunction }"

    set cs [ $base childsite ]
    eval "button $cs.2 -text \"...\" -command { $this GetFileName }"

    pack $cs.2 -side right 
    return $base
}



itcl::body bis_option::CreateGUIElementBoolean { base  } {

    iwidgets::labeledwidget $base  -labeltext "${shortdescription}:" 
    set labeledwidget $base
    set w [ $base childsite ]
    set valuewidget  $w.0
    checkbutton $w.0 -variable [itcl::scope thisparam($this,value)] 
    eval "$w.0 configure -command { $this GUICallbackFunction }"
    pack $w.0 -side left

    return $base
}


itcl::body bis_option::GetFileName { } {
    
    set doinitial 0
    set initial $thisparam($this,value)
    if { [ string length $initial ] > 1 } {
	set f2tail [ file tail $initial ]
	set f2path [ file dirname $initial ]
	set doinitial 1
    }

    set mode 0
    if { $optiontypehint == "directory" } {
	# directory 
	if { $doinitial > 0 } {
	    set dirname  [tk_chooseDirectory -title "Select Directory ${shortdescription}" -initialdir $initial ]
	} else {
	    set dirname  [tk_chooseDirectory -title "Select Directory ${shortdescription}" ]
	}
	if { [ string length $dirname ] < 1 } { return 0 }
	set thisparam($this,value) $dirname
	
    } elseif { $optiontypehint == "writefile" } {
	if { $doinitial > 0 } {
	    set fname  [tk_getSaveFile -title "Select Filename for $description" -filetypes $valuerange -initialfile $f2tail -initialdir $f2path ]
	} else {
	    set fname  [tk_getSaveFile -title "Select Filename for $description" -filetypes $valuerange ]
	}
	if { [ string length $fname ] < 1 } { return 0 }
	set thisparam($this,value) $fname

    } else { 
	# filename to read
	
	if { $doinitial > 0 } {
	    set fname  [tk_getOpenFile -title "Select Filename for $description" -filetypes $valuerange -initialfile $f2tail -initialdir $f2path ]
	} else {
	    set fname  [tk_getOpenFile -title "Select Filename for $description" -filetypes $valuerange ]
	}
	if { [ string length $fname ] < 1 } { return 0 }
	set thisparam($this,value) $fname
    }

    $this GUICallbackFunction
}

# ---------------------------------------------------------------------------------------------------------------------------------------
itcl::body bis_option::GetMultipleSelection { } {

    if { $thisparam($this,selectiondialog) == 0 } {
	set tb [ iwidgets::dialog ${basewidget}.lab.selectiondialog \
		     -title "Select Items for $shortdescription" \
		     -modality application ]

	set n [ llength $valuerange ]
	$tb configure -height [ expr 80+20*$n ]  -width 300
	
	set cs [ $tb childsite ]
	set listbox [ iwidgets::scrolledlistbox $cs.a -vscrollmode dynamic -hscrollmode none -selectmode multiple -labelpos nw -visibleitems 15x10 ]
	pack $cs.a -side top -expand true -fill both
	set thisparam($this,listbox) $listbox
	eval "$tb buttonconfigure Apply -text \"Select All\" -command { $listbox selection set 0 end }"
	eval "$tb buttonconfigure Cancel  -text \"Clear All\" -command { $listbox selection clear 0 end }"
	eval "$tb buttonconfigure Help  -text \"Close\" -command { $tb deactivate }" 
	set thisparam($this,selectiondialog) $tb
	update idletasks
    }

    $thisparam($this,listbox) delete 0 end
    $thisparam($this,listbox) selection clear 0 end
    for { set i 0 } { $i < [ llength $valuerange ] } { incr i } {
	$thisparam($this,listbox) insert end [ lindex $valuerange $i ]
    }
	

    for { set i 0 } { $i < [ llength $valuerange ] } { incr i } {
	set v [ lindex $valuerange $i ]
	if { [ lsearch -exact $thisparam($this,value) $v ] >=0 } {
	    $thisparam($this,listbox) selection set $i $i
	}
    }

    
    set a  [$thisparam($this,selectiondialog) activate ] 

    if { $a > 0 } {
	set a [ [ $thisparam($this,listbox) component listbox ] curselection ]
	set thisparam($this,value) ""
	for { set i 0 } { $i < [ llength $a ] } { incr i } {
	    lappend thisparam($this,value) [  lindex $valuerange [ lindex $a $i ]]
	}

	$this GUICallbackFunction
    }
}

# ---------------------------------------------------------------------------------------------------------------------------------------
proc myprint { args } {

    puts stderr "$args"
}

if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {



    # this is essentially the main function
    wm withdraw .
    toplevel .top 
    wm title .top "Test Option"
    wm geometry .top 500x500


    set opt1 [ [ bis_option \#auto ] GetThisPointer ]
    $opt1 SetAllProperties "-r" "Registration Resolution" "Resolution" real 2.0 { 1.0 5.0 } 100
    $opt1 SetOptionType real triplescale
    $opt1 CreateGUIElement .top.1 { myprint }
    pack .top.1 -side top -expand t -fill x
    $opt1 SetValueRange { 1.0 4.0 }


    set opt2 [ [ bis_option \#auto ] GetThisPointer ]
    $opt2 SetAllProperties "-norm" "Normalize Intensities" "AutoNorm" "boolean" 1 { 0 1 } 101
    $opt2 CreateGUIElement .top.2 { myprint}
    pack .top.2 -side top -expand t -fill x


    set opt3 [ [ bis_option \#auto ] GetThisPointer ]
    $opt3 SetAllProperties "-metric" "Intensity Metric" "Metric" "listofvalues" NMI { CC MI NMI } 102
    $opt3 CreateGUIElement .top.3 { myprint}
    $opt3 SetValueRange { NMI CC }
    pack .top.3 -side top -expand t -fill x
    

    set opt4 [ [ bis_option \#auto ] GetThisPointer ]
    $opt4 SetAllProperties "-metric" "Long Comment" "Comment" "string" "Registration" {} 102
    $opt4 CreateGUIElement .top.4 { myprint}
    pack .top.4 -side top -expand t -fill x

    set opt5 [ [ bis_option \#auto ] GetThisPointer ]
    $opt5 SetAllProperties "-r2" "Registration Resolution" "Resolution" real 2.0 { 1.0 5.0 } 100
    $opt5 SetOptionType real scale
    $opt5 CreateGUIElement .top.5 { myprint }
    pack .top.5 -side top -expand t -fill x


    set opt6 [ [ bis_option \#auto ] GetThisPointer ]
    $opt6 SetAllProperties "-r2" "Number of Levels" "Levels" integer 2 { 1 6 } 100
    $opt6 configure -optionguiwidth 2
    $opt6 SetOptionType integer default
    $opt6 CreateGUIElement .top.6 { myprint }
    pack .top.6 -side top -expand t -fill x

    set opt7 [ [ bis_option \#auto ] GetThisPointer ]
    $opt7 SetAllProperties "-orientation" "Image Orientation" "Orientation" "listofvalues" Axial { Axial Coronal Sagittal } 102
    $opt7 SetOptionType listofvalues radiobuttons
    $opt7 CreateGUIElement .top.7 
    pack .top.7 -side top -expand t -fill x

    set opt77 [ [ bis_option \#auto ] GetThisPointer ]
    $opt77 SetAllProperties "-orientation" "Image Orientation" "Orientation" { multiplevalues } Red { Red Green Blue Yellow Brown } 120
    $opt77 CreateGUIElement .top.77  { myprint }
    pack .top.77 -side top -expand t -fill x


set f 0
    if { $f == 1 } {
    set opt8 [ [ bis_option \#auto ] GetThisPointer ]
    $opt8 SetAllProperties "-setupfile" "Setup File Name" "Setup:" "filename" "test.msb" { Setup Files {*.msb} } 102
    $opt8 SetOptionType filename readfile
    $opt8 CreateGUIElement .top.8
    pack .top.8 -side top -expand t -fill x

    set opt81 [ [ bis_option \#auto ] GetThisPointer ]
    $opt81 SetAllProperties "-input" "Input Image Name" "Input:" "filename" "test.nii.gz" { pxitclimage } 102
    $opt81 SetOptionType filename readfile
    $opt81 CreateGUIElement .top.81
    pack .top.81 -side top -expand t -fill x

    set opt82 [ [ bis_option \#auto ] GetThisPointer ]
    $opt82 SetAllProperties "-output" "Output Image Name Stem" "OutStem:" "filename" "test.matr" { pxitcltransform } 102
    $opt82 SetOptionType filename directory
    $opt82 CreateGUIElement .top.82
    pack .top.82 -side top -expand t -fill x

 
    }


    

}

