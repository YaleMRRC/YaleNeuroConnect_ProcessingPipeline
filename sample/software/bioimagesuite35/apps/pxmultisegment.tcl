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





# --------------------------------------------------------------------------------------------------------
# 	$Id: pxmultiregister_int.tcl,v 1.1 2004/01/15 15:06:06 xenios Exp xenios $	


set imglist ""
set numclasses 3
set imgtype 1
set identifier "segm"
set usefsl 0
set mrfiterations 20
set smoothness 1.0
set maxsigmaratio 0.05
set mrfiterations 20

set argc [llength $argv]
if { $argc <2 } {
    set scriptname [ file tail $argv0 ]
    puts stderr "\n$scriptname is part of BioImage Suite (www.bioimagesuite.org)\n"
    puts stderr "$scriptname is a script that generates a makefile to compute batch mode tissue segmentation using\n\t\teither FSL/fast or native BioImage Suite segmentation tools (pxmat_segment.tcl)"

    puts stderr "Syntax: $scriptname setup_file output_directory \[ go\]  \[ > makefile  \]"
    puts stderr "\t\t if the word go is missing the program simply tests for the presence of all the images"
    puts stderr "\t\t if the word go is present then the program outputs a makefile to stdout. Use the make (gmake) command to execute the batch job!"
    
    puts stderr "\n type $scriptname sample > sample.setup "
    puts stderr " \t to generate a sample setup file\n"

    if { [ lindex $argv 0 ] != "sample" } {
	exit
    }

    puts stdout "\#Example Setup File\n\# all lines beginning with \# are ignored \n\#"
    puts stdout "\#\n\# Mode of Operation"
    puts stdout "\#\n\#\n\# List all images here\n\#"
    puts stdout "set imglist \{"
    puts stdout "   /data/brains/1001/sag.cihte.hdr"
    puts stdout "   /data/brains/1002/sag.cihte.lw.hdr"
    puts stdout "\}\n"
    puts stdout "\#\n\#\n\# Mode"
    puts stdout "\# Set this to 0 to use native BioImage Suite tools"
    puts stdout "set usefsl 1"
    puts stdout "\nset numclasses 3\n\n"
    puts stdout "set identifier $identifier"
    puts stdout "\#\n\#\n\# FSL parameters"
    puts stdout "set imgtype 1"
    puts stdout "\#\n\#\n\# BioImage Suite parameters"
    puts stdout "set smoothness 1.0"
    puts stdout "set maxsigmaratio 0.05"
    puts stdout "set mrfiterations 20"
    exit
}

lappend auto_path [ file dirname [ info script ]]; package require pxappscommon
package require  pxitclimage            1.0
package require  pxitcltransform        1.0
package require  pxitclsubjectentry     1.0
    
source [ lindex $argv 0 ]

# --------------------------------------------------------------------------------------------------------

proc TestImages { argv } {

    global imglist
    global identifier

    puts stderr "Testing for existence of images"

    set outputdirectory [ lindex $argv 1 ]
    set endsubject [ llength $imglist ]

    for { set i 0 } { $i < $endsubject } { incr i } {
	
	set fname   [ file root [ lindex $imglist $i ] ]
	set outname ${fname}_${identifier}
	
	set a "${fname}.hdr"
	set a1 "${fname}.img"
	set ok1 [ file exists $a ] ;   set sz1 -1 ; catch { set sz1 [ file size $a ] }
	set ok2 [ file exists $a1 ] ;   set sz2 -1 ; catch { set sz2 [ file size $a1 ] }
	
	set index [ expr $i + 1 ]
	if { $ok1 > 0 && $ok2 > 0  }  {
	    puts stderr "\n\t$index  $a,[file tail $a1 ] ($sz1,$sz2)\n\t output -> $outname"
	} else {
	    puts stderr "\n*********** Missing Image $a,$a1 ($sz1,$sz2)"
	    exit
	}
    }
}

# --------------------------------------------------------------------------------------------------------

proc MakeDirectory { } {
    global outputdirectory

    if { [ file exists $outputdirectory ] == 0 } {
	file mkdir $outputdirectory
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

    return $out
}

# --------------------------------------------------------------------------------------------------------
# Main Program
# --------------------------------------------------------------------------------------------------------

set outputdirectory [ lindex $argv 1 ]

TestImages $argv
puts stderr "Using identifier $identifier, output directory is $outputdirectory"

puts stdout "\# Global Settings\n\#"
puts stdout "\# Use FSL = $usefsl"
puts stdout "\# Number of Inputs"
puts stdout "\# Images = [ llength $imglist ]"
puts stdout "\# classes = $numclasses , imgtype=$imgtype"
if { $usefsl } {
    puts stdout "\# identifier=$identifier"
} else {
    puts stdout "\# mrfiterations=$mrfiterations, smoothness=$smoothness, maxsigmaratio=$maxsigmaratio"
}

if { [ llength $argv ] < 3 } {
    exit
}

if { [ lindex $argv 2 ] != "go" } {
    exit
}




MakeDirectory

puts stdout "\#\n\# Makefile for batch job\n\#\n\#\n"
puts stdout "all : computeall\n"
set all ""
set results ""

for { set i 0 } { $i < [ llength $imglist ] } { incr i } {

    set fname [ lindex $imglist $i ]
    set base  [ file root [ file tail $fname ]]
    set outname [ file join $outputdirectory "${base}_${identifier}" ]

    if { $usefsl == 1 } {
	set command "fast -c $numclasses -t$imgtype -v 5 -op -or -od $outname $fname"
	set command "$command > ${outname}.fsllog 2>&1"
	puts stdout "${outname}_restore.hdr :\n\t$command"
	
	set command2 "pxmat_fastpostprocess $fname $outname $numclasses"
	set command2 "$command2 > ${outname}_2.fsllog 2>&1"
	puts stdout "${outname}_classification.hdr :\n\t$command2"

	set all "$all ${outname}_restore.hdr"
	set results "$results ${outname}_classification.hdr"
	set results "$results ${outname}.fsllog ${outname}_2.fsllog"
    } else {
	
	set command "pxmat_segment.tcl $fname $numclasses $smoothness $maxsigmaratio $mrfiterations $outname  > ${outname}.segmlog 2>&1"
	puts stdout "${outname}.hdr :\n\t$command"
	set all "$all ${outname}.hdr"
	set results "$results ${outname}.segmlog"
    }
}
puts stdout "\# -------------------------------------------------------"
puts stdout "\#                     Global Targets                     "
puts stdout "\# -------------------------------------------------------"

puts stdout "computeall : $all\n\n"
puts stdout "clean :\n\t rm $all\n\n"
puts stdout "cleanresults :\n\t rm $results\n"



exit

