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


lappend auto_path [ file dirname [ info script ]]
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] base]
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] apps]

package provide bis_xmlalgorithm 1.0
package require bis_algorithm 1.0


itcl::class bis_xmlalgorithm {

    inherit bis_algorithm

     constructor { xmlfile } {	 $this Initialize $xmlfile }

    public method Initialize { xmlfile }
    public method Execute { }
    public method ExecuteDone { args }
    public method ExecuteCallback { args }
    public method GetGUIName { } { return "Pl:$algname" }

    # Parse XML stuff
    protected method InitializeFromXML { xmlfile }
    protected method InitializeFromSlicerXML { xmlelement }
    protected method InitializeFromLONIXML { xmlelement }


    # XML Basics
    protected method CleanString { line } 
    protected method PrintElement { elem n } 
    protected method ParseSlicerParameterTags { elem priority advanced } 
    protected method ParseSlicerContraints { nd ptype  }

    protected method SaveObject { obj index dir } 
    protected method CreateFilenameForObject { obj index dir } 
    protected method CreateExtensionForObject { obj } 


    # basic stuff
    protected variable algname "XML"
    protected variable commandline ""
    protected variable slicertaglist ""
    protected variable slicermaparray
    protected variable commandlineparameters
    protected variable commandlineobjects
    protected variable commandlinechannels
    protected variable inpxmlfile
    protected variable algdone 0
    protected variable inputpipe 0

}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_xmlalgorithm::Initialize { xmlfile } {

    PrintDebug "bis_xmlalgorithm::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set inputs { }
    set outputs {  }
    set options {    }

    set defaultsuffix { "_sm" }
    
    set scriptname bis_xmlalgorithm
    set completionstatus "Done"
    set forceguimode 1

    #
    #document
    #
    
    set description "Smoothes an image with a specific gaussian kernel."
    set description2 "Smoothing kernel size blursigma (in mm by default ) represents the FWHM filter size."
    set backwardcompatibility "Reimplemented from pxmat_xmlalgorithm.tcl. unit and radius options are  added. Multiple image processing eliminated,which will be recovered upon request. "
    set authors ""
    set category ""
    

    set slicertaglist { list integer  float  double  boolean  string  integer-vector  float-vector  double-vector  string-vector  integer-enumeration  float-enumeration  double-enumeration  string-enumeration  file  directory  image  geometry  point  region }
    set slicermaparray(integer) integer
    set slicermaparray(float)   real
    set slicermaparray(double)   real
    set slicermaparray(boolean) boolean
    set slicermaparray(string) string
    set slicermaparray(integer-vector) string
    set slicermaparray(float-vector) string
    set slicermaparray(double-vector) string
    set slicermaparray(string-vector) string
    set slicermaparray(integer-enumeration) listofvalues
    set slicermaparray(float-enumeration) listofvalues
    set slicermaparray(double-enumeration) listofvalues
    set slicermaparray(string-enumeration) listofvalues
    set slicermaparray(file) { filename readfile allfiles }
    set slicermaparray(directory)  { filename directory }
    set slicermaparray(image)      { object pxitclimage }
    set slicermaparray(geometry)   { object pxitclsurface }
    set slicermaparray(point)  string
    set slicermaparray(region)  filename


    set inputs ""
    set outputs ""
    set options ""
    $this InitializeFromXML $xmlfile
    lappend options [ list tmpdir  "Specify the output directory for temporary files" "Temp Directory" { filename directory 40 } "/tmp" "" 1 ]
    lappend options [ list keeptmp  "Keep  the output directory and temporary files" "Keep Temp" { boolean } 0 { 0 1 }  -1 ]
    lappend options [ list cmd      "Executable name" "Exec" { filename readfile } "" { allfiles }  -2 ]
    
    $this AddDefaultOptions
    set category "Plugin"

    set inpxmlfile $xmlfile

}
# -----------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------
#  Parse either Slicer3 or LONI pipeline xml file
# -------------------------------------------------------------------------------
itcl::body bis_xmlalgorithm::CleanString { line } {
    set line [ string trim $line ]
    regsub -all "\n" $line " " line
    regsub -all "\t" $line " " line
    regsub -all " +" $line " " line
    regsub -all " " $line "_" line
    return $line
}
# ----------------------------------------------------------------------------------
itcl::body bis_xmlalgorithm::PrintElement { elem n } {
    for { set i 0 } { $i < $n } { incr i } {
	puts -nonewline stdout "   "
    }

    puts -nonewline stdout "[ $elem GetName ]:\"[ CleanString [ $elem GetCharacterData ]]\""
    if { [ $elem GetNumberOfAttributes ] } { 
	puts -nonewline "attr=("
	for { set i 0 } { $i < [ $elem GetNumberOfAttributes ] } { incr i } {
	    puts -nonewline stdout "[ $elem GetAttributeName $i ]:\"[ CleanString [ $elem GetAttributeValue $i]]\" "
	}
	puts -nonewline ")"
    }


    for { set j 0 } { $j < [ $elem GetNumberOfNestedElements ] } { incr j } {
	set ok [ PrintElement [ $elem GetNestedElement $j ] [ expr $n +1 ] ]
    }
}

# ----------------------------------------------------------------------------------

itcl::body bis_xmlalgorithm::InitializeFromXML { xmlfile } {

    set parse [ vtkXMLDataParser New ]
    $parse SetFileName $xmlfile
    $parse SetIgnoreCharacterData 0
    $parse Parse

    set elem [ $parse GetRootElement ]
#    PrintElement $elem 0
   
    set ok 0

    if { $elem != "" } {
	set nm [ $elem GetName ]
	if { $nm == "executable" } {
	    set ok [ $this InitializeFromSlicerXML $elem ]
	} elseif { $nm == "pipeline" } {
	    set ok [ $this InitializeFromLONIXML $elem ]
	}
    }
    $parse Delete
    return $ok
}
# ---------------------------------------------------------------------
itcl::body bis_xmlalgorithm::ParseSlicerContraints { elem ptype  } {

    if { $ptype != "integer" && $ptype != "real"  } {
	return 0
    }

    set minv ""
    set maxv ""

    for { set j 0 } { $j < [ $elem GetNumberOfNestedElements ] } { incr j } {
	set nd [ $elem GetNestedElement $j ] 
	set nm [ $nd GetName ]
	if { $nm == "minimum" } { set minv [ $nd GetCharacterData ] }
	if { $nm == "maximum" } { set maxv [ $nd GetCharacterData ] }
    }

    return [ list $minv $maxv ]
}

# ----------------------------------------------------------------------

itcl::body bis_xmlalgorithm::ParseSlicerParameterTags { elem thispriority advanced } {

    set n [ $elem GetName ]
    set ind [ lsearch $slicertaglist $n ]
    if { $ind < 0 } { 
	if { $n == "label" } {
	    return [ list 0 [ $elem GetCharacterData ]  [ $elem GetName ] ]
	} 
	return [ list 0 "" [ $elem GetName ] ]
    }

    set tp $slicermaparray($n)
    set n [ lindex $tp 0 ]
    if { $n != "object" } {

	set p_type $tp
	if { [ llength $tp ] > 1 } {
	    set p_type [ list [ lindex $tp 0 ] [ lindex $tp 1 ] ]
	}
	
	if { [ llength $tp ] == 3 } {
	    set p_valrange [ lindex $tp 2 ]
	    set p_defaultvalue ""
	}

	set tval [ $elem GetAttribute fileExtensions ]
	if { $tval != "" } {
	    regsub -all "," $tval " " tval
	    set p_valrange [ list "Prefered Files" "{ $tval }" ]
	}
	
    }

    set p_valrange ""
    set p_shortdescription ""
    set p_commandswitch ""
    set p_commandswitchshort ""
    set p_description ""
    set p_defaultvalue ""
    set p_valrange ""
    set p_channel ""
    set p_extension ""
    set p_index 0
    set numinputs  [ llength $inputs ] 
    set numoutputs [ llength $outputs ] 

    set addedoption 0

    for { set j 0 } { $j < [ $elem GetNumberOfNestedElements ] } { incr j } {
	set nd [ $elem GetNestedElement $j ] 
	set nm [ $nd GetName ]
	switch -exact $nm {
	    "label" {      set p_shortdescription [ $nd GetCharacterData ] }
	    "longflag" {    set p_commandswitch   [ $nd GetCharacterData ] }
	    "flag" {    set p_commandswitchshort   [ $nd GetCharacterData ] }
	    "description" { set p_description     [ $nd GetCharacterData ] } 
	    "default"     { set p_defaultvalue    [ $nd GetCharacterData ] } 
	    "constraints" { set p_valrange [ $this ParseSlicerContraints $nd $p_type ] }
	    "element"     { if { $p_type == "listofvalues" } { lappend p_valrange [ $nd GetCharacterData ] } }
	    "channel"     { set p_channel         [ $nd GetCharacterData ] }
	    "index"       { set p_index           [ $nd GetCharacterData ] }
	}
    }

    set cname ""
    if { $p_commandswitch != "" } {
	set cname $p_commandswitch
    } else {
	set cname $p_commandswitchshort
    }
    

    if { $n != "object" } {
	set paramname "param$thispriority"

	if { $cname != "" } {
	    if { $advanced > 0 } {
		set thispriority [ expr - $thispriority ]
	    }
	    set plist [ list $paramname  $p_description $p_shortdescription  $p_type  $p_defaultvalue  $p_valrange  $thispriority  ]
	    lappend options $plist
	    set commandlineparameters($paramname) $cname
	    set addedoption 1
	} else {
	    puts stderr "Skipping parameters  $p_description"
	}
    } else {
	if { $p_channel == "input" } {
	    incr numinputs
	    set cflag inp$numinputs
	    set plist  [ list $cflag "$p_description" [ lindex $tp 1 ] "$p_defaultvalue"  $numinputs ]
	    if { $cname != "" } {
		set commandlineobjects($cflag) [ list $cname input ]
		lappend inputs $plist
	    } elseif { $p_index !="" } {
		set commandlinechannels(${p_index}) [ list $cflag input ]
		lappend inputs $plist
	    } else {
		puts stderr "Skipping input  $p_description"
	    }

	} else {
	    incr numoutputs
	    set cflag out$numoutputs
	    set plist  [ list  $cflag "$p_description" [ lindex $tp 1 ] "$p_defaultvalue"  $numoutputs ]
	    if { $cname != "" } {
		set commandlineobjects($cflag) [ list $cname output ]
		lappend outputs $plist
	    } elseif { $p_index !="" } {
		set commandlinechannels(${p_index}) [ list $cflag output ]
		lappend outputs $plist
	    } else {
		puts stderr "Skipping input  $p_description"
	    }
	}
    }

    return [ list $addedoption "" [ $elem GetName ] $thispriority ]

}
# ---------------------------------------------------------------------

itcl::body bis_xmlalgorithm::InitializeFromSlicerXML { xmlelement } {

#    puts stderr "In Slicer"
    set elem [ $xmlelement LookupElementWithName "title" ]
    if { $elem !="" } {    set algname [ string trim [ $elem GetCharacterData ] ]}
    
    set elem [ $xmlelement LookupElementWithName "description" ]
    if { $elem !="" } {    set description [ $elem GetCharacterData ] }

    set lname { version documentation_url license contributor }
    for { set i 0 } { $i < [ llength $lname ] } { incr i } {
	set elem [ $xmlelement LookupElementWithName [ lindex $lname $i ] ]
	if { $elem !="" } {    append description2 "[lindex $lname $i]:[ $elem GetCharacterData ] " }
    }
	
    set plist ""
    for { set j 0 } { $j < [ $xmlelement GetNumberOfNestedElements ] } { incr j } {
	set elem [ $xmlelement GetNestedElement $j ] 
	if { [ $elem GetName ] == "parameters" } {
	    lappend plist $elem
	}
    }

    lappend options [ list about  "$description"  "Name"  { comment "" 35 } $algname $algname 0 ]
    lappend options [ list about2 "$description $description2"  ""  { comment "" 100 } "$description $description2" "" 1 ]
#    lappend options [ list guicmt$pelement "Parameter group $labelname"  "Parameter Set"  comment $labelname $labelname $labelpriority ]
#    lappend options [ list guicmt$pelement "Parameter group $labelname"  "Parameter Set"  comment $labelname $labelname $labelpriority ]

    set thispriority 10

    for { set pelement 0 } { $pelement <  [ llength $plist ] } { incr pelement } {
	set  nd [ lindex $plist $pelement ]
	set labelname 0
	set labelpriority $thispriority
	set numadded 0
	incr thispriority
	set advanced 0
	if { [ $nd GetAttribute "advanced" ] == "true" } {
	    set advanced 1
	}

	for { set j 0 } { $j < [ $nd GetNumberOfNestedElements ] } { incr j } {
	    set lst [ $this ParseSlicerParameterTags [ $nd GetNestedElement $j ]   $thispriority   $advanced ]
	    #	    puts stderr $lst
	    set v [ lindex $lst 0 ]
	    if { $v > 0 } {
		incr numadded
		incr thispriority 
	    }
	    if { [ lindex $lst 1 ] != "" } {
		set labelname [ lindex $lst 1 ]
	    }
	}
	if { $numadded > 0 && $labelname != "" } {
	    if { $advanced > 0 } {
		set labelpriority [ expr  -$labelpriority ]
	    } 
	    set n [ $nd GetAttribute advanced ]
	    lappend options [ list guicmt$pelement "Parameter group $labelname $n"  "Parameter Set"  comment $labelname $labelname $labelpriority ]
	}
    }
    #    foreach inp $inputs { puts stderr "Input=$inp" }
    #    puts stderr ""
    #    foreach inp $outputs { puts stderr "Output=$inp" }
    #    puts stderr ""
    #    foreach inp $options { puts stderr "Option=$inp" }
    
}
 
# ----------------------------------------------------------------------

itcl::body bis_xmlalgorithm::InitializeFromLONIXML { xmlelement } {

    #    puts stderr "In LONI"
    set elem [ $xmlelement LookupElementWithName "module" ]
    
    PrintElement $elem 0
    return 1
}




# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------
itcl::body bis_xmlalgorithm::SaveObject { obj index odir }  {

    set oldfname [ $obj cget -filename ]
    set f [ $this CreateFilenameForObject $obj $index $odir ]
    $obj Save  $f
    $obj configure -filename $oldfname
    return $f

}
# ----------------------------------------------------------------------------------------
itcl::body bis_xmlalgorithm::CreateFilenameForObject { obj index odir }  {

    set ext [ $this CreateExtensionForObject $obj ]
    set name [ file join $odir object_${index}$ext ]
    $obj configure -filename $name
    return $name

}
 
itcl::body bis_xmlalgorithm::CreateExtensionForObject { obj }  {
    
    #    puts stderr "$obj , [ $obj info class ]"

    set ext ".txt"
    switch -exact [ $obj info class ] {
	"::pxitclimage"   { set ext ".nii.gz" }
	"::pxitclsurface"  { set ext ".vtk" }
    }

    return $ext
}
# ----------------------------------------------------------------------------------------
itcl::body bis_xmlalgorithm::Execute {  } {
    set cmdline "[ $OptionsArray(cmd) GetValue ] "
    set command [ file tail $cmdline ]

    set names [array names commandlineparameters ]

    foreach name $names { 
	set flag $commandlineparameters($name)  
	set val [ $OptionsArray($name) GetValue ]
	append cmdline "$flag $val "
    }

    set names [array names commandlineobjects ]

    set obase [ file join [ $OptionsArray(tmpdir) GetValue ] [ pid ]]
    set i 0
    set odir "${obase}_bistmp_${i}"
    while { [ file exists $odir ] } {
	incr i
	set odir "${obase}_${i}"
	
    }
    file mkdir $odir
    puts  stdout "making temp directory $odir"

    set usingoutputs ""

    
    set i 0
    foreach name $names { 
	set lst $commandlineobjects($name)  

	set flag [ lindex $lst 0 ]
	set inout [ lindex $lst 1 ]
	if { $inout == "input" } {
	    set val [ $this SaveObject [  $InputsArray($name)  GetObject ] $i $odir ]
	} else {
	    set val [ $this CreateFilenameForObject [  $OutputsArray($name)  GetObject ] [ expr $i + 100 ] $odir ]
	    lappend usingoutputs $name
	}
	append cmdline "$flag $val"
	incr i
    }


    set names [ array names commandlinechannels ]
    set names [lsort -increasing  $names ]
    for { set i 0 } { $i < [ llength $names ] } { incr i } { 
	set name  [ lindex $names $i ]
	set lst $commandlinechannels($name)  
	set flag [ lindex $lst 0 ]
	set inout [ lindex $lst 1 ]
	puts stderr "looking at $name, $flag $inout"
	if { $inout == "input" } {
	    set val [ $this SaveObject [  $InputsArray($flag) GetObject ] $i $odir ]
	} else {
	    set val [ $this CreateFilenameForObject [  $OutputsArray($flag)  GetObject ] [ expr $i + 100 ] $odir ]
	    lappend usingoutputs $flag
	}
	append cmdline "$val "
    }


    
    set algdone 0
    puts stdout "cmdline=\n$cmdline"

    if { $guimode == "standalone" } {
	wm geometry $basewidget 1280x700
    }

    set c [ file tail [ $OptionsArray(cmd) GetValue ] ]

    set inputpipe 0
    if { [catch {  set inputpipe [ open "| $cmdline 2>@1 " ] } ] } {
	puts stderr "Error invoking $cmdline"
	delete -force $odir
	return 0
    }

    puts stderr "Done invoking $inputpipe"
    fileevent $inputpipe readable [ list $this ExecuteCallback ]
    
    pxtkconsole
    after 50
    update 
    while { $algdone == 0 } {
	after 1000
	update
    }

    foreach objname $usingoutputs {
	[ $OutputsArray($objname) GetObject ] Load
	$OutputsArray($objname) UpdateInternalGUI
    }


    if { [ $OptionsArray(keeptmp) GetValue ] == 0 } {
	puts stdout "Removing directory $odir"
	file delete -force $odir
    }

    ::pxtclutil::Info "Execution of  Plugin $command done"

}

itcl::body bis_xmlalgorithm::ExecuteDone { args } {
    puts stderr "In Done ..............."
    catch {close $inputpipe }
    set inputpipe 0
    set algdone 1
}

itcl::body bis_xmlalgorithm::ExecuteCallback { args } {


    if { $inputpipe == 0 } {
	return
    }

    if {  [eof $inputpipe ]  } {
	return [ $this ExecuteDone ]
    }

    set ok 1

    while { $ok ==1 } {
	if { $inputpipe !=0 } {
	    set ok [ gets $inputpipe nm ] 
	    if { $ok } {
		pxtkprint "$nm\n"
		
		set f [ string first "<filter-progress>" $nm ]
		if { $f == 0 } {
		    set ind [ expr [ string first ">" $nm ] +1 ]
		    set ind2 [ expr [ string first "</filter-progress>" $nm ] -1 ]
		    set t [ expr [ string range $nm $ind $ind2 ] ]
		    $this ShowProgressVal Running $t 
		}
	    }
	} else {
	    set ok 0
	}
    }

    if { $inputpipe == 0 } {
	return
    }

    if {  [eof $inputpipe ]  } {
	$this ExecuteDone
    }

}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_xmlalgorithm.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_xmlalgorithm [pxvtable::vnewobj] [ lindex $argv 0 ] ]
    set argv [ lrange $argv 1 end ]
    $alg MainFunction 
}





