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



set argc [llength $argv]
if { $argc <2 } {
    set scriptname [ file tail $argv0 ]
    puts stderr "\n$scriptname is part of BioImage Suite (www.bioimagesuite.org)\n"
    puts stderr "$scriptname is a script that generates a makefile to compute batch mode registrations between pairs of images"

    puts stderr "Syntax: $scriptname setup_file output_directory \[ go\]"
    puts stderr " if the word go is missing the program simply tests for the presence of all the images"
    puts stderr "\n type $scriptname sample > sample.setup "
    puts stderr " \t to generate a sample setup file\n"
    puts stderr "\n"

    if { [ lindex $argv 0 ] != "sample" } {
	exit
    }


    puts stdout "\#Example Setup File\n\# all lines beginning with \# are ignored \n\#"
    puts stdout "\#\n\#\n\# List all subjects here\n\#"
    puts stdout "\#\n\#\n\# Put reference brain here\n\#"
    puts stdout "set reflist \{"
    puts stdout "   /data1/brains/1001/sag2.cihte.hdr"
    puts stdout "   /data1/brains/1002/sag2.cihte.lw.hdr"
    puts stdout "\}\n\#"
    puts stdout "set trglist \{"
    puts stdout "   /data1/brains/1001/sag.cihte.hdr"
    puts stdout "   /data1/brains/1002/sag.cihte.lw.hdr"
    puts stdout "\}\n\#"
    puts stdout "\#\n\# beginsubject determines which would the first subject to be processed"
    puts stdout "\# -1 = default automatically determines whether this is a new job or a restarting of a crashed job"
    puts stdout "set beginsubject -1"
    puts stdout "\# Initial Transform Mode = one of ( affine,similarity,rigid), only used if transformation is nonlinear or distortion"
    puts stdout "set linearmode  \"affine\"\n\n"
    puts stdout "\# mode = linear,nonlinear,distortion"
    puts stdout "set mode  \"nonlinear\""
    puts stdout "\#set mode \"rigid\""
    puts stdout "\#set mode \"affine\""
    puts stdout "\#set mode \"distortion\""
    puts stdout "\#\n\#\n\# Tweak parameters"
    puts stdout "\# filetype = 1 includes directory name in output filename 0 does not"
    puts stdout "\# defaults are for rigid/affine/nonlinear"
    puts stdout "set resolution 1.5\nset spacing   15.0\nset iterations 15\nset stepsize 1\nset smoothness auto\n"
    puts stdout "set autonormalize 1\n"
    puts stdout "\#For Distortion Correction use\n\#set resolution 2.0\n\#set spacing   12.0\n\#set iterations 15\n\#set stepsize 4\n\#set smoothness 0.0001\nset phaseencode 1\n"

    puts stdout "\# If in Child Study center set this to 1 otherwise leave alone"
    puts stdout "set filenametype 0\n"
    exit
}



lappend auto_path [ file dirname [ info script ]]; package require pxappscommon

set trglist ""
set reflist  ""
set beginsubject -1
set resolution 1.5
set spacing   15.0
set phaseencode 1
set iterations 15
set filenametype 0
set mode "nonlinear"
set stepsize 1.0
set smoothness auto
set dummy 0
set autonormalize 1
set linearmode "affine"

    
source [ lindex $argv 0 ]
set inputfile [ file tail [ file root [ lindex $argv 0 ]]]
set endsubject [ llength $trglist ]

# --------------------------------------------------------------------------------------------------------

proc TestImages { argv } {

    global resolution
    global spacing
    global beginsubject
    global iterations
    global endsubject
    global reflist
    global trglist
    global outputdirectory
    global identifier
    global filenametype
    global mode
    global suffix

    puts stderr "Testing for existence of images"
    set outputdirectory [ lindex $argv 1 ]
    set identifier "nmi_r${resolution}_s${spacing}_i${iterations}"
    
    set tname(0) "REF"
    set tname(1) "TRG"


    for { set i $beginsubject } { $i < $endsubject } { incr i } {

	set name(0) [ lindex $reflist $i ]
	set name(1) [ lindex $trglist $i ]
	set index [ format "%3d" [ expr 1 + $i ] ]
	
	for { set j 0 } { $j < 2 } { incr j } {
	    set a($j) $name($j)
	    set ok($j) [ pxappscommon::EnsureImageExists $a($j) ]
	}

	if { $ok(1) !=0 && $ok(0) !=0 } {
	    set f "--> [ pxtclutil::GenerateFilename $name(0) $name(1) $identifier $suffix $outputdirectory $filenametype ]"
	    for { set j 0 } { $j <=1 } { incr j } {
		puts stderr "$index $tname($j)  $ok($j) ok"
	    }
	    puts stderr "\t\t Output Transform in $f"
	} else {
	    puts stderr "\n*********** Missing Image $ok(0)\n"
	    puts stderr "\n*********** Missing Image $ok(1)\n"
	    exit
	}
	puts stderr "\n"
    }
}

# --------------------------------------------------------------------------------------------------------

proc MakeDirectory { } {
    global outputdirectory

    if { [ file exists $outputdirectory ] == 0 } {
	file mkdir $outputdirectory
    }

}

proc Log { args } {
	
    global inputpipe
    global donext
    if { $inputpipe == 0 } {
	return
    }
    
    if [eof $inputpipe] {
	catch { close $inputpipe  }
	set donext 1
    } else {
	gets $inputpipe line
	if { $line !="" } {
	    puts stderr "$args $line"
	}
    }
}

# --------------------------------------------------------------------------------------------------------
proc GenAbsolute { fname } {

    if { [ file pathtype $fname ] == "relative" } {
	set out [ file join [ pwd ] $fname ]
	regsub -all  "/./" $out "/" out
    } else {
	set out $fname
    }

    puts stderr "$fname -> $out"
    return $out
}

# --------------------------------------------------------------------------------------------------------
# Main Program
# --------------------------------------------------------------------------------------------------------

if { $beginsubject == -1 } {
    set auto_flag 1
    set beginsubject 0
} else {
    set auto_flag 0
}

if { [ llength $reflist ] != [ llength $trglist ] } {
    puts stderr "Different Number Of Target and Source Images exiting\n"
    exit
}

set suffix [ pxtclutil::GetNonLinearSuffix ]
if { $mode == "rigid" || $mode == "affine" } {
    set suffix [ pxtclutil::GetLinearSuffix ]
}

TestImages $argv

puts stderr "Using identifier $identifier, output directory is $outputdirectory"

if { [ llength $argv ] < 3 } {
    exit
}

if { [ lindex $argv 2 ] != "go" } {
    exit
}


# Stop the program and fix up the button

MakeDirectory

set inputpipe 0
set donext 0

if { $smoothness == "auto" } {
    if { $mode == "nonlinear" } {
	set smoothness 0.0
    } else {
	set smoothness 1.0
    }
}


set lmode 1
if { $linearmode == "similarity" } {
    set lmode 2 
} elseif { $linearmode == "rigid" } {
    set lmode 3
}


puts stdout "\# Makefile for pxpairwiseregister.tcl"
puts stdout "\#\n\# Computing [ expr $endsubject - $beginsubject ] $mode registration(s)\n\#\n\#"
puts stdout "\# Example usage:\n\#\t nohup gmake -k -j2 -f makefile >& log.txt &\n\# to execute\n\#\n\n"
puts stdout "all : computeall\n\n"

set allreg ""

for { set i $beginsubject } { $i < $endsubject } { incr i } {
    
    set name(0) [ lindex $reflist $i ]
    set name(1) [ lindex $trglist $i ]
    set outname [ pxtclutil::GenerateFilename $name(0) $name(1) $identifier $suffix $outputdirectory $filenametype ]
    
    if { $mode == "rigid" } {
	    set command "pxmat_register.tcl $name(0) $name(1) $outname 2 $resolution $spacing $iterations $stepsize 0 $lmode $autonormalize"
    } elseif { $mode == "affine" } {
	set command "pxmat_register.tcl $name(0) $name(1) $outname 1 $resolution $spacing $iterations $stepsize 0 $lmode $autonormalize"
    } elseif { $mode == "distortion" } {
	set command "pxmat_distortioncorrection.tcl $name(0) $name(1) $outname $phaseencode $resolution $spacing $iterations $stepsize $smoothness $lmode $autonormalize"
    } else {
	set command "pxmat_register.tcl $name(0) $name(1) $outname 0 $resolution $spacing $iterations $stepsize $smoothness $lmode $autonormalize"
    }
    set allreg "$allreg $outname "
    puts stdout "$outname : \n\t $command > $outname.intlog 2>&1\n"
}

puts stdout "\n\n\# All Results\n\n computeall : $allreg"

exit

