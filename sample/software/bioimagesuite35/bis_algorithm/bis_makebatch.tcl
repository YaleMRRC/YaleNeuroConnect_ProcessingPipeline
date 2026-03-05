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

package require bis_algorithm 1.0
package provide bis_makebatch 1.0

#
# output makebatchrmation
#

itcl::class bis_makebatch {

    inherit bis_algorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }

    protected method GenerateExample { }
    protected method ReadSetupFile   { fname docheck }
    protected method CreateSetupFile { makefile outputdir setparams mode }

    protected method GenerateOutFile { inplist suffix }
    protected method GenerateFlagString { mode index isinput }
    protected method DoesInputExist { fname }
    protected method CleanString { line { nospace 1 }}

    public method GetGUIName { } { return "Make Batch" }

}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_makebatch::Initialize { } {

    PrintDebug "bis_makebatch::Initialize" 

    set options {
	{ setup "specify the setup file for the batch job" "Setup File"  { filename readfile 40 } "" "textfile" 1 }
	{ makefile "specify the output makefile for the batch job" "Makefile Name"  { filename writefile 40 } "" "textfile" 2 }
	{ odir  "specify the output directory for the batch job" "Output Directory" { filename directory 40 } "" "to store outputs" 3 }
	{ doexample  "generate an example file"   "Do Example" boolean 0 { 0 1 } -10 }
	{ mode  "default is BioImage Suite mode , i.e. specifiy inputs using -inp, -inp 2 etc. If 0 lists inputs and outputs in sequence" "Mode"  boolean 1 { 0 1 } -11 }
	{ docheck  "if 1 then we test if the input files exist" "Check Files"  boolean 1 { 0 1 } -12 }
	{ dummymode  "if 1 then we simply test the setup file but not create any output makefile/directories" "Dummy Mode"  boolean 0 { 0 1 } -13 }

    }

    set defaultsuffix ""
    
    set scriptname bis_makebatch
    set inputs { }
    set outputs { }

    #
    #document
    #
    
    set category "Utility"
    set description "Creates a makefile given a batch input definition file"
    set description2 ""
    set backwardcompatibility "Replaces a bunch of old style batch files"
    set authors "xenophon.papademetris@yale.edu."

    $this AddDefaultOptions 1
}
# -----------------------------------------------------------------------------------------
#  Generating Example for registration ....
# -----------------------------------------------------------------------------------------
itcl::body bis_makebatch::GenerateExample { } {

    puts stdout "# Example Batch File"
    puts stdout "# The following variables can be defined"
    puts stdout "\# inputlist(1) .. inputlist(9) :  lists of inputs"
    puts stdout "\# outputsuffix : list of outputsuffices"
    puts stdout "\# cmdline : the command line beginning with the algorithm"
    puts stdout "\# logsuffix : the suffix of the log file for each command\n\n"
    puts stdout "set inputlist(1) {"
    puts stdout "    ref.hdr"
    puts stdout "}\n"
    puts stdout "set inputlist(2) {"
    puts stdout "    test1.hdr"
    puts stdout "    test2.hdr"
    puts stdout "    test3.nii.gz"
    puts stdout "}\n"
    puts stdout "#Use the *ignore* flag to skip an optional input, i.e. in this case -inp3 will not be used"
    puts stdout "set inputlist(3) {"
    puts stdout "    *ignore*"
    puts stdout "}\n"
    puts stdout "set inputlist(4) {"
    puts stdout "    ref_weight.hdr"
    puts stdout "}\n"
    puts stdout "set inputlist(5) {"
    puts stdout "    w1.hdr"
    puts stdout "    w2.hdr"
    puts stdout "    w3.nii.gz"
    puts stdout "}\n"
    

    puts stdout "set outputsuffix {"
    puts stdout "    map.grd"
    puts stdout "}\n"
    puts stdout "set logsuffix \"results\"\n"
    puts stdout "set cmdline \"bis_nonlinearintensityregister.tcl --spacing 20.0 --useinitial \\"
    puts stdout "  0.0 --useweightimage 2\" "

}
# -----------------------------------------------------------------------------------------
itcl::body bis_makebatch::CleanString { line { nospace 1 } } {
    set line [ string trim $line ]
    regsub -all "\n" $line " " line
    regsub -all "," $line " " line
    regsub -all "\t" $line " " line
    regsub -all " +" $line " " line
    if { $nospace == 1 } {
	regsub -all " " $line "" line
    }
    return $line
}
# -----------------------------------------------------------------------------------------
itcl::body bis_makebatch::DoesInputExist { fname } {

    if { $fname == "*ignore*" } {
	return 1
    }

    # Step 1 -- is this an image -- then if this is a .hdr file

    set f2 $fname
    set ext [ file extension $fname ]
    if { $ext == ".gz" } {
	set f2 [ file rootname $fname ]
	set ext [ file extension $f2  ]
    }
    
    if { [ file exists $fname ] == 0 } {
	set errormessage "$fname does not exist"
	return 0
    }
    if { [ file readable $fname ] == 0 } {
	set errormessage "Cannot read $fname -- check permissions"
	return 0
    }

    if { $ext != ".hdr" } {
	return 1
    }

    # From here on we are in analyze mode 
    set test(1) "[ file rootname $f2].img"
    set test(2) "$test(1).gz"
    for { set i 1 } { $i <= 2 } { incr i } {
	set ok [ $this DoesInputExist $test($i) ]
	if { $ok ==1 } {
	    return 1
	}
    }

    set errormessage "Cannot read either $test(1) or $test(2)"
    return 0

}

# -----------------------------------------------------------------------------------------
itcl::body bis_makebatch::ReadSetupFile { fname docheck } {

    if { [ file readable $fname ] == 0 } {
	set errormessage "Failed to read Setupfile $setupname"
	return 0
    }

    set cmdline ""
    for { set i 1 } { $i <= 9 } { incr i } {
	set inputlist($i) ""
	set outputsuffix ""
    }

    set logsuffix ".results"
    source $fname

    if { $cmdline == "" } {
	set errormessage "No Command line specified in $setupname"
	return 0
    }

    set pname(cmdline) [ $this CleanString $cmdline   0 ]
    set logsuffix      [ $this CleanString $logsuffix 1 ]

    if { [ string first "." $logsuffix ] == 0 } {
	set pname(logsuffix)  $logsuffix
    } else {
	set pname(logsuffix) ".$logsuffix"
    }
    set icount 1


    for { set i 1 } { $i <= 9 } { incr i } {
	set v [ $this CleanString $inputlist($i) 0 ]
	if { $v != "" } {
	    set pname(inputlist,$icount) $v
	    incr icount
	}
    }

    puts stderr "OutputSuffix=$outputsuffix"

    set pname(outputsuffix) [ $this CleanString $outputsuffix 0 ]

    
    set nlist ""
    set goodlists 0

    set icount [ expr $icount -1 ]
    set jcount [ llength $outputsuffix ]

    if { $icount ==0 || $jcount == 0 } {
	set errormessage "No inputs or outputs specified in setupfile"
	return 0
    }

    set pname(numberofinputs) $icount
    set pname(numberofoutputs) $jcount



    if { $docheck > 0 } {
	# Check if inputs exist
	#
	for { set i 1 } { $i <= $icount } { incr i } {
	    set l [ llength $pname(inputlist,$i) ]
	    for { set j 0 } { $j < $l } { incr j } {
		set ok [ $this DoesInputExist [ lindex $pname(inputlist,$i) $j ] ]
		if { $ok == 0 } {
		    return 0
		}
	    }
	}
    }


    for { set i 1 } { $i <= $icount } { incr i } {
	set l [ llength $pname(inputlist,$i) ]
	if { $l > 1 } {
	    lappend nlist $l
	}
    }

#    puts stderr "nlist = $nlist "

    set pname(numberofjobs) 1

    if { [ llength $nlist ] > 0 } {
	set v [ lindex $nlist 0 ]
	# Need to do some testing
	for { set j 1 } { $j < [ llength $nlist ] } { incr j } {
	    if { $v != [ lindex $nlist $j ] } {
		set errormessage "Unequal numbers of inputs specified in inputlists"
		return 0
	    }
	}
	set pname(numberofjobs) $v
    }


    


    if { [ llength $nlist ] > 0 } {
	for { set i 1 } { $i <= $icount } { incr i } {
	    set l [ llength $pname(inputlist,$i) ]
	    if { $l == 1 } {
		set elem [ lindex $pname(inputlist,$i) ]
		for { set j 1 } { $j < $pname(numberofjobs) } { incr j } {
		    lappend pname(inputlist,$i) $elem
		}
	    }
	}
    }






    return [ array get pname ]

}
# -----------------------------------------------------------------------------------------
itcl::body bis_makebatch::GenerateOutFile { inplist suffix } {


    set oname ""
    for { set i 0 } { $i < [ llength $inplist ] } { incr i } {

	if {  [  lindex $inplist $i ] != "*ignore*" } {
	    puts stdout "using [ lindex $inplist $i ]"
	    set fname [ file tail [  lindex $inplist $i ] ]
	    if { [ file extension $fname ] == ".gz" } {
		set fname [ file rootname $fname ]
	    }
	    set fname [ file rootname $fname ]
	    if { $i > 0 } {
		set oname "${oname}_${fname}"
	    } else {
		set oname $fname
	    }
	}
    }


    set ind [ string first "."  $suffix  ] 
    set ind2 [ string first "_"  $suffix  ] 

    if { $ind == "-1" } {
	set oname "${oname}.${suffix}"
    } elseif { $ind ==0 || $ind2 ==0 } {
	set oname "${oname}${suffix}"
    } else {
	set oname "${oname}_${suffix}"
    }
    return $oname
}

# -------------------------------------------------------------------------

itcl::body bis_makebatch::GenerateFlagString { mode index isinput } {
    if { $mode == 0 } {
	return ""
    }

    if { $index ==  0 } {
	if { $isinput ==1 } {
	    return "-inp"
	} else {
	    return "-out"
	}
    }

    set ip [ expr $index + 1 ]

    if { $isinput ==1 } {
	return "-inp$ip"
    }

    return "-out$ip"
}

# -----------------------------------------------------------------------------------------
itcl::body bis_makebatch::CreateSetupFile { makefile outputdir setparams mode } {

    set fout 0
    if { $makefile != "" } {
	catch { set fout [ open $makefile w ] }
	if { $fout == 0 } {
	    set errormessage "Cannot write makefile in $makefile"
	    return 0
	}
    }
    
    array set pname $setparams 

    set outtext ""
    set listofresults ""
    set cleanfiles ""
    
    for { set job 0 } { $job < $pname(numberofjobs) } { incr job } {
	
	set ilist ""
	for { set i 1 } { $i <= $pname(numberofinputs) } { incr i } {
	    lappend ilist [ lindex $pname(inputlist,$i) $job ]
	}
	
	set olist ""
	for { set j 1 } { $j <= $pname(numberofoutputs) } { incr j } {
	    lappend olist [ file join $outputdir [ $this GenerateOutFile $ilist [ lindex $pname(outputsuffix) [ expr $j -1 ] ] ] ]
	}

	set outtext "$outtext\n# Job [ expr $job + 1] / $pname(numberofjobs)"
	set outtext "$outtext\n[ lindex $olist 0 ] : "

	lappend listofresults [ lindex $olist 0 ]

	for { set i 0 } { $i < [ llength $ilist ] } { incr i } {
	    if { [ lindex $ilist $i ] != "*ignore*" } {
		set outtext "$outtext [ lindex $ilist $i ]"
	    }
	}
	set outtext "$outtext\n\t $pname(cmdline)"
	
	for { set i 0 } { $i < [ llength $ilist ] } { incr i } {
	    set flag [ $this GenerateFlagString $mode $i 1 ]
	    if { [ lindex $ilist $i ] != "*ignore*" } {
		set outtext "$outtext $flag [ lindex $ilist $i ]"
	    }
	}

	for { set i 0 } { $i < [ llength $olist ] } { incr i } {
	    set flag [ $this GenerateFlagString $mode $i 0 ]
	    set outtext "$outtext $flag [ lindex $olist $i ]"
	    lappend outputlist($i)  [ lindex $olist $i ]
	}
	
	set resultsfile "[ lindex $olist 0 ]$pname(logsuffix)"
	set outtext "$outtext > $resultsfile 2>&1\n\n"
	
	lappend cleanfiles $resultsfile

    }

    set header "# BioImage Suite Batch File"
    set header "$header\n# cmdline = $pname(cmdline)"
    set header "$header\n# logsuffix = $pname(logsuffix)"
    set header "$header\n# numberofjobs = $pname(numberofjobs)"
    set header "$header\n# numberofinputs = $pname(numberofinputs)"
    set header "$header\n# numberofoutputs = $pname(numberofoutputs)\n\n"
    
    set header2 "all : $listofresults\n\n"
    set header2 "$header2\nclean : \n\t rm $listofresults $cleanfiles\n"
    set header2 "$header2\ncleanwin : \n\t delete $listofresults $cleanfiles\n"
    set outtext "$header\n$header2\n$outtext"


    if { $makefile != "" } {
	puts $fout "$outtext"
	close $fout
	
	set makelog "$makefile$pname(logsuffix)"
	
	set fout [ open $makelog w ]
	puts $fout "\# Output File lists for future use"
	puts $fout "\# These  files might become inputs to a new batch job down the road\n"
	for { set i 0 } { $i < [ llength $olist ] } { incr i } {
	    puts $fout "set inputlist([ expr $i+1 ]) { "
	    for { set j 0 } { $j < [ llength $outputlist($i) ] } { incr j } {
		puts $fout "\t [ lindex $outputlist($i) $j ]"
	    }
	    puts $fout "}\n"
	}
	close $fout
	
	puts stdout "Details = \n$header\n"
	puts stdout "Makefile stored in $makefile (lists of outputs in $makelog)"
	puts stdout "use gmake -f $makefile to execute the batch job\n"
    } else {
	puts stdout "$outtext\n"
    }

}
# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_makebatch::Execute {  } {

    PrintDebug "bis_makebatch::Execute"
    
    set setupname [ $OptionsArray(setup) GetValue ]
    set makefile  [ $OptionsArray(makefile) GetValue ]
    set outputdir [ $OptionsArray(odir) GetValue ]
    set doexample [ $OptionsArray(doexample) GetValue ]
    set mode      [ $OptionsArray(mode) GetValue ]
    set docheck   [ $OptionsArray(docheck) GetValue ]
    set dummymode   [ $OptionsArray(dummymode) GetValue ]


    if { $doexample == 1 } {
	$this GenerateExample
	return 1
    }

    set setparams [ $this ReadSetupFile $setupname $docheck ]
    if { $setparams == 0 } {
	return 0
    }



    if { $dummymode > 0 } {
	set makefile ""
    } else {
	set making 0
	if { [ file exists $outputdir ] == 0 } {
	    set making 1
	    catch { file mkdir $outputdir }
	}
	
	if { [ file exists $outputdir ] == 0 } {
	    set errormessage "Cannot create $outputdir .. "
	    return 0
	}

	puts stdout "Created output directory $outputdir"
    }

    set ok [ $this CreateSetupFile $makefile $outputdir $setparams $mode ]
    return $ok
}


# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_makebatch.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_makebatch [pxvtable::vnewobj]]
    $alg MainFunction 
}

