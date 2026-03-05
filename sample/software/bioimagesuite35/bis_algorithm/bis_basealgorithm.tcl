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

package provide bis_basealgorithm 1.0

#
# bis_basealgorithm.tcl
# 
#  Do we want to add
#
#  bis_optionslist class
#  bis_objectlist  class
#
#

package require  Itcl
package require  cmdline

package require bis_option 1.0
package require bis_object 1.0
package require bis_common 1.0

package require Iwidgets 

package require pxitclobject 1.0
#package require pxtcluserprefs 1.0

#
# bis_basealgorithm class
#

itcl::class bis_basealgorithm {

    #
    #public
    #

    constructor { } { }
    destructor { $this CleanAll }


    # This Pointer
    public method GetThisPointer { } { return $this }

    # Some Methods you mant to override
    # ----------------------------------
    public method  UpdateOutputFilenames { } { return 1 }

    # The rest is pretty fixed at this point
    # --------------------------------------
    #Get command line options list
    public method  GetCmdLineOptionsList { }

    #Get list from interenal arrays
    public method  GetOptionsList { }
    public method  GetInputsList { }
    public method  GetOutputsList { }

    # -----------------------------------------------------------
    # vtk-like interface to Modify/access invidual option and inputs outputs
    # -----------------------------------------------------------
    public method SetOptionValue  { optionname value }
    public method GetOptionValue  { optionname }
    public method GetOptionType  { optionname }
    public method SetInputObject  { inputname obj }
    public method GetInputObject  { inputname }
    public method GetOutputObject { outputname }

    public method GetOutputBisObject { outputname }
    public method GetInputBisObject  { inputname }

    public method RenameInput     { id newname { newpriority -1 } }
    public method RenameOutput    { id newname { newpriority -1 } }
    public method GetInputName    { id }
    
    #Set parameter values and file names to internal arrays
    protected method  SetArguments { parameterlist filelist }

    #Set parameter values to internal bis_option arrays
    public method  SetParameters   { plist } 

    #This handle parameter set stuff
    protected method HandleParameterSetArgument { plist } { }

    #Clean List and Make Sure Priorities are Sorted
    protected method CleanAndSortPriorities { inplist fld } 

    # Set bis_object of InputsArray from a bis_object list Why do we nee this ?
    public method  SetInputObjects { objectlist }

    # Prints InputsArray
    public method  PrintObjectList { } 

    # Clean InputsArray and OutputsArray
    public method  CleanAll {  }
    public method  CleanInputsArray {  }
    public method  CleanOutputsArray {  }
    public method  AddLog { comment } { lappend Log $comment }

    #print usage
    public method  PrintUsage {  } 

    #Get help related information 
    public method  GetUsage         {  } { return $Usage }
    public method  GetDescription   {  } { return  $description}
    public method  GetDescription2  {  } { return  $description2}
    public method  GetCategory      {  } { return  $category}
    public method  SetCategory      { c } { set  category $c}
    public method  GetAuthors       {  } { return  $authors }
    public method  GetBackwardCompatibility { } { return $backwardcompatibility }
    public method  GetSeeAlso       {  } {reurn $seealso }

   # Get formatted help information (mode = stdout or html or tex )
    public method  GetDetailDescription   { mode } 
    public method  GetSynopsis            { mode } 

    # Load bis_object to InputsArray from files
    public method  LoadObjects { }

    # Save bis_object of OutputsArray
    public method  SaveObjects { { forcedir "" } { updatefilenames 1 } }

    # Memory preservation stuff
    public method ClearInputs { }
    public method ClearOutputs { }


    # Get Name of Script
    public method GetScriptName { } { return $scriptname }
    public method GetCompletionStatus { } { return $completionstatus }




    #Debug switch
    public method  DebugOn   { } {   set debug 1 }
    public method  DebugOff  { } {   set debug 0 }

    #print debug message only when DebugON
    public method  PrintDebug { msg } { 
	if {$debug == 1 } {
	    if { [ catch { pxtkprint "$msg\n" } ] } { puts stdout "$msg" }
	}
    }

    # Set Log from arguments specified (=argv_org) and filelist
    public method   SetLog { str  } { 	
	set  scr  [info script]
	set  Log [concat  $scr $str ]    
    }

    #Save log files if "testlog" or "log" option is specified
    #If testlog specified,information for testing saved in  bis_common::bis_testlog
    #If log specified,additional log file will be saved
    public method   SaveTestLog {  }

    #
    #protected
    #
    protected variable containerobject 0
    protected variable eventcontainerobject 0

    # Mode
    # managed, standalone, commandline
    protected variable guimode "managed"
    protected variable errormessage ""
    protected variable resultmessage ""

    public method GetResultsMessage { } { return $resultmessage }
    public method GetErrorMessage { } { return $errormessage }

    #Help related information 
    protected variable category ""
    protected variable description ""
    protected variable description2 ""
    protected variable Synopsis ""
    protected variable Usage ""
    protected variable scriptname ""
    protected variable completionstatus "Not specified"
    protected variable backwardcompatibility  ""
    protected variable seealso  ""
    protected variable authors  ""

    #Internal tcl array for input files 
    #output files and options. See bis_option.tcl 
    #bis_object.tcl
    protected variable InputsArray
    protected variable OutputsArray
    protected variable OptionsArray
    protected variable StandardOptionsList ""
    protected variable AdvancedOptionsList ""

    #Log related
    protected variable debug 0
    protected variable Log ""
    protected variable PreserveHistory 0

    #
    #Inputs, Outputs and Options
    #
    protected variable inputs    ""
    protected variable outputs   ""
    protected variable options ""
    protected variable extrafilenames ""
    protected variable directinputs  ""



    # Create Default Output File list based on specific rules
    protected method CreateDefaultOutputFileList  { filelist { numoutputs -1 } }

    #output file name default is input filename + default suffix
    protected variable defaultsuffix ""


    #Generate internal tcl array (InputsArray,OutputsArray, and OptionsArray)
    #from tcl lists (inputs outputs,options). Values and objects  won't be
    #set until execution
    protected method   CreateOptionsArray { }

    # Set InputsArray,OutputsArray
    protected method CreateInputArray  { }
    protected method CreateOutputArray { }
    protected method CreateVTKObjects  { }
    protected method CreateInputArrayElement { newlist  { cmdline "" }}
    protected method CreateOutputArrayElement { newlist { cmdline "" }} 

    # set the filenames from a list for those objects not initialized from the command line (-inp, -out) style switches
    public method SetInputArrayFilenames  { inplist }

    #under construction
    protected method   AddHistoryToLog {  }

}


#----------------------------------------------------
# under construction
#----------------------------------------------------
itcl::body bis_basealgorithm::AddHistoryToLog {  } {

    PrintDebug "bis_basealgorithm::AddHistoryToLog"

    set history ""

    #history is a list which contains history from all the input file
    if { $PreserveHistory != 0 } {
	foreach input [ array names InputsArray ] {
	    set object      [$InputsArray($name) GetObject ] 
	    set object_type [$InputsArray($name) GetObjectType ] 
	    switch object_type {
		pxitclimage {
		    set comment [ $object GetImageHeader GetComment ]
		}
		pxitcltransform {
		}
		pxitclsurface {
		}
		pxitcllandmarks {
		}
		pxitclelectrodemultigrid {
		}
		default {
		}
		lappend history $comment
	    }
	}
	lappend Log $history
    }
    PrintDebug "Log =$Log" 
}

#----------------------------------------------------
#Get command line options list
#----------------------------------------------------
itcl::body bis_basealgorithm::GetCmdLineOptionsList {  } {
    #    PrintDebug "bis_basealgorithm::GetCmdLineOptionsList"

    $this CreateInputArray
    $this CreateOutputArray

    set optionslist ""

    for { set i 0 } { $i < [ llength $inputs ] } { incr i } { 
	set name [ lindex [ lindex $inputs $i ] 0 ]
	set cmdoption [ $InputsArray($name) GetCommandSwitch ]
	if { $cmdoption != "" } {
	    lappend optionslist [  $InputsArray($name) GetCmdLineString ]
	}
    }

    for { set i 0 } { $i < [ llength $outputs ] } { incr i } { 
	set name [ lindex [ lindex $outputs $i ] 0 ]
	set cmdoption [ $OutputsArray($name) GetCommandSwitch ]
	if { $cmdoption != "" } {
	    lappend optionslist [  $OutputsArray($name) GetCmdLineString ]
	}
    }

    set nlist [ concat $StandardOptionsList $AdvancedOptionsList ]
    for { set i 0 } { $i < [ llength $nlist ] } { incr i } {
	set name [ lindex $nlist $i ]
	set opt $OptionsArray($name)
 	if { [ string compare -length 3 $name "gui" ] != 0 } {
 	    lappend optionslist [  $OptionsArray($name) GetCmdLineString ]
 	}
     }
    

    PrintDebug "\n\n\[CmdLineOptionsList\]"
    PrintDebug "$optionslist"
    return $optionslist
}


#----------------------------------------------------
#Get list from interenal arrays
#----------------------------------------------------
itcl::body bis_basealgorithm::GetInputsList  {  } {    return  [array names InputsArray]  }
itcl::body bis_basealgorithm::GetOutputsList {  } {    return  [array names OutputsArray] }
itcl::body bis_basealgorithm::GetOptionsList {  } {    return  [array names OptionsArray] }


# -----------------------------------------------------------
#  VTK Like interface to options and outputs
# -----------------------------------------------------------

itcl::body bis_basealgorithm::SetOptionValue { optionname value } {

    $OptionsArray($optionname) SetValue $value
}

itcl::body bis_basealgorithm::GetOptionValue { optionname } {

    return [ $OptionsArray($optionname) GetValue ]
}

itcl::body bis_basealgorithm::GetOptionType { optionname } {

    return [ $OptionsArray($optionname) GetOptionType ]
}


itcl::body bis_basealgorithm::SetInputObject { inputname obj } {

    catch {
	if { [ $obj IsA "vtkObject"  ] == 1 } {
	    puts stderr "You are doing something wrong in SetInputObject $inputname, you are using a vtkObject instead of a pxitcl object"
	    exit
	}
    }
    [ $InputsArray($inputname) GetObject ] Copy $obj
}

itcl::body bis_basealgorithm::GetInputObject { inputname } {
    return [  $InputsArray($inputname) GetObject ]
}
 
itcl::body bis_basealgorithm::GetOutputObject { outputname }  {
    return [ $OutputsArray($outputname) GetObject ]
}

itcl::body bis_basealgorithm::GetInputBisObject { inputname } {
    return   $InputsArray($inputname) 
}
 
itcl::body bis_basealgorithm::GetOutputBisObject { outputname }  {
    return  $OutputsArray($outputname) 
}

itcl::body bis_basealgorithm::GetInputName { id } {

    return [ lindex [ lindex $inputs $id ] 1 ]
}

itcl::body bis_basealgorithm::RenameInput { id newname { newpriority -1 } } {

    set n [ llength $inputs ]
    if { $id >= $n } {
	return 0
    }

    set tmp $inputs
    set inputs ""
    for { set i 0 } { $i < $n } { incr i } {
	if { $id != $i } {
	    lappend inputs [ lindex $tmp $i ]
	} else {
	    set tmplist [ lindex $tmp $i ]


	    lset tmplist 1 "$newname"

	    if { $newpriority != -1 } {
		lset tmplist 4 $newpriority
	    }

	    lappend inputs $tmplist
	}
    }
    set tmp ""

}

itcl::body bis_basealgorithm::RenameOutput { id newname { newpriority -1 } } {

    set n [ llength $outputs ]
    if { $id >= $n } {
	return 0
    }

    set tmp $outputs
    set outputs ""
    for { set i 0 } { $i < $n } { incr i } {
	if { $id != $i } {
	    lappend outputs [ lindex $tmp $i ]
	} else {
	    set tmplist [ lindex $tmp $i ]


	    lset tmplist 1 "$newname"

	    if { $newpriority != -1 } {
		lset tmplist 4 $newpriority
	    }

	    lappend outputs $tmplist
	}
    }
    set tmp ""

}

#----------------------------------------------------
#Generate InputsArray,OutputsArray, and OptionsArray
#----------------------------------------------------
itcl::body bis_basealgorithm::CreateOptionsArray { } {

    PrintDebug  "bis_basealgorithm::CreateOptionsArray"

    PrintDebug "Creating Options Array "
    array set OptionsArray {}
    set nlist ""
    for { set i 0 } { $i < [llength $options  ] } { incr i } {
	set lst [ lindex $options $i]
	set name [ lindex $lst  0]

	if { $name == "out" || $name == "inp" || $name == "i" || $name =="o" } {
	    puts stderr "Bad Option Name \"out\" -- this is reserved"
	    exit
	}

	if { [ regexp "^out\[0-9\]+" $name  ] > 0 } {
	    puts stderr "Bad Option Name $name -- this matches a  reserved name"
	    exit
	}

	if { [ regexp "^inp\[0-9\]+" $name  ] > 0 } {
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

 #   puts stderr "nlist = $nlist"

    set nlist [ lsort -integer  -index 1 $nlist ]
 #   puts stderr "sorted nlist = $nlist"
    for { set i 0 } { $i < [ llength $nlist ] } { incr i } {
	
	set ind [ lindex [ lindex $nlist $i ] 0 ]
	set lst [ lindex $options $ind ]
	set p   [ lindex $lst 6 ]
#	puts stderr "Reading lst item $i, p=$p lst=$lst"


	set name [ lindex $lst 0 ]
#	puts stderr "Item $i, ind=$i, lst=$lst, p=$p"
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

#	puts stderr "\t\t adding Option $name  $p --> [ lindex $lst 6 ] \t\t: $lst"
    }
}

#----------------------------------------------------
# Get usage information including input,output
# and option description.Stdout by default
# or html format if specified
#----------------------------------------------------
itcl::body bis_basealgorithm::GetDetailDescription { mode  } {

    set description_all "$description $description2 \n"
    #
    if {[string compare $mode "html" ] == 0 } { 
	set cr  "<br>"
	set cr2  "<BR>"
	set bos "<b>"
	set boe "</b>"
	set bh4 " <BR><B><span style=\"color: red;\">"
	set eh4 "</span></B>"
	set eeh4 ""
    } elseif {[string compare $mode "tex" ] == 0 } { 
	set cr "\n"
	set cr2 "\n\n"
	set bos "\\item{"
	set boe "}"
	set bh4 "\n\\paragraph*{"
	set eh4 "}\n\\begin{compactitem}"
	set eeh4 "\n\\end{compactitem}"
    } else {
	set cr "\n"
	set cr2 "\n\n"
	set bos ""
	set boe ""
	set bh4 ""
	set eh4 ""
	set eeh4 ""

    }

    #
    #Inputs
    #
    set desc_in ""
    if { [llength $inputs ]  > 0 } {
	set desc_in  "$cr2$bh4\[Inputs\]$eh4"

	if { [ llength $inputs ] > 0 } {

	    for { set i 0 } { $i < [ llength $inputs ] } { incr i } {
		set name [lindex [ lindex $inputs $i ]  0 ]
		if { $name != $directinputs } {
		    set cmdoption [ $InputsArray($name) GetCommandSwitch ]
		    set comment1  "${bos}$name${boe} (command line option --$cmdoption) : [lindex [ lindex $inputs $i ] 1 ]"
		} else {
		    set comment1  "${bos}$name${boe} list --  specify the list of names for this at the end of the command line"
		}
		append desc_in "$cr $comment1 "
	    }
	}
	append desc_in $eeh4
    }

    

    #
    #Outputs
    #
    set desc_out ""
    if { [llength $outputs ]  > 0 } {

	set desc_out "$cr2$bh4\[Outputs\]$eh4"
	
	if { [ llength $outputs ] > 0 } {
	    for { set i 0 } { $i < [ llength $outputs ] } { incr i } {
		set name [lindex [ lindex $outputs $i ]  0 ]
		set cmdoption [ $OutputsArray($name) GetCommandSwitch ]
		set comment1  "${bos}$name${boe} (command line option --$cmdoption) : [lindex [ lindex $outputs $i ] 1 ]"
		append desc_out " $cr $comment1 "
	    }
	}

	append desc_out $eeh4
    }

    #
    #Options
    #

    for { set pass 0 } { $pass <=2 } { incr pass } {
	set cnt($pass) 0
#	puts stdout "\n\n"
	if { $pass == 0 } {
	    set desc_opt($pass) "$cr2$bh4\[Options\]$eh4"
	} elseif { $pass ==1 } {
	    set desc_opt($pass) "$cr2$bh4\[Common Options\]$eh4"
	} else {
	    set desc_opt($pass) "$cr2$bh4\[Software Testing Options\]$eh4"
	}

	foreach elem $options {
	    set nm [ lindex $elem 0 ]
	    if { $nm != "testlog" && [ string compare -length 3 $nm "gui" ] != 0 } {
	
		set pri [ lindex $elem 6 ]
		set includethis 0
		
		if { $pass == 0 && $pri > -10000 } {
		    set includethis 1
		} elseif { $pass == 1 && ( $pri <= -10000 && $pri > -11000 ) } {
		    set includethis 1
		} elseif { $pass == 2 && $pri < -11000 } {
		    set includethis 1
		}

#		puts stdout "nm=$nm pri=$pri pass=$pass includethis=$includethis"

		if { $includethis > 0 } {
		    #description for each option. name, description, default value
		    set comment1 "${bos}[lindex $elem 0]${boe}  : [lindex $elem 1]. Default value is \"[lindex $elem 4]\"."
		    set etype [ lindex [ lindex $elem 3 ] 0 ]
		    if { $etype != "string" && $etype != "filename" && $etype != "comment"  } {
			if { $etype == "listofvalues" } {
			    set comment2 "Allowed values = \["
			    set l [ llength [ lindex $elem 5 ] ]
			    for { set i 0 } { $i < $l } { incr i } {
				set comment2 "${comment2} [ lindex [ lindex $elem 5 ] $i ]"
				if { $i != [ expr $l -1 ] } {
				    set comment2 "${comment2},"
				}
			    }
			    set comment2 "${comment2} \]"
			} elseif { $etype == "boolean" } {
			    set comment2  "Allowed values are either 0 (Off) or 1 (On)"
			} else {
			    set comment2  "Allowed range is from [lindex [lindex $elem 5] 0 ] to [lindex [lindex $elem 5] 1 ] "
			}
		    } else {
			set comment2 ""
		    }
		    
		    set tmp "$desc_opt($pass) $cr $comment1 $comment2"
		    set desc_opt($pass) $tmp
		    incr cnt($pass)
		}
	    }
	}
	if { $cnt($pass) < 1 } {
	    set desc_opt($pass) "$cr"
	} else {
	    append desc_opt($pass) $eeh4
	}
    }
    


    return "$description_all $desc_in $desc_out $desc_opt(0) $desc_opt(1) $desc_opt(2)"
}

#----------------------------------------------------
#print usage
#----------------------------------------------------
itcl::body bis_basealgorithm::PrintUsage {  } {

    puts stdout "---------------------- BioImage Suite Command Line Tools (www.bioimagesuite.org)--------------"
    puts stdout "\n\[NAME\]"
    puts stdout "${scriptname}.tcl [GetDescription]"
    puts stdout "\n\[SYNOPSIS\]"
    puts stdout "[GetSynopsis text]"
    puts stdout "\n\[DESCRIPTION\]"
    puts stdout "[GetDetailDescription text ]"
    puts stdout "\n\[BACKWARD COMPATIBILITY\]"
    puts stdout "[GetBackwardCompatibility]"
    puts stdout "\n\[NOTE\]"
    puts stdout "BioImage Suite accepts both single dash and double dash specs, e.g. you may use --dogui instead of -dogui or vice-versa."
}

#----------------------------------------------------
# Create Default Output File list based on specific rules
# rule 1 : "the first input file name" + "suffix".
#          If the input filename is "image" and the 
#          default suffix is "_smooth","_bin", output
#          will be "image_smooth" and "image_bin"
# rule2 :"the first input file name" and index.
#          If the input filename is "image" ,
#          output will be "image_001",image"002",,,
#----------------------------------------------------
itcl::body bis_basealgorithm::CreateDefaultOutputFileList  { filelist { numoutputs -1 } } {
#    DebugOn
#    puts stdout "bis_basealgorithm::CreateDefaulteDefaultOutputFileList"
#    puts stdout "filelist = $filelist"
#    puts stdout "defaultsuffix = $defaultsuffix"


    # First setting up the suffix rules
    # ---------------------------------

    if { $numoutputs == -1 } {
	set numoutputs  [ llength $outputs ]
    }
    set numsuffixes [ llength $defaultsuffix ]

    if { $numsuffixes == 0 } {
	set firstsuffix "_out"
    } else {
	set firstsuffix [ lindex $defaultsuffix 0 ]
    }

    if { $numsuffixes < $numoutputs } {

	set str "%d"
        if { $numoutputs >=100 && $numoutputs < 1000 } {
	    set str "%03d"
	} elseif { $numoutputs >=10 }  {
	    set str "%02d"
	}

	for { set i  $numsuffixes  } { $i < $numoutputs } { incr i } {
	    set num [ format $str [ expr $i +1 ] ]
	    lappend defaultsuffix "${firstsuffix}_$num"
	    #	    puts stdout "Adding to $defaultsuffix"
	}
    }

#    puts stderr "Suffixes = $defaultsuffix"

    # Second setup the main file stem and suffix and directory name
    # -------------------------------------------------------------
    set inname [ lindex $filelist 0 ]

    set l [ ::bis_common::SplitFileNameGZ $inname ]
    set inname [ lindex $l 0 ]
    set extension [ lindex $l 1 ]
    set tmp ""; catch { set tmp [ $this GetOptionValue outputstem ] }
    if { [ string length $tmp ] > 0 } { set inname $tmp }

    set ext [ file extension $inname ]    
    if { [ string length $ext ] > 0 } {
	set extension $ext 
    }
    set inname    [ file rootname  $inname ]
    set l [ ::bis_common::SplitFileNameGZ $inname ]
    set inname [ lindex $l 0 ]
    set extension [ lindex $l 1 ]


    # Ovveride dirname from outputpath
    set dirname [ file normalize [ file dirname $inname ] ]
    set rootname [ file tail $inname ]

    
    set output_filelist ""
    
    foreach suffix $defaultsuffix  {
	if { $suffix == "_nosuffix_" } {
	    set suffix ""
	}
	PrintDebug "************************* root=$rootname, suffix=$suffix, $extension"
	lappend output_filelist [ file join $dirname "$rootname$suffix$extension" ]
    }
    
    
    PrintDebug "output_filelist = $output_filelist"
    #    puts stderr "Outputs = $output_filelist"
    #puts $output_filelist
    return $output_filelist
}

#----------------------------------------------------
# CreateInputArrayElement 
#----------------------------------------------------
itcl::body bis_basealgorithm::CreateInputArrayElement { newlist { cmdline "" } } {

    PrintDebug "bis_basealgorithm::CreateInputArrayElement"
    set name  [ lindex $newlist  0 ]
    set elem  [ [ bis_object \#auto ] GetThisPointer ]
    set InputsArray($name) $elem
    PrintDebug "$scriptname Created Input Array $name == $elem"

    $InputsArray($name) SetValueAsList $newlist
    $InputsArray($name) SetUpdateCallback "$this UpdateInputsFromContainer"
    $InputsArray($name) SetCommandSwitch $cmdline
    #    $InputsArray($name) CreateVTKObject     
    if { $debug ==1 } { $InputsArray($name) PrintSelf }
}




#----------------------------------------------------
# CreateOutputArrayElement 
#----------------------------------------------------
itcl::body bis_basealgorithm::CreateOutputArrayElement { newlist { cmdline "" }} {
    set name  [ lindex $newlist  0 ]
    set elem  [ [ bis_object \#auto ] GetThisPointer ]
    set OutputsArray($name) $elem
    PrintDebug "$scriptname: Created Output Array $name == $elem"
    $OutputsArray($name) SetValueAsList $newlist
    $OutputsArray($name) SetCommandSwitch $cmdline
    if { $debug ==1 } { $OutputsArray($name) PrintSelf }
    
    
}


#-----------------------------------------------------------------------
#  Utility Function to sort priorities
#-----------------------------------------------------------------------
itcl::body bis_basealgorithm::CleanAndSortPriorities { elemlist fld } {

    #puts stderr "\n\n ------------------------------------------------------------------\n"
    set indlist ""
    for { set idx 0 } { $idx < [llength $elemlist] } { incr idx } {
	set elem [ lindex $elemlist $idx ]
	while { [ llength $elem ] <= $fld } {
	    lappend elem 0
	}
	set tmp [ list $idx [ lindex $elem $fld ] ]
	lappend indlist $tmp
	#puts stderr "Adding unsorted element $tmp "
    }
    
    set newlist [ lsort -integer  -index 1 $indlist ]


    set sortedelemlist ""
    set offset 0
    for { set idx 0 } { $idx < [llength $elemlist] } { incr idx } {
	set ind [ lindex $newlist $idx ] 


	if {  [ lindex $ind 1 ] < 100 } { 
	    set offset 0
	} else {
	    set offset 100
	}
	set index [ lindex $ind 0 ]
	set elem [ lindex $elemlist $index ]
	while { [ llength $elem ] <= $fld } {
	    lappend elem ""
	}
	set elem2 [ lreplace $elem $fld $fld [ expr $offset + $idx ] ]
	lappend sortedelemlist $elem2
	#puts stderr "Adding $elem2"
    }


    return $sortedelemlist
}
#-----------------------------------------------------------------------
# Set InputArray
#-----------------------------------------------------------------------
itcl::body bis_basealgorithm::CreateInputArray {  } {


    # Clean Priorities and Sort

    set inputs [ CleanAndSortPriorities $inputs 4 ]

    set maxpr [ expr [ llength $inputs ] +1 ]

    # set fixed and optional input files
    for { set idx 0 } { $idx < [llength $inputs] } { incr idx } {
	set ilist         [ lindex $inputs $idx ]
	set line "inp"
	if { $idx > 0 } {
	    set j [ expr $idx +1 ]
	    set line "inp$j"
	}

	CreateInputArrayElement $ilist $line
    }

}

itcl::body bis_basealgorithm::SetInputArrayFilenames  { inplist } {

    if { $directinputs != "" } {
	if { [ llength $inplist ] > 0 } {
	    puts stdout "Setting $directinputs  filenames= ( $inplist ) \n"
	    $InputsArray($directinputs) SetFileName [ lindex $inplist 0 ] 1
	    if { [ llength $inplist ] > 1 } {
		set extrafilenames  [ lrange $inplist 1 [ expr [ llength $inplist ] -1 ] ]
		$InputsArray($directinputs) AddFileNames $extrafilenames
	    }
	}
	return
    }

    set index 0
    for { set idx 0 } { $idx < [llength $inputs] } { incr idx } {
	set elem [ lindex $inputs $idx ]
	set name  [ lindex $elem  0 ]
	if { [ $InputsArray($name) IsFileNameTheDefault ] == 1 }  {
	    if { $index < [ llength $inplist ] } {
		$InputsArray($name) SetFileName [ lindex $inplist $index ] 1
		#puts stderr "\t\t\t Setting $name [ lindex $inplist $index ]"
		incr index
	    } else {
		#puts stderr "\t\t\t index $index  is too big compared to [ llength $inplist ]"
	    }
	} else {
	    #puts stderr "\t\t\t Image $name not default ignoring"
	}
    }
    
    return 1
}

#-----------------------------------------------------------------------
# Set OutputArray
#-----------------------------------------------------------------------
itcl::body bis_basealgorithm::CreateOutputArray {  } {

    set outputs [ CleanAndSortPriorities $outputs 4 ]
    set maxpr [ expr [ llength $inputs ] +1 ]

    PrintDebug "bis_basealgorithm::CreateOutputArray"
    # set fixed and optional input files
    for { set i 0 } { $i < [llength $outputs] } { incr i } {
	set ilist         [ lindex $outputs $i ]
	set line "out"
	if { $i > 0 } {
	    set j [ expr $i +1 ]
	    set line "out$j"
	}
	#puts stderr "Creating outputelement $ilist, $line"
	CreateOutputArrayElement $ilist $line
    }

}

itcl::body bis_basealgorithm::CreateVTKObjects  { } {
    

#    puts stderr "Creating VTK Objects \n\n\n\n\n"

    if { [ llength [ array names OutputsArray ] ] <1  } {
	$this CreateOutputArray
    }
    foreach name [ array names OutputsArray ] {
	set ok [ $OutputsArray($name) CreateVTKObject $guimode ]
	if { $ok ==0 } {
	    return 0
	}
    }

    if { [ llength [ array names InputsArray ] ] < 1 } {
	$this CreateInputArray
    }

    foreach name [ array names InputsArray ] {
	set ok [ $InputsArray($name) CreateVTKObject $guimode ]
	if { $ok ==0 } {
	    return 0
	}
    }
    return 1
}
#----------------------------------------------------
#Set parameter values and file names to internal arrays
#----------------------------------------------------
itcl::body bis_basealgorithm::SetArguments { parameterlist filelist } {

    set ret 1

    PrintDebug "bis_basealgorithm::SetArguments"
    PrintDebug "parameterlist = $parameterlist"
    PrintDebug "filelist = $filelist"

    set ret [ $this SetParameters $parameterlist ]
    if { $ret == 0 } {
	return 0 
    }

    $this SetInputArrayFilenames  $filelist  
    AddHistoryToLog 

    return 1
}

#----------------------------------------------------
# Prints InputsArray
#----------------------------------------------------

itcl::body bis_basealgorithm::PrintObjectList {   } {

    set names [array names InputsArray]
    foreach name $names {
	$InputsArray($name) PrintSelf
  }
}

#----------------------------------------------------
#Set parameter values (given as list) to internal bis_option arrays
#----------------------------------------------------
itcl::body bis_basealgorithm::SetParameters { params_list } {
    
    PrintDebug "bis_basealgorithm::SetParameters"
    set ret 1


    set ret [ $this HandleParameterSetArgument $params_list ]
    if { $ret == 0 } {
	return 0
    }

    array set params $params_list
    # Parameters should be an array of bis_options not a list
    foreach { key value } [array get params] {
	# input checking will be done automatically in SetValue

	set found 0
	if { [string first "-" $key ] !=-1 } {
	    set key [ string range $key 1 end ]
	}
	
	foreach name [ array names OutputsArray ] {
	    if { $found == 0 } {
		set cmdoption [ $OutputsArray($name) GetCommandSwitch ]
		if { $cmdoption == $key } {
		    $OutputsArray($name) SetFileName $value 1
		    set found 1
		}
	    }
	}

	if { $found == 0 } {
	    foreach name [ array names InputsArray ] {
		if { $found == 0 } {
		    set cmdoption [ $InputsArray($name) GetCommandSwitch ]
		    if { $cmdoption == $key } { 
			if { $name != $directinputs } {
			    $InputsArray($name) SetFileName $value 1
			}
			set found 1
		    }
		}
	    }
	}

	if { $found == 0 } {
	    set tmp [$OptionsArray($key) SetValueIfCurrentIsTheDefault $value ]
	}
    }
    return $ret
}

#----------------------------------------------------
# Clean InputsArray
#----------------------------------------------------
itcl::body bis_basealgorithm::CleanInputsArray {  } {
    foreach name [array names InputsArray] {
	set obj [ $InputsArray($name) GetObject ]

	# this deltes a vtkObject
	catch { $obj Delete }

	# this deltes a Itcl object
	catch { itcl::delete object $obj }
    }
}

#----------------------------------------------------
# Clean OutputsArray
#----------------------------------------------------
itcl::body bis_basealgorithm::CleanOutputsArray {  } {
    foreach name [array names OutputsArray] {
	set obj [ $OutputsArray($name) GetObject ]

	# this deltes a vtkObject
	catch { $obj Delete }

	# this deltes a Itcl object
	catch { itcl::delete object $obj }

    }
}
itcl::body bis_basealgorithm::CleanAll {  } {
    PrintDebug "bis_basealgorithm::CleanAll"
    $this CleanInputsArray
    $this CleanOutputsArray
}



#----------------------------------------------------
# Load bis_object to InputsArray from files
#----------------------------------------------------
itcl::body bis_basealgorithm::LoadObjects {  } {

    PrintDebug "bis_basealgorithm::LoadObjects"
    if { $guimode  == "managed" } {
	return 0
    }

    foreach input [ array names InputsArray ] {

	#load pxitcl object
	set filename [ $InputsArray($input) GetFileName ]
	set type     [ $InputsArray($input) GetObjectType]
	set priority [ $InputsArray($input) GetPriority ]


	set ok 0
	if { $filename != "" && $filename != "\"\"" } {
	    set ok       [ $InputsArray($input) LoadObject $filename ]
	} elseif { $priority >= 100 } {
	    set ok -1
	}
    	
	if { $ok == 0 } {
	    set errormessage "Failed to load \"$filename\" for input object [  $InputsArray($input) GetDescription ]. Specify this using the --[ $InputsArray($input) GetCommandSwitch ] flag"
	    return 0
	}
    }

    if { $directinputs != "" } {
	set objectlist [ $InputsArray($directinputs) GetObjectList ]
	for { set i 0 } { $i < [ llength $objectlist ] } { incr i } {
	    set obj [ lindex $objectlist $i ]
	    set fn  [ $obj cget -filename ]
	    set ok [ $obj Load $fn ]
	    if { $ok == 0 } {
		set errormessage "Failed to load \"$fn\" for input object [  $InputsArray($input) GetDescription ] (extra [ expr $i+1 ]). "
		return 0
	    }
	}
	$InputsArray($directinputs) UpdateInternalGUI
    }
    return 1
}

#----------------------------------------------------
# Set bis_object of InputsArray from a bis_object list Why do we nee this ?
#----------------------------------------------------
itcl::body bis_basealgorithm::SetInputObjects { objectlist  } {
    PrintDebug "bis_basealgorithm::LoadObjects"
    if { [ llength $objectlist ] != [ llength $inputs ] } {
	puts stderr "Bad Input $objectlist, wrong number of elements "
	return 
    }

    foreach input [ array names InputsArray ] {
	 $InputsArray($input) Copy [ lindex $objectlist $i ] 
    }
    return 1

}

#------------------------------------------------------------------------------------
# Save filenames for validation. This information is used from bis_test::SaveExpectData
#------------------------------------------------------------------------------------
itcl::body bis_basealgorithm::SaveTestLog {  } {

    PrintDebug "bis_basealgorithm::SaveTestLog"

    #testlog file
    set flag 0
    catch { set flag [ $OptionsArray(testlog)    GetValue ]  }

    if {$flag  == 1} {
	set tmp ${bis_common::bis_testlog}
	puts stdout "$tmp"
	set chan [ open $tmp  w]
	foreach output [ array names OutputsArray ] {
	    set filename [ $OutputsArray($output) GetFileName ]
	    if  { $filename != "" } {
		puts $chan  "$filename"
	    }
	}

	set found [lsearch [array names OptionsArray ] log]
	if { $found  > 0 } {
	    set  additional_log [ $OptionsArray(log)    GetValue ] 
	    if {$additional_log  != ""} {
		if  { $additional_log != "" } {
		    puts $chan  "$additional_log"
		}
	    }
	}
	close $chan 
    }


    return 1
}

#----------------------------------------------------
# Save bis_object of OutputsArray
#----------------------------------------------------
itcl::body bis_basealgorithm::SaveObjects { { forcedir "" }  { updatefilenames 1 } } {
    PrintDebug "bis_basealgorithm::SaveObjects"

    if { $updatefilenames > 0  } {
	$this UpdateOutputFilenames
    }

    set tmp  [ array names OutputsArray ]
    set namelist [lsort $tmp]
    set resultmessage ""

    foreach output $namelist {
	#save each pxitcl object
	set filename [ $OutputsArray($output) GetFileName ]
	set object   [ $OutputsArray($output) GetObject  ]
	set type     [ $OutputsArray($output) GetObjectType]

	set ok 0
	if { $filename != "" } {
	    if { [ string length $forcedir ] > 1 } {
		set filename [ file join $forcedir [ file tail $filename ]]
	    }

	    set tok [ file writable [ file dirname $filename ] ]
	    if { [ file exists $filename ] } {
		set tok [ file writable $filename ]
	    }

	    if { $tok !=0 } {
		catch { set ok [ $object Save $filename ] }
	    }

	    if { $ok == 0 } {
		set errormessage "Failed to save object [ $OutputsArray($output) GetDescription ] in \"$filename\""
		return 0
	    } else {
		set resultmessage "${resultmessage}\t Saved object [ $OutputsArray($output) GetDescription ] in $filename\n"
	    }
	}
    }

    #Save log for test if specified
    $this SaveTestLog

    return 1
}


#--------------------------------------------------------------
# GetSynopsis
#--------------------------------------------------------------
itcl::body bis_basealgorithm::GetSynopsis { mode  } {

    set html 0
    set latex 0
    set linebreak ""

    if { [string compare $mode "html" ] == 0 } { 
	set html 1
	set linebreak "<br>\t"    
    } elseif { [string compare $mode "tex" ] == 0 } { 
	set latex 1
	set linebreak  "|\\linebreak\n\\verb|     "    
    }

    if { $html } {
	set Synopsis "<PRE><B>"    
	append Synopsis ${scriptname}.tcl
	append Synopsis "</B>" 
    } elseif { $latex } {
	set Synopsis "\\verb| ${scriptname}.tcl "
    } else {
	set Synopsis "${scriptname}.tcl "
    }

    set numouts [ llength $outputs ]

    set cnt 1

    set badlist [ list  outputpath outputstem outputsuffix ]

    for { set i 0 } { $i < [ llength $inputs ] } { incr i } { 
	set name [ lindex [ lindex $inputs $i ] 0 ]
	if { $name != $directinputs } {
	    set cmdoption [ $InputsArray($name) GetCommandSwitch ]
	    if { $cmdoption != "" } {
		if { [expr ${cnt} % 5 ] == 0 } {
		    append Synopsis  $linebreak
		}
		
		set tmp [  $InputsArray($name) GetCommandSwitch ]
		append Synopsis  "\[--$tmp \] "
		incr cnt
	    }
	}
    }
    
    for { set i 0 } { $i < [ llength $outputs ] } { incr i } { 
	set name [ lindex [ lindex $outputs $i ] 0 ]
	set cmdoption [ $OutputsArray($name) GetCommandSwitch ]
	if { $cmdoption != "" } {
	    if { [expr ${cnt} % 5 ] == 0 } {
		append Synopsis  $linebreak
	    }

	    set tmp [  $OutputsArray($name) GetCommandSwitch ]
	    append Synopsis    "\[--$tmp \] "
	    incr cnt
	}
    }

    foreach elem $options {

	set elemname [ lindex $elem 0 ]
	set found [ lsearch -exact $badlist $elemname ]


	if { $numouts > 0 || $found  ==-1  } {

	    if { [expr ${cnt} % 5 ] == 0 } {
		append Synopsis  $linebreak
	    }

	    set option    "\[--[ lindex $elem 0] \] "
	    
	    if { [string compare "[lindex $elem 0]" "testlog" ] !=0 } {
		append Synopsis   $option 
	    }
	    incr cnt
	}
    }


    if { $directinputs != "" } { 
	append Synopsis "$linebreak ${directinputs}1 ${directinputs}2  ... ${directinputs}N "
    }

#    foreach elem $inputs {
#	append Synopsis "\[ [lindex $elem 0] \]"
#    }
    

    if { $html > 0 } {
	append Synopsis "</PRE>"    
    } elseif { $latex > 0 } {
	append Synopsis "|\n"    
    }

    return $Synopsis 
}

# ------------------------------------------------------------------
itcl::body bis_basealgorithm::ClearInputs { } {
    foreach name [ array names InputsArray ] {
	set bisobj $InputsArray($name)
	set obj [ $bisobj GetObject ]
	$obj Clear
	$bisobj UpdateInternalGUI
    }

}
# -----------------------------------------------------------------
itcl::body bis_basealgorithm::ClearOutputs { } {

    foreach name [ array names OutputsArray ] {
	set bisobj $OutputsArray($name)
	set obj [ $bisobj GetObject ]
	$obj Clear
	$bisobj UpdateInternalGUI
    }
}
# -----------------------------------------------------------------
