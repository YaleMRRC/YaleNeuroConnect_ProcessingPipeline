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

package provide bis_util 1.0

#
# AUTHOR Hirohito Okuda, hirohito.okuda@yale.edu
# 

package require  Itcl
package require  Iwidgets 

itcl::class bis_util {

    constructor { } {
    }

    #
    #file operaton
    #

    # createa a sequential filelist (e.g., {file001 file002 file003..})
    public method create_sequential_filelist { file_trunk start end } 

    #make directory
    public method MakeDirectory { directory }

    # generate abolute path name of the file
    public method GenAbsolute { fname } 

    public method TestIfTransformsExist { transformlist }

    public method TestIfImagesExist { imagelist }

    #
    #private
    #
    private method TestIfFilesExist   { filelist mode }

}

#######################################################
# createa a sequential filelist (e.g., {file001 file002 file003..})
#######################################################

itcl::body bis_util::create_sequential_filelist { file_trunk start end } {
    set filelists ""
    for {set i $start } {$i  <= $end } {incr i} {
	if { $i <10 } {
	    set target  [format "%s_00%s" $file_trunk $i]
	} elseif { $i < 100 } {
	    set target  [format "%s_0%s"  $file_trunk $i]
	} else {
	    set target  [format "%s_%s"  $file_trunk $i]
	}
	lappend filelists $target
    }
    return $filelists
}

itcl::body bis_util::MakeDirectory { directory } {
    if { [ file exists $directory ] == 0 } {
	file mkdir $directory
    }
}

itcl::body bis_util::GenAbsolute { fname } {

    if { [ file pathtype $fname ] == "relative" } {
	set out [ file join [ pwd ] $fname ]
	regsub -all  "/./" $out "/" out
    } else {
	set out $fname
    }

    puts stderr "$fname -> $out"
    return $out
}


itcl::body bis_util::TestIfTransformsExist { transformlist } {
    TestIfFilesExist  $transformlist  0 
}

itcl::body bis_util::TestIfImagesExist { imagelist } {
    TestIfFilesExist  $transformlist  1 
}

#
# mode=0 transform,mode=1,image files
#
itcl::body bis_util::TestIfFilesExist { filelist mode } {
    for { set i 0 } { $i < [ llength $filelist ] } { incr i } {
	set a [ lindex $filelist $i ]

	switch $mode {
	    0 {
		set b $a 
	    }
	    1 {
		set b "[ file root $a ].img"
	    }
	}
	set index [ format "%3d" [ expr $i +1 ] ]
	set ok1 [ file exists $a ] ;   set sz1 -1 ; catch { set sz1 [ file size $b ] }
	
	if { $ok1 > 0 } {
	    puts stderr "\t$index  $a ($sz1)  ok"
	} else {
	    puts stderr "\n*********** Missing Transform $a ($sz1)"
	    exit
	}
    }
}


