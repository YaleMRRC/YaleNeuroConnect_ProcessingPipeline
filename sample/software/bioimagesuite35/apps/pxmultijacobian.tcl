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




set transformlist ""
set refimg  ""
set resolution -1.0
set blursize 0.0
set outputstem "jac"
set rawjacobians 0
set threshold 0.01
set computeaverage 0

set argc [llength $argv]
if { $argc <2 } {
    set scriptname [ file tail $argv0 ]
    puts stderr "\n$scriptname is part of BioImage Suite (www.bioimagesuite.org)\n"
    puts stderr "$scriptname is a script that computes either the determinant of the jacobian or the full tensor for a set of transformations"
    puts stderr "Syntax: $scriptname setup_file output_directory \[ go\]"
    puts stderr " if the word go is missing the program simply tests for the presence of all the images/transformations"
    puts stderr "\n type $scriptname sample > sample.setup "
    puts stderr " \t to generate a sample setup file\n"

    if { [ lindex $argv 0 ] != "sample" } {
	exit
    }

    puts stdout "\#Example Setup File\n\# all lines beginning with \# are ignored \n\#"
    puts stdout "\#\n\#\n\# List all subjects here\n\#"
    puts stdout "set transformlist \{"
    puts stdout "   /usr/home/schultz/brain_reg/brains/1001/sag.cihte.grd"
    puts stdout "   /usr/home/schultz/brain_reg/brains/1002/sag.cihte.lw.grd"
    puts stdout "\}\n\#"
    puts stdout "\#\n\#\n\# Put reference brain here\n\#"
    puts stdout "set refimg  /home/papad/normalized/1115_normalized.hdr\n\#"
    puts stdout "\#\n\#\n\# Put output stem and resolution here\n\#"
    puts stdout "set outputstem jac"
    puts stdout "set resolution -1.0\n"
    puts stdout "set blursize 0\n"
    puts stdout "\# Set this to 1 to get the full tensor as opposed to just the determinant"
    puts stdout "set rawjacobians 0"
    puts stdout "\# Set this to 0.05 to eliminate computation of jacobian in low intensity regions"
    puts stdout "set threshold   0.0"
    puts stdout "\# Set this to 1 to compute the mean and standard deviation of the output"
    puts stdout "set computeaverage 0"
    exit
}

lappend auto_path [ file dirname [ info script ]]; package require pxappscommon

    
source [ lindex $argv 0 ]
set outputdirectory [ lindex $argv 1 ]
set inputfile [ file tail [ file root [ lindex $argv 0 ]]]

# --------------------------------------------------------------------------------------------------------

proc TestImages {  } {

    global refimg
    global transformlist
    global singlereference

    puts stderr "Testing for existence of images"

    
    for { set i 0 } { $i < [ llength $transformlist ] } { incr i } {
	
	set a [ lindex $transformlist $i ]
	set index [ format "%3d" [ expr $i +1 ] ]
	set ok1 [ file exists $a ] ;   set sz1 -1 ; catch { set sz1 [ file size $a ] }
	
	if { $ok1 > 0 } {
	    puts stderr "\t$index  $a ($sz1)  ok"
	} else {
	    puts stderr "\n*********** Missing Transform $a ($sz1)"
	    exit
	}

	if { $singlereference == 0 } {

	    set refimgname [ lindex $refimg $i ]
	    set b "[ file root $refimgname ].img"
	    set ok1 [ file exists $a ] ;   set sz1 -1 ; catch { set sz1 [ file size $a ] }
	    set ok2 [ file exists $b ] ;   set sz2 -1 ; catch { set sz2 [ file size $b ] }
	    
	    if { $ok1 > 0 && $ok2 > 0 } {
		puts stderr "\tRef image $index  $a,[file tail $b ] ($sz1,$sz2)  ok"
	    } else {
		puts stderr "\n*********** Missing Image $a,$b ($sz1,$sz2)"
		exit
	    }
	}


    }

    if { $singlereference == 1 } {
	set refimgname [ lindex $refimg 0 ]
	set a $refimgname
	set b "[ file root $refimgname ].img"
	set ok1 [ file exists $a ] ;   set sz1 -1 ; catch { set sz1 [ file size $a ] }
	set ok2 [ file exists $b ] ;   set sz2 -1 ; catch { set sz2 [ file size $b ] }
	
	if { $ok1 > 0 && $ok2 > 0 } {
	    puts stderr "\tSingle Ref image  $a,[file tail $b ] ($sz1,$sz2)  ok"
	} else {
	    puts stderr "\n*********** Missing Image $a,$b ($sz1,$sz2)"
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

set singlereference 1

if { [ llength $transformlist ] == [ llength $refimg ] } {
    set singlereference 0
}


TestImages 


if { [ llength $argv ] < 3 } {
    exit
}

MakeDirectory

puts stdout "\# Makefile Output\n"
puts stdout "all : computeall\n"

set nlist ""
set blist ""
set rlist ""

for { set i 0 } { $i < [ llength $transformlist ] } { incr i } {

    if { $singlereference == 0 } {
	set ref_image [ lindex $refimg $i ]
    } else {
	set ref_image $refimg
    }

    set trfname [ lindex $transformlist $i ]
    # $rawjacobians 
    # $threshold
    # $sigma
    
    set fname  [ file join $outputdirectory "[ file tail [ file root $trfname ]]_${outputstem}_${blursize}" ]
    if { $rawjacobians == 0 } {
	set a "${fname}_combined"
	set b "${fname}_nonlinear"
	lappend rlist $a.hdr
	lappend rlist $a.img.gz
	lappend rlist $b.hdr 
	lappend rlist $b.img.gz
	lappend blist ${b}.hdr
    } else {
	set a "${fname}_raw"
	lappend rlist $a.hdr
	lappend rlist $a.img.gz

    }
    puts stdout "${a}.hdr : $trfname"
    lappend nlist ${a}.hdr

    puts stdout "\tpxsinglejacobian.tcl $ref_image $trfname ${fname}.hdr $resolution $blursize $threshold $rawjacobians\n"
}

set nlist2 ""

if { $computeaverage == 1 } {

    set maxv 2
    if { $rawjacobians == 1 } {
	set maxv 1 
    }
    for { set i 0 } { $i < $maxv } { incr i } {
	if { $rawjacobians == 1 } {
	    set mstem [ file join $outputdirectory ${outputstem}_${blursize}_raw ]
	    puts stdout "${mstem}_mean.hdr : $nlist\n\tpxcomputeaverage.tcl $mstem $nlist\n"
	} elseif { $i == 0 } {
	    set mstem [ file join $outputdirectory ${outputstem}_${blursize}_combined ]
	    puts stdout "${mstem}_mean.hdr : $nlist\n\tpxcomputeaverage.tcl $mstem $nlist\n"
	} else {
	    set mstem [ file join $outputdirectory ${outputstem}_${blursize}_nonlinear ]
	    puts stdout "${mstem}_mean.hdr : $nlist\n\tpxcomputeaverage.tcl $mstem $blist\n"
	}
	
	lappend rlist "${mstem}_mean.hdr"
	lappend rlist "${mstem}_mean.img"
	lappend nlist2 "${mstem}_mean.hdr"
    }
}
puts stdout "\ncomputeall : $nlist $nlist2\n"
puts stdout "\nclean : \n\trm $rlist "

exit

