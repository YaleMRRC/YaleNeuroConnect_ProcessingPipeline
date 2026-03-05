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


set argc [llength $argv]
if { $argc <2 } {
    set scriptname [ file tail $argv0 ]
    puts stderr "\n$scriptname is part of BioImage Suite (www.bioimagesuite.org)\n"
    puts stderr "$scriptname is a script that generates a makefile to compute batch mode registrations to a single reference"

    puts stderr "Syntax: $scriptname setup_file output_directory \[ go,setup\]  \[ > makefile  \]"
    puts stderr " if the word go is missing the program simply tests for the presence of all the images"
    puts stderr " if the word setup is present the program simply generates a multi-subject setup file (.msb) and stops"
    puts stderr " if the word go is present then the program outputs a makefile to stdout. Use the make (gmake) command to execute the batch job!"
    
    puts stderr "\n type $scriptname sample > sample.setup "
    puts stderr " \t to generate a sample setup file\n"
    puts stderr "\n"

    if { [ lindex $argv 0 ] != "sample" } {
	exit
    }

    puts stdout "\#Example Setup File\n\# all lines beginning with \# are ignored \n\#"
    puts stdout "\#\tif imglist is missing this defaults to standard rpm registration"
    puts stdout "\#\tif surfacelist is missing this defaults to standard intensity registration"

    puts stdout "\#\txformlist   is ignored unless both imglist and surfacelist are present"
    puts stdout "\#\t\t if no initial transformations are specified, these are computed via rpm and then the integrated algorithm is executed!"

    puts stdout "\#\n\# Mode of Operation"
    puts stdout "set intensities_only 0"
    puts stdout "set points_only 0"
    puts stdout "set ignore_initial_transformations 0\n\#\n\#"
    puts stdout "\#\n\#\n\# List all images here\n\#"
    puts stdout "set imglist \{"
    puts stdout "   /data/brains/1001/sag.cihte.hdr"
    puts stdout "   /data/brains/1002/sag.cihte.lw.hdr"
    puts stdout "\}\n\#\n\#\n"

    puts stdout "\#\n\#\n\# List all surface objectmaps (same number as the images here)\n\#"
    puts stdout "set surfacelist \{"
    puts stdout "   /data/brains/1001/1001_objectmap.vtk"
    puts stdout "   /data/brains/1002/1002_objectmap.vtk"
    puts stdout "\}\n\#\n\#\n"

    puts stdout "\#\n\#\n\# List all initial transforms (if they exist -- same number as images else do not include ) here\n\#"
    puts stdout "set xformlist \{"
    puts stdout "   /data/brains/1001/1115_normalized_objectmap_1001_objectmap.grd"
    puts stdout "   /data/brains/1002/1115_normalized_objectmap_1002_objectmap.grd"
    puts stdout "\}\n\#\n\#\n"

    puts stdout "\#\n\# If Binary map to test alignment -- put it here"
    puts stdout "set objectmaplist \{"
    puts stdout "   /data/brains/1001/1115_gray.hdr"
    puts stdout "   /data/brains/1002/1115_gray.hdr"
    puts stdout "\}\n\#\n\#\n"
    

    puts stdout "\#\n\#\n\# Put reference brain here\n\#"
    puts stdout "set refimg  /home/papad/normalized/1115_normalized.hdr"
    puts stdout "set refsurface  /home/papad/normalized/1115_normalized_objectmap.vtk\n\#"
    puts stdout "\# If using objectmaps put reference objectmap here"
    puts stdout "\nset refobjectmap /data/brains/1002/1115__normalized_gray.hdr\n\#"
    puts stdout "\# Leave objectmap sigma as negative number unless it is a single roi"
    puts stdout "\nset objectmapsigma -2.0"
    puts stdout "\#\n\# beginsubject determines which would the first subject to be processed"
    puts stdout "\# -1 = default automatically determines whether this is a new job or a restarting of a crashed job"
    puts stdout "set beginsubject -1"
    puts stdout "\# Initial Transform Mode = one of ( affine,similarity,rigid )"
    puts stdout "set linearmode  \"affine\"\n\n"
    puts stdout "\#\n\#\n\# Tweak parameters for intensity based part"
    puts stdout "\# Regarding filetype: filetype = 1 includes directory name in output filename 0 does not"
    puts stdout "set resolution 1.5\nset spacing   15.0\nset iterations 15\nset filenametype 0\nset smoothness 0.001"
    puts stdout "set linearonly 0\nset autonormalize 1\n"
    puts stdout "\#\n\#\n\# Tweak parameters for point-based part, userpm=0 then use icp instead"
    puts stdout "set userpm 1"
    puts stdout "set numpoints 1000\nset initial_spacing  30\nset final_spacing 15\n"
    puts stdout "set initial_smoothness 5.0\nset final_smoothness 1.0\n"
    puts stdout "set initial_linear_temperature 15\nset final_linear_temperature  3"
    puts stdout "set initial_spline_temperature 3\nset final_spline_temperature 1.5"
    puts stdout "\#\n\#\n\# Tweak parameters for integrated part"
    puts stdout "\nset pointsweight 0.1"
    puts stdout "set fixedcorrespondences    0"
    puts stdout "set numsteps 1"
    puts stdout "set surface_threshold_low      -100"
    puts stdout "set surface_threshold_high     +100"
    puts stdout "set identifier \"\""

    puts stdout "\#\n\#\n\# Parameters for jacobian computation for the final registration\n"
    puts stdout "set dojacobians 0"
    puts stdout "set jacobians_stem \"jacobians\""
    puts stdout "set jacobians_resolution 2.0"
    puts stdout "set jacobians_blursize   2.0"
    puts stdout "set jacobians_raw 0"
    puts stdout "set jacobians_threshold 0.0"


    exit
}
# ------------------------------------------------------------------------------------------------------

set imglist ""
set refimg  ""
set objectmaplist ""
set refobjectmap ""
set beginsubject -1
set resolution 1.5
set spacing   15.0
set iterations 15
set filenametype 0
set smoothness 0.001
set linearonly 0
set autonormalize 1
set linearmode "affine"

set surfacelist ""
set xformlist ""
set refsurface ""
set userpm 1

set numpoints 3000
set initial_spacing 30
set final_spacing 15
set initial_smoothness 5.0
set final_smoothness 1.0

set initial_linear_temperature 15
set final_linear_temperature   3

set initial_spline_temperature 3
set final_spline_temperature   1

set anneal_rate 0.93


set identifier ""
set pointsweight 0.1

set fixedcorrespondences    0
set weightedcorrespondences 1
set surface_threshold_low       -100
set surface_threshold_high      +100

set intensities_only          0
set points_only             0
set ignore_initial_transformations 0
set ignore_objectmaps 0
set objectmapsigma   -2.0
set numsteps 1
set userpm 1

set jacobians_stem "jacobians"
set jacobians_resolution 2.0
set jacobians_blursize   2.0
set jacobians_raw 0
set jacobians_threshold 0.0
set dojacobians 0

    
lappend auto_path [ file dirname [ info script ]]; package require pxappscommon
package require  pxitclimage            1.0
package require  pxitcltransform        1.0
package require  pxitclsubjectentry     1.0


set usesurfaces 1
set useimgages  1
set useinitialxforms 1
set usesurfacesforchecking 0
set useimagesforchecking   0
set useobjectmaps 1

set inputfile [ file tail [ file root [ lindex $argv 0 ]]]
source [ lindex $argv 0 ]


if { $imglist != "" } {
    set endsubject [ llength $imglist ]
} else {
    set endsubject [ llength $surfacelist ]
}


# --------------------------------------------------------------------------------------------------------

proc TestImages { argv } {

    global resolution
    global spacing
    global beginsubject
    global iterations
    global endsubject
    global refimg
    global refsurface
    global imglist
    global outputdirectory
    global identifier
    global filenametype
    global surfacelist
    global xformlist
    global useinitialxforms
    global pointsweight
    global usesurfaces
    global useimages
    global numpoints
    global initial_smoothness
    global final_smoothness
    global initial_spacing
    global final_spacing
    global initial_spline_temperature
    global final_spline_temperature
    global usesurfacesforchecking 
    global useimagesforchecking   
    global useobjectmaps 
    global objectmaplist 
    global refobjectmap
    

    puts stderr "Testing for existence of images,surfaces and initial transforms (useimages=$useimages,usesurfaces=$usesurfaces,usexforms=$useinitialxforms)"
    set outputdirectory [ lindex $argv 1 ]

    if { $identifier == "" } {
	if { $usesurfaces == 1 && $useimages == 1 } {
	    set identifier  "integr"
	} elseif { $usesurfaces == 1 } {
	    set identifier "np${numpoints}_sm${initial_smoothness}_${final_smoothness}_cp${initial_spacing}_${final_spacing}"
#_te_${initial_spline_temperature}_${final_spline_temperature}"
	} else {
	    set identifier  "nmi_${spacing}_${resolution}"
	}
    }

    for { set i $beginsubject } { $i <= $endsubject } { incr i } {
	
	if { $i != $endsubject } {
	    
	    if { $useimages == 1 || $useimagesforchecking == 1 } {
		set a [ lindex $imglist $i ]
	    } else {
		set a ""
	    }


	    if { $usesurfaces == 1 || $usesurfacesforchecking == 1 } {
		set b [ lindex $surfacelist $i ]
	    } else {
		set b ""
	    }
	    
	    if { $useinitialxforms == 1 } {
		set c [ lindex $xformlist $i ]
	    } else {
		set c ""
	    }
	    set index [ format "%3d" $i ]

	    if { $useobjectmaps == 1 } {
		set d [ lindex $objectmaplist $i ]
	    } else {
		set d ""
	    }
	} else {
	    if { $useimages == 1 || $useimagesforchecking == 1} {
		set a $refimg
	    } else {
		set a ""
	    }
	    
	    if { $usesurfaces == 1 || $usesurfacesforchecking == 1 } {
		set b $refsurface
	    } else {
		set b ""
	    }
	    set c ""
	    set index "REF"

	    set d $refobjectmap
	}

	if { $a != "" } {
	    set ok1 [ pxappscommon::EnsureImageExists $a ]
	} else {
	    set ok1 "(none)"
	}

	if { $b != "" } {
	    set ok3 [ file exists $b  ] ;   set sz3 -1 ; catch { set sz3 [ file size $b ] }
	} else {
	    set ok3 1 
	    set sz3 none
	}

	if { $c != "" } {
	    set ok4 [ file exists $c ] ;   set sz4 -1 ; catch { set sz4 [ file size $c ] }
	} else {
	    set ok4 1
	    set sz4 "(none)"
	}


	if { $d != "" } {
	    set okd1 [ pxappscommon::EnsureImageExists $d ]
	} else {
	    set okd1 "(none)"
	}

	
	if { $ok1 !=0    && $ok3 > 0 && $ok4 > 0 && $okd1 !=0   } {
	    set f "--> [ pxtclutil::GenerateFilename $refimg $a $identifier [ pxtclutil::GetNonLinearSuffix ] $outputdirectory $filenametype ]"
	    if { $index == "REF" } {
		set f ""
	    }
	    puts stderr "\n\t$index  $ok1\n\t surface=$b ($sz3)\n\t initxform = $c ($sz4) $f  objectmap=$okd1 ok"
	} else {
	    puts stderr "\n*********** Missing Image $ok1 surface  $b ($sz3)  or initxform $c ($sz4) or ojectmap $okd1"
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
proc GenerateSetupFile {  }  {

    global outputdirectory
    global identifier
    global beginsubject
    global endsubject
    global refimg
    global imglist
    global filenametype
    global inputfile
    global useimages
    global usesurfaces
    global surfacelist
    global refsurface

    set fname [ file join $outputdirectory "${inputfile}_${identifier}.msb" ]

    set fileid [open $fname w]
    puts $fileid "#Multisubject Description File v2"
    
    set task [ pxitcltask \#auto ]
    $task configure -task_name "First Task"
    $task configure -task_suffix "_task1"

    puts $fileid "Tasks\n1"
    puts $fileid "- - - - - - - - - - - - - - - - - - - -"
    $task SaveToSetupFile $fileid
    
    set subject [ pxitclsubject \#auto ]

    puts $fileid "Subjects\n[llength $imglist]"
    puts $fileid "- - - - - - - - - - - - - - - - - - - -"
    for { set i $beginsubject } { $i < $endsubject } { incr i } {
	[ $subject cget -anatomical_image ] configure -filename [ GenAbsolute [ lindex $imglist $i ] ]
	if { $useimages == 1 } {
	    set f "[ pxtclutil::GenerateFilename $refimg [ lindex $imglist $i ] $identifier [ pxtclutil::GetNonLinearSuffix ] $outputdirectory $filenametype ]"
	} else {
	    set f [ pxtclutil::GenerateFilename $refsurface [ lindex $surfacelist $i ] $identifier [ pxtclutil::GetNonLinearRPMSuffix ] $outputdirectory $filenametype ] 
	}
	[ $subject cget -reference_transform ] configure -filename [ GenAbsolute $f ]
	$subject SaveToSetupFile $fileid
    }

    puts $fileid "Reference/Output Images"
    puts $fileid "--------------------------------------"

    puts $fileid " Reference Image : [ GenAbsolute $refimg]"

    set output_list [ list "Average Anatomical" "Std Anatomical" "Average Functional" "Std Functional" "TofT Functional" "Thresholded Composite" "Average Jacobian" "Std Jacobian" ]
    set name_list [ list "average_anatomical" "std_anatomical" "average_functional" "std_functional" "toft_functional" "thresholded_composite" "average_jacobian" "std_jacobian" ]

    for { set i 0 } { $i < [ llength $output_list ] } { incr i } {
	if { $i >=2 && $i <= 5 } {
	    puts $fileid "[ lindex $output_list $i ] : [ GenAbsolute [ file root $fname]_[ lindex $name_list $i ]_task1.hdr]"
	} else {
	    puts $fileid "[ lindex $output_list $i ] : [ GenAbsolute [ file root $fname]_[ lindex $name_list $i ].hdr]"
	}
    }
    
    close $fileid
}
# --------------------------------------------------------------------------------------------------------
#    Jacobian Stuff
# --------------------------------------------------------------------------------------------------------

proc   GenerateJacobianTarget { finalxformlist ptsweight numweights } {

    global jacobians_stem 
    global jacobians_resolution 
    global jacobians_blursize   
    global jacobians_raw 0
    global jacobians_threshold 
    global argv

    global identifier
    global refimg
    global inputfile
    global outputdirectory

    set suffix ${jacobians_stem}
    if { $numweights > 1 } {
	set suffix "${jacobians_stem}_${ptsweight}"
    }

    set fname [ file join $outputdirectory "${inputfile}_${identifier}_${suffix}.txt" ]
    
    set fileid [open $fname w]

    puts $fileid "\#Jacobian Definition File\n"
    puts $fileid "set transformlist \{"
    for { set i 0 } { $i < [ llength $finalxformlist ] } { incr i } {
	puts $fileid "\t [ lindex $finalxformlist $i ]"
    }
    puts $fileid "\}\n\#"
    puts $fileid "\#\n\#\n\# Put reference brain here\n\#"
    puts $fileid "set refimg  $refimg"
    puts $fileid "\n\#\n\#\n\# Put output stem and resolution here\n\#"
    puts $fileid "set outputstem $suffix"
    puts $fileid "set resolution ${jacobians_resolution}"
    puts $fileid "set blursize   ${jacobians_blursize}"
    puts $fileid "\n\# Set this to 1 to get the full tensor as opposed to just the determinant"
    puts $fileid "set rawjacobians ${jacobians_raw}"
    puts $fileid "\n\# Set this to 0.05 to eliminate computation of jacobian in low intensity regions"
    puts $fileid "set threshold  ${jacobians_threshold}"

    close $fileid

    set jobname "jacobians_${suffix}"

    set dname [ file join $outputdirectory $jobname ]

    file mkdir $dname

    puts stdout "$jobname : $finalxformlist"
    puts stdout "\t pxmultijacobian.tcl $fname $dname go\n"

    return $jobname
}


# --------------------------------------------------------------------------------------------------------
# Main Program
# --------------------------------------------------------------------------------------------------------

set totalnumber 0

if { $beginsubject == -1 } {
    set auto_flag 1
    set beginsubject 0
} else {
    set auto_flag 0
}


if { [ llength $imglist ] > 0 } {
    if { [ llength $surfacelist ] > 0 } {
	if { [ llength $surfacelist ] != [ llength $imglist ] } {
	    puts stderr "Error different numbers of images ([llength $imglist]) and surfaces ([ llength $surfacelist ]) specified"
	    exit 0
	}
	set usesurfaces 1
    } else {
	set usesurfaces 0
    }
    
    if { [ llength $xformlist ] > 0 && $ignore_initial_transformations == 0 } {
	if { [ llength $xformlist ] != [ llength $imglist ] } {
	    puts stderr "Error different numbers of images ([llength $imglist]) and surfaces ([ llength $xformlist ]) specified"
	    exit 0
	}
	set useinitialxforms 1
    } else {
	set useinitialxforms 0
    }
    set useimages 1
    set totalnumber [ llength $imglist ]
} else {
    set usesurfaces 1
    set useinitialxforms 0
    set useimages 0
    set totalnumber [ llength $surfacelist ]
}
    

if { $intensities_only == 1 && $useimages == 1 } {
    
    if  { $usesurfaces == 1 } {
	set usesurfaces 0
	set usesurfacesforchecking 1
    }
} elseif { $points_only == 1 && $usesurfaces == 1 } {
    
    if { $useimages == 1 } {
	set useimages 0
	set useimagesforchecking 1
    }
}

if { [ llength $objectmaplist ] == $totalnumber } {
    set usetobjectmaps 1
} else  {
    set useobjectmaps 0
}


TestImages $argv
puts stderr "Using identifier $identifier, output directory is $outputdirectory"

puts stdout "\# Global Settings\n\#"
puts stdout "\# Number of Inputs"
puts stdout "\# Images = [ llength $imglist ], Surfaces = [ llength $surfacelist ], Transforms = [ llength $xformlist ]"
puts stdout "\# Input Specs: intensities_only = $intensities_only,   points_only=$points_only ignore_initial_xforms=$ignore_initial_transformations\n\#"
puts stdout "\# Actual Use:"
puts stdout "\#\t Use Images = $useimages (for checing only $useimagesforchecking)"
puts stdout "\#\t Use Surfaces = $usesurfaces (for checing only $usesurfacesforchecking)"
puts stdout "\#\t Use Initial Transformations = $useinitialxforms, and Objectmaps=$useobjectmaps\n\#\n\#-------------------------------------------------------"

if { [ llength $argv ] < 3 } {
    exit
}

if { [ lindex $argv 2 ] != "go" } {
    if { [ lindex $argv 2 ] == "setup" } {
	GenerateSetupFile
    }
    exit
}



# Stop the program and fix up the button
MakeDirectory
GenerateSetupFile


puts stdout "\#\n\# Makefile for batch job\n\#\n\#\n"
puts stdout "all : computeall\n"
set all ""
set linearall ""
set realcleanall ""
set results ""
set rpmresults ""
set overlaps ""

set jacobianlist ""
set lmode 1
if { $linearmode == "similarity" } {
    set lmode 2 
} elseif { $linearmode == "rigid" } {
    set lmode 3
}

if { $usesurfaces == 0 || $useimages == 0 } {
    set pointsweight "\#"
}

if { $userpm != 0 } {
    set rpmname "rpm"
    set userpm  1
} else {
    set rpmname "icp"
    set userpm 0
}

for { set j  0 } { $j < [ llength $pointsweight ] } { incr j } {

    set finalxformlist ""

    set weight [ lindex $pointsweight $j ]

    if { $usesurfaces == 0 || $useimages == 0 } {
	set identifierw $identifier
    } else {
	set wg [ format "%5.3f" $weight ]
	if { $usesurfaces == 0 } {
	    set identifierw ${identifier}_${wg}
	} else {
	    set identifierw ${identifier}_${rpmname}_${wg}_${numsteps}
	}
    }


    for { set i $beginsubject } { $i < $endsubject } { incr i } {
	
	puts stdout "\#-------------------------------------------------------\n\# Individual Subject [ expr $i + 1 ] w=$weight\n\#-------------------------------------------------------\n"
	
	
	if { $usesurfaces ==1 } {
	    set f1 [ pxtclutil::GenerateFilename $refsurface [ lindex $surfacelist $i ]  $rpmname [ pxtclutil::GetLinearSuffix ] $outputdirectory $filenametype ]
	    set f2 [ pxtclutil::GenerateFilename $refsurface [ lindex $surfacelist $i ]  $rpmname [ pxtclutil::GetNonLinearRPMSuffix ] $outputdirectory $filenametype ]
	}
	
	# -------------------------------------------------------
	#
	# Case A :  use images or not
	#
	# -------------------------------------------------------
	
	
	if { $useimages == 1 } {
	    set f3 [ pxtclutil::GenerateFilename $refimg [ lindex $imglist $i ]  "${identifierw}" [ pxtclutil::GetNonLinearSuffix ] $outputdirectory $filenametype ]
	} else {
	    set f2 [ pxtclutil::GenerateFilename $refsurface [ lindex $surfacelist $i ] "${identifierw}" [ pxtclutil::GetNonLinearRPMSuffix ] $outputdirectory $filenametype ]
	}

	# -------------------------------------------------------
	#
	# Case B : use surfaces  =0
	#
	# -------------------------------------------------------
	
	if { $usesurfaces == 0 } {
	    
	    # -------------------------------------------------------
	    #
	    # Do not use Surfaces use only images
	    #
	    # -------------------------------------------------------

	    if { $linearonly == 1 } {
		set f3 [ pxtclutil::GenerateFilename $refimg [ lindex $imglist $i ]  "${identifierw}" [ pxtclutil::GetLinearSuffix ] $outputdirectory $filenametype ]
		set command "pxmat_register.tcl $refimg [ lindex $imglist $i ] $f3 $lmode $resolution $spacing $iterations 1.0 $smoothness $lmode $autonormalize"	    
		set command "$command > $f3.intlog 2>&1"
		puts stdout "$f3 :\n\t$command"
		set all "$all $f3"
	    } else {
		set command "pxmat_register.tcl $refimg [ lindex $imglist $i ] $f3 0 $resolution $spacing $iterations 1.0 $smoothness $lmode $autonormalize"
		if { $useinitialxforms == 1 } {
		    set command "$command [ lindex $xformlist $i ]"
		}
		set command "$command > $f3.intlog 2>&1"
		puts stdout "$f3 :\n\t$command"
		set all "$all $f3"
		
		if { $usesurfacesforchecking == 0 } {
		    set command2 "pxmat_computesimilarity.tcl $refimg [ lindex $imglist $i ] $f3 > $f3.results 2>&1"
		} else {
		    set command2 "pxmat_computesimilarity.tcl $refimg [ lindex $imglist $i ] $f3 $refsurface [ lindex $surfacelist $i ] $final_spline_temperature [ expr $numpoints /3 ]  0  > $f3.results 2>&1"
		}

		if { $useobjectmaps > 0 } {
		    set command3 "pxmat_computeoverlap.tcl $refobjectmap [ lindex $objectmaplist $i ] $objectmapsigma $f3 > $f3.overlap 2>&1"
		    set overlaps "$overlaps $f3.overlap"
		    puts stdout "\n$f3.overlap : $f3\n\t$command3\n"
		} else {
		    puts stderr "objectmaps = $useobjectmaps"
		}
		
		puts stdout "$f3.results : $f3\n\t$command2"
		set realcleanall "$realcleanall $f3"
		set results      "$results $f3.results"

		lappend finalxformlist $f3

	    }
	} else {
	    
	    # -------------------------------------------------------
	    #
	    # Use Surfaces  =1
	    #
	    # -------------------------------------------------------
	    
	    if { $useinitialxforms == 0 } {
		
		# -------------------------------------------------------
		#
		# Compute Straight RPM for initialization
		#
		# -------------------------------------------------------
		
		
		set command "pxmat_pointregister.tcl $refsurface [ lindex $surfacelist $i ] $f1 $lmode $userpm [ expr $numpoints / 3 ] $initial_linear_temperature $final_linear_temperature 5.0 1.0 20 10  > $f1.intlog 2>&1"
		puts stdout "$f1 :\n\t $command\n"
		set linearall "$linearall $f1"
		
		set command "pxmat_pointregister.tcl $refsurface [ lindex $surfacelist $i ] $f2 0 $userpm [ expr $numpoints  ] $initial_spline_temperature $final_spline_temperature $initial_smoothness $final_smoothness $initial_spacing $final_spacing $f1 > $f2.intlog 2>&1"
		puts stdout "$f2 : $f1\n\t $command\n"
		
		
		set realcleanall "$realcleanall $f1 $f2 ${f1}.intlog ${f2}.intlog"
	    } else {
		
		# -------------------------------------------------------
		#
		# Else Use Initial Transform 
		#
		# -------------------------------------------------------
		
		set f2 [ lindex $xformlist $i ]
	    }
	    
	    if { $useimages == 1 } {
		
		# -------------------------------------------------------
		#
		#  Use Images + Surfaces 
		#
		# -------------------------------------------------------
		
		set command "pxmat_integratedregistration.tcl $refimg [ lindex $imglist $i ] $refsurface [ lindex $surfacelist $i ] $f3 $f2 $spacing $resolution $iterations $smoothness $weight $numpoints  $final_spline_temperature $fixedcorrespondences $userpm $numsteps $surface_threshold_low $surface_threshold_high > $f3.intlog 2>&1 "
		puts stdout "$f3 : $f2\n\t $command\n"
		
		set all "$all $f3"
		set realcleanall "$realcleanall $f3"
		lappend finalxformlist $f3

		set command2 "pxmat_computesimilarity.tcl $refimg [ lindex $imglist $i ] $f3 $refsurface [ lindex $surfacelist $i ] $final_spline_temperature [ expr $numpoints /3 ]  0  > $f3.results 2>&1"
		puts stdout "$f3.results : $f3\n\t$command2\n"
		set results "$results $f3.results"
		
		if { $j == 0 } {
		    set outcommand2 [ file join $outputdirectory [ file tail $f2 ]]
		    set command2b "pxmat_computesimilarity.tcl $refimg [ lindex $imglist $i ] $f2 $refsurface [ lindex $surfacelist $i ] $final_spline_temperature [ expr $numpoints /3 ]  0  > $outcommand2.results 2>&1"
		    puts stdout "$outcommand2.results : $f2\n\t$command2b\n"
		    set rpmresults "$rpmresults $outcommand2.results"
		}
		
		if { $useobjectmaps > 0 } {
		    set command3 "pxmat_computeoverlap.tcl $refobjectmap [ lindex $objectmaplist $i ] $objectmapsigma $f3 > $f3.overlap 2>&1"
		    set overlaps "$overlaps $f3.overlap"
		    puts stdout "$f3.overlap : $f3\n\t$command3\n"
		}
	    } else {
		
		# -------------------------------------------------------
		#
		#  Do not Use Images + Surfaces  i.e. surface only
		#
		# -------------------------------------------------------
		
		set all "$all $f2"
		if { $useimagesforchecking == 0 } {
		    set command2 "pxmat_computedistance.tcl $refsurface [ lindex $surfacelist $i ] $f2 0 $final_spline_temperature [ expr $numpoints /3 ]  > $f2.results 2>&1"
		} else {
		    set command2 "pxmat_computesimilarity.tcl $refimg [ lindex $imglist $i ] $f2 $refsurface [ lindex $surfacelist $i ] $final_spline_temperature [ expr $numpoints /3 ]  0  > $f2.results 2>&1"
		}
		puts stdout "$f2.results : $f2\n\t$command2\n"
		set results "$results $f2.results"
		
		if { $useobjectmaps > 0 } {
		    set command3 "pxmat_computeoverlap.tcl $refobjectmap [ lindex $objectmaplist $i ] $objectmapsigma $f2 > $f2.overlap 2>&1"
		    set overlaps "$overlaps $f2.overlap"
		    puts stdout "$f2.overlap : $f2\n\t$command3\n"
		}
		lappend finalxformlist $f2
	    }
	}
	puts stdout " "
    }
    
    if { $dojacobians > 0 } {
	puts stdout "\#-------------------------------------------------------\n\# Jacobian Target for w=$weight\n\#-------------------------------------------------------\n"
	lappend jacobianlist [ GenerateJacobianTarget $finalxformlist [ lindex $pointsweight $j ] [ llength $pointsweight ] ]
    }
}
puts stdout "\# -------------------------------------------------------"
puts stdout "\#                     Global Targets                     "
puts stdout "\# -------------------------------------------------------"

puts stdout "computeall : $all evaluate\n\n"
if { $dojacobians > 0 } {
    puts stdout "jacobians : $jacobianlist\n\n"
}
puts stdout "evaluate   : $results\n"
puts stdout "linear     : $linearall\n"
if { $useobjectmaps > 0 } {
    puts stdout "overlap   : $overlaps\n"
    puts stdout "evaluaterpm : $rpmresults\n"
}

puts stdout "clean :\n\t rm $all\n\n"
puts stdout "realclean : cleanresults \n\t rm $realcleanall\n\t rm $rpmresults\n"
puts stdout "cleanresults :\n\t rm $results \n"



exit

