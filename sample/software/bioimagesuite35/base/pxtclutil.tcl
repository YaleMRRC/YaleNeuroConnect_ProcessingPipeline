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

package provide pxtclutil 1.0




package require pxvtable 1.0

# 	$Id: pxtclutil.tcl,v 1.2 2002/02/22 23:18:07 Xenios Exp $	


namespace eval ::pxtclutil {
    
    namespace export  ReadArray SaveArray PrintArray CreateTriple CreateInputFile LoadParameters SaveParameters ShowWindow HideWindow  ExportJPEGImage ColorBox FindCommandInPath

    # Some Quick Dialog Boxes
    # ------------------------

    proc GetAbsoluteFileName { fname } {
	if { [ file pathtype $fname ] == "relative" } {
	    set out [ file join [ pwd ] $fname ]
	    regsub -all  "/./" $out "/" out
	} else {
	    set out $fname
	}
	
	return $out
    }

    proc Info    { message } { 
	set a 0
	catch { set a [ llength [ winfo children . ] ] }
	if { $a > 1 } {
	    tk_messageBox -type ok -message $message -title "For your information ..." -icon info
	} else {
	    puts stdout "Info -- $message"
	}
    }

    proc Warning { message } {
	set a 0
	catch { set a [ llength [ winfo children . ] ] }
	if { $a > 1 } {
	    tk_messageBox -type ok -message $message -title "Error!" -icon error
	} else {
	    puts stderr "Error -- $message"
	}
    }

    proc Question { message } {
	set ok [ tk_messageBox -type yesno -default no -title "Think again ..." -message $message -icon question  ]
	if { $ok == "yes" } {
	    return 1
	}  else {
	    return 0
	}
    }


    proc Question2 { message } {
	set ok [ tk_messageBox -type yesnocancel -default no -title "Think again ..." -message $message -icon question  ]
	if { $ok == "yes" } {
	    return 1
	}  elseif { $ok=="no" } {
	    return 0
	} else {
	    return -1
	}
    }

    proc GetLinearSuffix { } { return "affine.matr" } 
    proc GetNonLinearSuffix { } { return "grid.grd" } 
    proc GetNonLinearRPMSuffix { } { return "rpm.grd" } 

    proc GenerateFilename { name1 name2 identifier suffix { basedir "" } { filenametype 0 } } {

	set f1a [ file tail [ file dirname $name1 ]]
	set f1b [ file root [ file tail $name1 ]]
	set f2a [ file tail [ file dirname $name2 ]]
	set f2b [ file root [ file tail $name2 ]]
	if { $filenametype > 0 } {
	    set newname "${f1a}${f1b}_${f2a}${f2b}_${identifier}_${suffix}"
	} else {
	    set newname "${f1b}_${f2b}_${identifier}_${suffix}"
	}
	if { $basedir != "" } {
	    set newname [ file join $basedir $newname ]
	}
	return $newname
    }

    # Show/Hide Window Stuff
    proc ShowWindow { w } { 
	wm deiconify $w ; raise $w ;
	set geom ""
	catch { set geom [ winfo geometry [ winfo parent $w ]] }
	if { [ string length $geom ] > 2 } {
	    
	    set offset [ lsearch [ winfo children [ winfo parent $w ]] $w ]
	    
	    scan $geom "%dx%d+%d+%d" w0 h0 x0 y0
	    set x0 [ expr $x0+$w0/2+20*$offset]
	    set y0 [ expr $y0+5+10*$offset ]
	    wm geometry $w "+$x0+$y0"
	}
    }
    
    proc HideWindow { w } {
	set len [ llength [ winfo children $w ]]
	if { $len > 0 } {
	    for { set k 0 } { $k < $len } { incr k } { 
		set a [ lindex [ winfo children $w ] $k ]
		if { [ winfo class $a ] == "Toplevel"} {
		    HideWindow $a
		}
	    }
	}
	wm withdraw $w
    }


    # A Complex GUI Element
    # ---------------------
    proc CreateTriple {base2 name variable range1 range2 resol interv length } {
	
	set base [ LabelFrame:create $base2 -text $name ]
	pack $base2 -side left -padx 3 -pady 1 -expand t -fill both

	entry  $base.en -width 5 -textvariable $variable -relief sunken
	scale  $base.sc -orient horizontal  -from $range1 -to $range2 -resolution $resol -bigincrement $interv -showvalue 0 -length $length -variable $variable
	pack $base.sc $base.en -side left -expand true -fill x
	
	return $base.sc
    }

    proc CreateInputFile { f name tvar } {

	frame  $f -relief raised
	pack $f -side top -expand true -fill x -padx 2 -pady 2

	label  $f.name -text $name
	set cmd " entry  $f.entry -width 35 -textvariable $tvar "
	eval $cmd
	button $f.but -text "Browse"

	pack $f.name $f.entry  -side left -fill x -pady 5 -expand true
	pack $f.but -side left -pady 5 
	return $f.but
    }

    # --------------------------------------------------
    # --------------------------------------------------
    # Save Array from file including possible headerline
    # --------------------------------------------------

    proc printArrays {args} {
	foreach array $args {
	    upvar $array data
	    foreach name [lsort [array names data]] {
		puts "$array\($name\) = $data($name)"
	    }
	}
    }
    # --------------------------------------------------
    proc PrintArray { varname } {
	::pxtclutil::SaveArray "" $varname "Debug Info"
    }

    proc SaveArray { fname varname2 headerline } {
	SaveArrayComplex $fname $varname2 $headerline "" 
    }

    # --------------------------------------------------
    proc SaveArrayComplex { fname varname2 headerline exclude } {
	
	upvar #0 $varname2 varname

	set len [ string length $exclude ]
	set keylist { }
	foreach { key value } [array get varname] {
	    if { $len > 0 } {
		if { [ string equal -length $len $key $exclude ] == 0 } {
		    set keylist [concat $keylist $key]
		}
	    } else {
		set keylist [concat $keylist $key]
	    }
	}
	set keylist [lsort -ascii $keylist]
	
	if { [string length $fname] > 0 } {
	    set fileid [open $fname w]
	} else {
	    set fileid stdout
	}
	
	if { [ string length $headerline  ] > 0 } {
	    puts $fileid "$headerline"
	    puts $fileid "--------------------"
	}
	
	for { set k 0 } { $k < [llength $keylist] } { incr k } {
	    set key [lindex $keylist $k]
	    puts $fileid "$key  : $varname($key)"
	}
	
	if {$fileid != "stdout" } {
	    close $fileid
	}
    }

    # --------------------------------------------------
    proc SaveArrayList { fname varname2 headerline paramlist } {
	
	upvar #0 $varname2 varname

	set keylist [ array names varname ]
	
	if { [string length $fname] > 0 } {
	    set fileid [open $fname w]
	} else {
	    set fileid stdout
	}
	
	if { [ string length $headerline  ] > 0 } {
	    puts $fileid "$headerline"
	    puts $fileid "--------------------"
	}
	
	for { set k 0 } { $k < [llength $paramlist] } { incr k } {

	    set key [lindex $paramlist $k]
	    set value ""
	    set ind [ lsearch  -exact $keylist $key ]
	    if { $ind >=0 } {
		set value $varname($key)
	    }
	    if { [ string length $value] > 0 } {
		puts $fileid "$key  : $value"
	    }
	}
	
	if {$fileid != "stdout" } {
	    close $fileid
	}
    }
    # --------------------------------------------------

    proc SaveParameters { param headerline  } {
	SaveParametersComplex $param $headerline ""
    }

    proc SaveParametersComplex { param headerline exclude } {
	set fname [tk_getSaveFile -title "Filename" -defaultextension .log  -filetypes { {"Log files" {.log}}}]
	if { [string length  $fname] < 1 } { return}
	::pxtclutil::SaveArrayComplex $fname $param $headerline $exclude
	return $fname
    }
    
    proc SaveParametersList { param headerline paramlist } {
	set fname [tk_getSaveFile -title "Filename" -defaultextension .log  -filetypes { {"Log files" {.log}}}]
	if { [string length  $fname] < 1 } { return}
	::pxtclutil::SaveArrayList $fname $param $headerline $paramlist
	return $fname
    }

    # --------------------------------------------------
    # Read Array from file including possible headerline
    # --------------------------------------------------
    proc ReadArray { fname varname2 headerline } {
	
	upvar #0 $varname2 varname
	
	
	if { [string length $fname] < 1 } {
	    return 0
	}
	
	if { [ file exists $fname ]  == 0 } {
	    return 0
	}
	
	set fileid [open $fname r]
	
	# Eliminate Header 
	
	if { [ string length $headerline ] > 0 } {
	    gets $fileid line
	    if { [string compare $line $headerline] !=0 } {
		::pxtclutil::Warning "Cannot read parameter file\n Desired = $headerline \n Actual = $line"
		close $fileid
		return 0 
	    } else {
		gets $fileid line
	    }
	}
	
	while { [ gets $fileid line ] >=0 } {
	    set index [string first ":" $line]
	    
	    if { $index > 0 }  {
		set len   [string length $line]
		
		set key   [string trim   [string range $line 0 [expr $index - 1]]]
		set value [string trim [string range $line [expr $index +1] [expr $len -1]]]
		set varname($key)  $value 
	    }
	}  
	close $fileid
	return 1
    }
	
    # --------------------------------------------------
    proc ReadArrayList { fname varname2 headerline paramlist } {
	
	upvar #0 $varname2 varname
	
	
	if { [string length $fname] < 1 } {
	    return 0
	}
	
	if { [ file exists $fname ]  == 0 } {
	    return 0
	}
	
	set fileid [open $fname r]
	
	# Eliminate Header 
	
	if { [ string length $headerline ] > 0 } {
	    gets $fileid line
	    if { [string compare $line $headerline] !=0 } {
		::pxtclutil::Warning "Cannot read parameter file\n Desired = $headerline \n Actual = $line"
		close $fileid
		return  0
	    } else {
		gets $fileid line
	    }
	}
	
	while { [ gets $fileid line ] >=0 } {

	    if { [ string  first "#" $line ] != 0 } {
		set index [string first ":" $line]
		
		if { $index > 0 }  {
		    set len   [string length $line]
		    set key   [string trim   [string range $line 0 [expr $index - 1]]]
		    set value [string trim [string range $line [expr $index +1] [expr $len -1]]]
		    
		    if { [ lsearch -exact $paramlist $key ] >=0 } {
			set varname($key)  $value 
		    }
		}
	    } else {
		puts stdout "Comment Line $line"
	    }
	}  
	close $fileid
	return 1
    }
	
    # ---------------------------------------------------------------------------------
    
    proc LoadParameters { param headerline} {

	set fname [tk_getOpenFile -title "Filename" -filetypes { {"Log files" {.log}}}]
	if { [string length  $fname] < 1 } { return  }
	
	return [ ::pxtclutil::ReadArray $fname $param $headerline ]
    }

    proc LoadParametersList { param headerline paramlist} {

	set fname [tk_getOpenFile -title "Filename" -filetypes { {"Log files" {.log}}}]
	if { [string length  $fname] < 1 } { return  }
	
	::pxtclutil::ReadArrayList $fname $param $headerline $paramlist
	return $fname
    }


    # ---------------------------------------------------------------------------------
    #   Matrix Stuff
    # ---------------------------------------------------------------------------------
    proc SaveMatrix { matr { fname "" } } {

	if { [string length  $fname] > 0 } {
	    if [ catch { set fileid [open $fname w] } ] {
		return 0
	    }
	} else {
	    set fileid stdout
	    puts stdout "Matrix Elements\n-------------\n"
	}
	    
	for { set i 0 } { $i < 4 } { incr i } {
	    for { set j 0 } { $j < 4 } { incr j } {
		set key [$matr GetElement $i $j]
		set line [ format "%6.3f " $key ]
		puts -nonewline $fileid  "$line"
	    }
	    puts $fileid ""
	}

	if { $fileid != "stdout" } {
	    close $fileid
	}
	return 1
    }

    proc LoadMatrix { matr fname } {
	
	if { [string length  $fname] < 1 } {  return 0 }
	
	if { [ file exists $fname ] == 0 } {
	    return 0
	}
	set fileid [open $fname r]
	
	for { set i 0 } { $i < 4} { incr i } {
	    set a [ gets $fileid line ]
	    if { $a > 0 } { 
		set row $line
		if { [llength $row] == 4 } {
		    for { set j 0 } {$j < 4} { incr j } {
			$matr SetElement $i $j [lindex $row $j ]
		    }
		}
	    }
	}
	close $fileid
	return 1
    }

    # ---------------------------------------------------------------------------------
    #   Export as JPEG Stuff
    # ---------------------------------------------------------------------------------

    proc ExportJPEGImage { fname img } {

	set f $fname

	if { $f == "" } { return }

	set ok 0

	set data [ [ $img  GetPointData ] GetScalars ]
	$data Modified
	set r0 [lindex [$data GetRange] 0]
	set r1 [lindex [$data GetRange] 1]

	set sc [ vtkImageShiftScale [ pxvtable::vnewobj ]]
	$sc SetInput $img
	$sc SetOutputScalarTypeToUnsignedChar 
	$sc SetScale [ expr 255.0 / ($r1 - $r0 )]
	$sc SetShift [ expr -1.0* $r0 ]
	$sc Update

	set data [ [ [ $sc GetOutput ]  GetPointData ] GetScalars ]
	set r0 [lindex [$data GetRange] 0]
	set r1 [lindex [$data GetRange] 1]

	set tiffwriter [ vtkJPEGWriter [ pxvtable::vnewobj  ] ]
	$tiffwriter DebugOn
	$tiffwriter SetFileDimensionality 2
	puts stderr "File Prefix [ file rootname $fname ]"
	$tiffwriter SetFilePrefix [ file rootname $fname ]
	$tiffwriter SetFilePattern "%s_%d.jpg"
	$tiffwriter SetInput [ $sc GetOutput] 
	$tiffwriter Write
	catch { $tiffwriter Delete }
	catch { $sc Delete }
    }


    #  ArrayEditor Stuff 
    # ------------------------------------------

        
    proc CreateGlobalArrayEditor { arrayname comment loadcommand savecommand resetcommand } {

	upvar #0 $arrayname varname

	set top [ pxvtable::vnewobj]
	set dlg [ toplevel .$top ]
	wm withdraw $dlg

	label $dlg.o -bg black -fg white -text $comment
	pack $dlg.o -side top -expand t -fill x -pady 5
	frame $dlg.bot  
	pack $dlg.bot -side bottom -pady 15 -expand t -fill x


	set keylist ""
	foreach { key value } [array get varname] {
	    set keylist [concat $keylist $key]
	}
	set keylist [lsort -ascii $keylist]
	set len [  llength $keylist  ]
	
	for { set k 0 } { $k < $len } { incr k } {
	    frame $dlg.$k ;
	    pack $dlg.$k -side top -expand t -fill x
	    set name [ lindex $keylist  $k ] 

	    label $dlg.$k.l -text $name -width 20
	    eval "entry $dlg.$k.e -textvariable ${arrayname}($name) -width 50"
	    pack $dlg.$k.l $dlg.$k.e -side left -expand f -padx 10
	}
	
	eval "button $dlg.bot.close -text Close -command { wm withdraw $dlg }"
        eval "button $dlg.bot.load -text ReLoad -command { $loadcommand }"
        eval "button $dlg.bot.save -text Save   -command { $savecommand }"
        eval "button $dlg.bot.def -text Defaults   -command { $resetcommand }"
	
	pack $dlg.bot.load $dlg.bot.save $dlg.bot.def $dlg.bot.close -side left -expand t -padx 20 -fill x
	return $dlg
    }

    proc GetIpAddress {} {
	set ip 255.255.255.0
        catch { set me [socket -server garbage_word -myaddr [info hostname] 0];set ip [lindex [fconfigure $me -sockname] 0];close $me; }
	return $ip
    }

    proc GetAllInfo {} {
	global tcl_platform
	global tcl_version
	global auto_path 

	set m0 $tcl_platform(user)
	set m1 $tcl_platform(os)
	set m2 $tcl_platform(osVersion)
	set m3 $tcl_version
	set m24 [ info nameofexecutable ]

	set m5 [ file normalize [ file join $::pxtclvtkpxcontrib::baselibrarypath  $::pxtclvtkpxcontrib::librarypath ] ]
	set m5 "$m5, $::pxtclvtkpxcontrib::osmode "

       	#puts stderr "m5=$m5"
	set m4 ""
    
	catch { 
	    set m4 "([ GetIpAddress ])"
	}
	return "User $m0 on [ info hostname ] $m4\n OS=$m1 ($m2)\n using $m24 $m3\nLibrary Directory=$m5"
    }

    proc ColorBox { inp_title inp_color inp_parent } {

	for { set i 0 } { $i <=2 } { incr i } {
	    set c($i) [ lindex $inp_color $i ]
	    if { $c($i) < 0 } {
		set c($i) 0.0
	    } elseif { $c($i) > 1.0 } {
		set c($i) 1.0
	    }

	    set c($i) [ expr round($c($i) *255.0) ]
	}
	
	set line [ format "\#%02x%02x%02x"  $c(0) $c(1) $c(2) ]

	set out [ tk_chooseColor -title $inp_title -initialcolor $line -parent $inp_parent ]
	#	puts stdout "out color = $out"

	if { [ string length $out ] > 0 } {
	    set out_list ""

	    for { set i 0 } { $i <=2 } { incr i } {
		set m [ expr 2*$i +1  ]
		set n [ expr $m + 1 ]
		set t [ string range $out $m $n ]
		scan $t "%x" t1
		lappend out_list [ expr $t1/255.0 ]
	    }
	    return $out_list
	} else {
	    return $inp_color
	}
    }

    proc FindCommandInPath { cmd } {

	global tcl_platform
	global env

	set exename [ info nameofexecutable ]
	if { [ string first cygwin $exename ] > 0 } {
	    set cygwin 1
	} else {
	    set cygwin 0
	}


	if { $tcl_platform(platform) == "windows" && $cygwin == 0 } {
	    set divider ";"
	} else {
	    set divider ":"
	}
	

	set plist [ split $env(PATH) $divider ]
	set ppath ""
	set flag 0
	set len [ llength $plist ]
	set i 0
	while { $i < $len && $flag == 0 } {
	    set ppath [ lindex $plist $i ]
	    set out   [ file join $ppath ${cmd} ]
	    if { [ file exists $out ] == 1 } {
		set flag 1
		set i $len
	    } else {
		incr i
	    }
	}

	if { $flag == 0 } {
	    return 0
	}
	
	return $out
    }


    proc GenerateVOIFileNameFromImageName { objectmapname } { 

	set tname [ file rootname $objectmapname ]
	set ff [ file extension $objectmapname ]
	if { $ff == ".gz" } {
	    set tname [ file rootname $tname ]
	}
	set tname "${tname}.txt"
	return $tname
    }

    proc LoadVOINamesList { tname numc } {

	if { $numc < 2 } {
	    set numc 2 
	} elseif { $numc > 255 } {
	    set numc 255
	}
	
	set tmpname(0) "Background"
	for { set i 1 } { $i < $numc } { incr i } {
	    set tmpname($i) "Region $i"
	}
	
	puts stderr "Reading Names from $tname"

	# Read Objectmap Colors
	if { [ file exists $tname ] == 0 } {
	    return  [ array get tmpname ]
	}


	set fileid [open $tname r]

	# Eliminate Header 
	set found 0
	while { [ gets $fileid line ] >=0 } {
	    #puts stderr "Testing line \"$line\""
	    if { [  string range $line 0 0 ] == "\#" || [ string range $line 0 0 ] == "\[" } {
		
	    } else {
		set index [string first ":" $line]
		set lst ""
		if { $index > 0 } {
		    set lst [ split $line ":" ]
		} else {
		    set index [string first "\t" $line]
		    if { $index > 0 } {
			set lst [ split $line "\t" ]
		    }
		}
		if { $lst != "" } {
		    set index   [ string trim [ lindex $lst 0 ] ]
		    set value   [ string trim [ lindex $lst 1 ] ]
		    set tmpname($index) $value
		}
	    }
	}
	close $fileid
    
	return  [ array get tmpname ]
    }

}


