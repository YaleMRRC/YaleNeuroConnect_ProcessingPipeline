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
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] main]

package require bis_algorithm 1.0
package require bis_viewer 1.0
package require pxitclcamera 1.0
package provide bis_testdatabase 1.0

#
# Operations involving multisubject average for testing ....
#

itcl::class bis_testdatabase {

    inherit bis_algorithm
    
    constructor { } {
	$this Initialize
    }

    public method Initialize { }
    public method Execute { }
    public method CreateTable { dbname tpname imgname }
    public method GetGUIName { } { return "Test Database" }

}
# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_testdatabase::Initialize { } {

    PrintDebug "bis_testdatabase::Initialize" 

    #name,description,type,object,filename(if applicable),priority (optional)

    set outputs { 
	{ out_image "Saved Image" pxitclimage  ""    2000 }
    }

    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ sqlfile "Input database file name" "SQLite Filename:"  { filename readfile }  "" { "BioImage Suite SQLITE Files" { * }} 1 }
	{ tablename  "SQL Table Name" "Table Name"  string "" { "" }  2 }
	{ tableindex  "Index into table" "Index"  integer 0 { 0 1000 } 3 }
	{ createtable  "0 or 1 to create table instead of doing anything else" "Create Table"  boolean  0 { 0  1 }  -10 }       
	{ imgname "Input Image file name" "Image Filename to Add:"  { filename readfile }  "" pxitclimage -11 }
    }

    set defaultsuffix { "" }

    set scriptname bis_testdatabase
    set completionstatus ""
    #
    #document
    #
    set category "Utility"
    set description "This is a test script for the BioImage Suite Viewers, primarily for regression testing"
    set description2 ""
    set backwardcompatibility ""
    set authors "xenophon.papademetris.yale.edu"

    $this AddDefaultOptions
}

itcl::body bis_testdatabase::CreateTable { dbname tpname imgname } {

    set connector [ vtkbisDatabase New ]
    $connector InitializeSQLite $dbname 
    set ok [ $connector Connect ]
    
    if { $ok > 0 } {
	set dbase [ vtkbisFilenameTable New ]
	$dbase SetConnector $connector
	$dbase CreateTable
	$dbase DeleteAll $tpname

	for { set i 0 } { $i < [ llength $imgname ] } { incr i } {
	    puts stdout "AddingItem  $tpname [ file tail [ file rootname [ lindex $imgname $i ] ] ]  [ lindex $imgname $i ]"
	    $dbase AddItem $tpname "IM_[ file tail [ file rootname [ lindex $imgname $i ] ] ]"  [ lindex $imgname $i ]
	}
	$dbase Delete
    } else {
	puts stdout "Failed to connect to $dbname"
	set errormessage "Failed to connect to $dbname"
    }

    $connector Delete
    return $ok
}


itcl::body bis_testdatabase::Execute {  } {


    set dbname [ $OptionsArray(sqlfile) GetValue ]
    set tpname [ $OptionsArray(tablename) GetValue ]
    set index  [ $OptionsArray(tableindex) GetValue ]
    set createtable  [ $OptionsArray(createtable) GetValue ]
    set imgname  [ $OptionsArray(imgname) GetValue ]

    if { $createtable > 0 } {
	return [ $this CreateTable $dbname $tpname $imgname ]
    }

    set connector [ vtkbisDatabase New ]
    $connector InitializeSQLite $dbname
    set ok [ $connector Connect ]
    if { $ok == 0 } {
	set errormessage "Failed to open sqlite database $dbname" 
	$connector Delete
	return 0
    }
    set dbase [ vtkbisFilenameTable New ]
    $dbase SetConnector $connector
    $dbase CreateTable

    set lst [ split [ $dbase QueryAll $tpname ] "|" ]
    set max [ expr [ llength $lst ] -1 ]
    for { set i 0 } { $i < $max } { incr i } {
	puts stdout "Item $i = [ lindex $lst $i ]"
    }

    puts stdout "max=$max, lst=$lst"

    if { [ llength $lst ] >= $index } {

	set line [ lindex $lst $index ]
	set lst2 [  split $line "," ]
	set key   [string trim   [ lindex $lst2 1 ] ]
	set fname0 [string trim   [ lindex $lst2 2 ] ]

	set fname [ file join [ file dirname $dbname ] [ file tail $fname0 ] ]
	puts stdout "\n\n\n\n Loading $key:$fname0 --> $fname "
	set ok [ [ $this GetOutputObject out_image ] Load $fname ]

	if { $ok > 0 } {
	    set fdir [ file normalize [ file dirname $fname ] ]
	    set ftail [ file tail $fname ]
	    [ $this GetOutputObject out_image ] SetFileName  [ file join $fdir  "SQL_${ftail}" ]
	} else {
	    set errormessage "Failed to load image from $fname"
	}
    } else {
	set ok 0
	set errormessage "Failed To Find $index in database $tpname"
    }

    $dbase Delete
    $connector Delete

    return $ok
}
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_testdatabase [pxvtable::vnewobj]]
    $alg MainFunction 
}

