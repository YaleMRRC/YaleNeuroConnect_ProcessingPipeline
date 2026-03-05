#!/bin/sh
#Next line is a comment in Tcl, but not in bash \
exec wish -f "$0" ${1+"@0"}
#Now we have access to tk from within this script
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

wm withdraw .

package provide chellyDB 1.0

#---------------------------------------------------------------------------------------------
#Import of required packages and other required initialization defs
#---------------------------------------------------------------------------------------------
lappend auto_path [file dirname [info script]]
package require pxitclchellypackages 1.0


# Require key packages
# Xenios' C++ Extensions
package require vtkpxcontrib     1.0

# Simple Naming package
package require Itcl
package require Iwidgets

package require struct;#This package includes the "struct::tree"

#This is the metakit package -  may be used at some point
#package require Mk4tcl;


#------------------------------------------------------------------------------------------
#Base Class defining the database
#------------------------------------------------------------------------------------------
::itcl::class chellyDBManager {

    variable DataTree
    variable MultiSubjData
    variable msbDataArray
    variable CSIPatientData
    variable ElectrodeAttributeArray
    public variable masterpath ""
    public variable masterlist ""

    public method SaveDatatree {} {}
    public method LoadDatatree {} {}

    constructor { } { 

    }
    
    destructor {
	catch {unset DataTree}
    }


}



#------------------------------------------------------------------------------------------
# Basic Save/Load file implementation of the DB
#------------------------------------------------------------------------------------------


::itcl::class chellyDBBasic {

    inherit chellyDBManager

    #These two methods overload the methods in the abstract class chellyDBManager
    public method SaveDatatree { TreeArrayList {filename -1} }
    public method LoadDatatree { {filename -1} }
    public method LoadElectrodeAttributes { {filename -1} } 
    public method LoadMSBfile { {filename -1} }
    public method LoadCSIPatientFile { {filename -1} }

    public method SaveFile {object}
    public method LoadFile {imgobj filename desc}
    public method LoadTransformationFile {transobj filename}
    
    public method GetImageFileName {}
    public method GetSurfaceFileName {}
    public method GetLandmarkFileName {}
    public method GetElectrodeFileName {}

    public method GetTransformationFileName {}    

    public method SaveTypeDefs { TypeArrayList }
    public method LoadTypeDefs { }

    constructor { } {

    }

}

##########################################################################################
# These methods load and save whole trees
##########################################################################################

::itcl::body chellyDBBasic::SaveDatatree { TreeArrayList {filename -1} } {

    #puts  [ file extension $filename ]
   
    if {$filename == -1} {
	set typelist {
	    {"Tree Definition File" {.tre}}
	    {"All Files" {*}}
	}
	
	set filename [tk_getSaveFile -filetypes $typelist]
    }
    
    if {[llength $filename]} {

	set ext [ file extension $filename ]
	if { $ext != ".tre" } {
	    set filename set "${filename}.tre"
	    
	}


	array set tmparray $TreeArrayList
	
	set f [ open $filename w ]
	puts $f "\#Chelly's Datatree File Format"
	
	set keylist [ array names tmparray ]
	set keylist [lsort $keylist]
	
	for { set k 0 } { $k < [llength $keylist] } { incr k } {
	    set key [lindex $keylist $k]
	    set val $tmparray($key)
	    set ext [ file extension $val ]
	    if { $key != "serialized" } {
		if { $ext != ".donotsave" } {
		    puts $f "$key  : $val"
		} else {
		    puts $f "$key : "
		}
	    }
	}
	set key "serialized" 
	puts $f "$key  : $tmparray($key)"
	close $f
    } else {return -1}

}


::itcl::body chellyDBBasic::LoadDatatree { {filename -1} } {

    if { $filename == -1 } {
	set typelist {
	    {"Tree Definition File" {.tre}}
	    {"All Files" {*}}
	}
	
	set filename [tk_getOpenFile -filetypes $typelist]
    }

    if {[llength $filename]} {
	set fileid [open $filename r]
	
	gets $fileid line
	
	if { [ string compare $line "#Chelly's Datatree File Format" ] != 0 } {
	    puts stderr " File is not in Chelly's Datatree File Format "
	    close $fileid
	    return 0
	}
	
	while { [ gets $fileid line ] >=0 } {
	    set index [string first ":" $line]
	    
	    if { $index > 0 }  {
		set len   [string length $line]
		
		set key   [string trim   [string range $line 0 [expr $index - 1]]]
		set value [string trim [string range $line [expr $index +1] [expr $len -1]]]
		set newtree($key)  $value 
		#puts stderr "New key = $key, value = \"$value\""
	    }
	}  
	close $fileid
	
	#Throw a key into the array to tag its type
	set newtree(ChellysTreeFormat) 1
	set newtree(ThisFileName) $filename
	set newlist [ array get newtree ]
	return $newlist
	
    } else { return -1 }
}

::itcl::body chellyDBBasic::LoadElectrodeAttributes { { filename -1 } } {

    catch {unset ElectrodeAttributeArray}

    if {$filename == -1} {
	set typelist {
	    {"Electrode Attribute File" {.ele}}
	    {"All Files" {*}}
	}

	set filename [tk_getOpenFile -filetypes $typelist]

    } 
    
    if {[llength $filename]} {
	set fileid [open $filename r]
	
	gets $fileid line
	
	if { [ string compare $line "#Electrode Attribute Description File" ] != 0 } {
	    puts stderr " File is not in Electrode Attribute File Format "
	    close $fileid
	    return 0
	}
	
	gets $fileid line
	gets $fileid line
	gets $fileid line
	
	set alltitles $line
	set numtitles [llength $alltitles]

	set titles [lrange $alltitles 2 end]
	set ElectrodeAttributeArray(titles) $titles
	
	gets $fileid line

	while { [ gets $fileid line ] >=0 } {
	    #Read the line in:
	    set istr $line
		
	    set gridletter [ string range [lindex $istr 1] 0 0 ]
	    set electrodenumber [ string range [lindex $istr 1] 1 end ]
	   
	    for {set a 0} {$a < [expr $numtitles - 2 ]} {incr a} {
		if {[llength $gridletter] > 0 && [llength $electrodenumber] > 0} {
		    set ElectrodeAttributeArray($gridletter,$electrodenumber,$a) [lindex $istr [expr $a + 2] ]
		}
	    }
	    
	}

	close $fileid
	return [array get ElectrodeAttributeArray]

    } else { return -1 }
    
}; #End LoadElectrodeAttributes method


::itcl::body chellyDBBasic::LoadMSBfile { {filename -1} } {

    if {$filename == -1} {
	set typelist {
	    {"Multisubject Description File" {.msb}}
	    {"All Files" {*}}
	}
	
	set filename [tk_getOpenFile -filetypes $typelist]
    } 

    if {[llength $filename]} {
	set fileid [open $filename r]
	
	gets $fileid line

	if { [ string compare $line "#Multisubject Description File v2" ] != 0 } {
	    if { [ string compare $line "#Multisubject Description File v3"  ] != 0 } {
		puts stderr " File is not in Multisubject fMRI Description File Format "
		close $fileid
		return 0
	    } else {
		set setupmode 2
	    }
	} else {
	    set setupmode 1
	}
	

	gets $fileid line 
	if {$line == "Tasks"} {
	    gets $fileid line 
	    set numtasks $line
	    if {$numtasks < 1} {error "There are no tasks in this file"; return -1}
	}
	set msbDataArray(numtasks) $numtasks

	gets $fileid line;# skip a line

	for {set i 0} {$i < $numtasks} {incr i} {
	    gets $fileid line;     #Task Name 
	    set index [string first ":" $line]
	    set value [string trim [string range $line [expr $index +1] [expr [string length $line] -1]]]
	    lappend TaskNames $value
	    gets $fileid line;     #Task Suffix 
	    set index [string first ":" $line]
	    set value [string trim [string range $line [expr $index +1] [expr [string length $line] -1]]]
	    lappend TaskSuffixes $value
	    gets $fileid line;     # skip a line
	}
	set msbDataArray(tasknames) $TaskNames
	set msbDataArray(tasksuffixes) $TaskSuffixes

	puts stderr "TaskNames=$TaskNames, $TaskSuffixes"

	gets $fileid line;         # Subjects 
	if {$line == "Subjects"} {
	    gets $fileid line 
	    set numsubjects $line
	    if {$numsubjects < 1} {error "There are no subjects in this file"; return -1}
	}	
	set msbDataArray(numsubjects) $numsubjects
	
	gets $fileid line;     # skip a line

	#For each subject:
	#------------------------------------------------------------------------------------------
	for {set n 0} {$n < $numsubjects} {incr n} {

	    if { $setupmode == 2 } {
		gets $fileid line
		set index [string first ":" $line]
		set value2 [string trim [string range $line [expr $index +1] [expr [string length $line] -1]]]
		regsub -all ":" $value2 " " value
		if { [ string length $value ] > 0 } {
		    set msbDataArray($n,Name) $value
		} else {
		    set msbDataArray($n,Name) [ format "Subject %02d" [expr $n+1 ] ]
		}
	    } else {
		set msbDataArray($n,Name) [ format "Subject %02d" [expr $n+1 ] ]
	    }
	    puts stderr "Name=$msbDataArray($n,Name)"

	    gets $fileid line;     # Anatomical Image
	    set index [string first ":" $line]
	    set value [string trim [string range $line [expr $index +1] [expr [string length $line] -1]]]
	    set msbDataArray($n,Anatomical) $value
	    #--------------------------------------------------
	    gets $fileid line;     # Conventional Image
	    set index [string first ":" $line]
	    set value [string trim [string range $line [expr $index +1] [expr [string length $line] -1]]]
	    set msbDataArray($n,Conventional) $value
	    #--------------------------------------------------

	    #----------------------------------------------------------##
	    #----------------------------------------------------------##
	    #Generation and reading of functional data file names
	    gets $fileid line;     # Functional Image (use this to generate the rest)
	    set index [string first ":" $line]
	    set value [string trim [string range $line [expr $index +1] [expr [string length $line] -1]]]

	    set basefilename $value
	    set oldsuffix [lindex $TaskSuffixes 0]

	    foreach TaskSuf $TaskSuffixes {
		set ind [ string last $oldsuffix $basefilename ]
		regsub -start $ind $oldsuffix $basefilename $TaskSuf f2
		set msbDataArray($n,Task_$TaskSuf) $f2
	    }
	    #----------------------------------------------------------##
	    #----------------------------------------------------------##
	   
	    #--------------------------------------------------
	    gets $fileid line;     # Reference Transformation
	    set index [string first ":" $line]
	    set value [string trim [string range $line [expr $index +1] [expr [string length $line] -1]]]
	    set msbDataArray($n,ReferenceTrans) $value
	    #----------------------------------------	    	    
	    gets $fileid line;     # Internal Transformation
	    set index [string first ":" $line]
	    set value [string trim [string range $line [expr $index +1] [expr [string length $line] -1]]]
	    set msbDataArray($n,InternalTrans) $value
	    #----------------------------------------	    	    
	    gets $fileid line;     # Echoplanar Image
	    set index [string first ":" $line]
	    set value [string trim [string range $line [expr $index +1] [expr [string length $line] -1]]]
	    set msbDataArray($n,Echoplanar) $value
	    #----------------------------------------	    	    
	    gets $fileid line;     # Distortion Transformation
	    set index [string first ":" $line]
	    set value [string trim [string range $line [expr $index +1] [expr [string length $line] -1]]]
	    set msbDataArray($n,DistortionTrans) $value
	    #----------------------------------------	    	    
	    gets $fileid line;     # Fieldmap Image
	    set index [string first ":" $line]
	    set value [string trim [string range $line [expr $index +1] [expr [string length $line] -1]]]
	    set msbDataArray($n,FieldMap) $value
	    #----------------------------------------	    	    
	    gets $fileid line;     # skip a line

	 #   puts stderr "Subject [ expr $n+1 ]: $msbDataArray($n,Name), $msbDataArray($n,Anatomical), $msbDataArray($n,Conventional)"

	};# matches "for $numsubjects"
	
	#------------------------------------------------------------------------------------------
	# Now read in the reference image stuff
	#------------------------------------------------------------------------------------------
	
	gets $fileid line;     # skip a line
	gets $fileid line;     # skip a line
	#gets $fileid line;     # skip a line
	#puts stderr "Last Skipped line = $line"

	gets $fileid line;     # Reference Image
	set index [string first ":" $line]
	set value [string trim [string range $line [expr $index +1] [expr [string length $line] -1]]]
	set msbDataArray(ReferenceImage) $value
	#	puts stderr "$index :$value, $msbDataArray(ReferenceImage)"

	if { $setupmode == 2 } {
	    gets $fileid line;     # VOI Image
	}
	
	gets $fileid line;     # Average Anatomical
	set index [string first ":" $line]
	set value [string trim [string range $line [expr $index +1] [expr [string length $line] -1]]]
	set msbDataArray(AverageAnatomical) $value
	
	gets $fileid line;     # Std Anatomical
	set index [string first ":" $line]
	set value [string trim [string range $line [expr $index +1] [expr [string length $line] -1]]]
	set msbDataArray(StdAnatomical) $value
	
	foreach st {AverageFunctional StdFunctional ZscoreFunctional} {
	
	    #----------------------------------------------------------##
	    #----------------------------------------------------------##
	    #Generation and reading of functional data file names
	    gets $fileid line;     # Base (Average Functional, Standard Functional, Z-score Functional)
	    set index [string first ":" $line]
	    set value [string trim [string range $line [expr $index +1] [expr [string length $line] -1]]]
	    
	    set basefilename $value
	    puts stderr "$value"
	    set oldsuffix [lindex $TaskSuffixes 0]
	    
	    foreach TaskSuf $TaskSuffixes {
		set ind [ string last $oldsuffix $basefilename ]
		regsub -start $ind $oldsuffix $basefilename $TaskSuf f2
		set msbDataArray($st,Task_$TaskSuf) $f2
	    }
	    #----------------------------------------------------------##
	    #----------------------------------------------------------##
	    
	}
	
	close $fileid
	
# 	foreach {k} [lsort [array names msbDataArray]] {
# 	    puts "$k   :   $msbDataArray($k)"
#	}
	

	return [array get msbDataArray]

    } else {return -1}
    
}


##########################################################################################

::itcl::body chellyDBBasic::LoadCSIPatientFile { {filename -1} } {

    if {$filename == -1} {
	set typelist {
	    {"CSI Patient Description File" {.csi}}
	    {"All Files" {*}}
	}
	
	set filename [tk_getOpenFile -filetypes $typelist]
    } 

    if {[llength $filename]} {
	set fileid [open $filename r]
	
	gets $fileid line

	if { [ string compare $line "#CSI Subject Description File" ] != 0 } {
	    puts stderr " File is not in CSI Patient Description File Format "
	    close $fileid
	    return 0
	}

	gets $fileid line 
	gets $fileid line;# "Transformations" title
	gets $fileid line 

	gets $fileid line 
	set index [string first ":" $line]
	set value [string trim [string range $line [expr $index +1] [expr [string length $line] -1]]]
	set CSIPatientData(TransAnat2CSIConv) $value

	gets $fileid line;# skip a line
	gets $fileid line;# "Images" title
	gets $fileid line;# skip a line

	#----------------------------------------------------------------------
	gets $fileid line 
	set index [string first ":" $line]
	set value [string trim [string range $line [expr $index +1] [expr [string length $line] -1]]]
	set CSIPatientData(Anatomical) $value
	#----------------------------------------------------------------------
	gets $fileid line 
	set index [string first ":" $line]
	set value [string trim [string range $line [expr $index +1] [expr [string length $line] -1]]]
	set CSIPatientData(Conventional) $value
	#----------------------------------------------------------------------
	gets $fileid line 
	set index [string first ":" $line]
	set value [string trim [string range $line [expr $index +1] [expr [string length $line] -1]]]
	set CSIPatientData(RawCSIImage) $value
	#----------------------------------------------------------------------
	gets $fileid line 
	set index [string first ":" $line]
	set value [string trim [string range $line [expr $index +1] [expr [string length $line] -1]]]
	set CSIPatientData(PMAPCSIImage) $value
	#----------------------------------------------------------------------
	gets $fileid line 
	set index [string first ":" $line]
	set value [string trim [string range $line [expr $index +1] [expr [string length $line] -1]]]
	set CSIPatientData(NormSmooth1) $value
	#----------------------------------------------------------------------
	gets $fileid line 
	set index [string first ":" $line]
	set value [string trim [string range $line [expr $index +1] [expr [string length $line] -1]]]
	set CSIPatientData(NormSmooth2) $value
	#----------------------------------------------------------------------

	gets $fileid line;# skip a line
	gets $fileid line;# "Extra Information" title
	gets $fileid line;# skip a line





	close $fileid
	
		foreach {k} [lsort [array names CSIPatientData]] {
		    puts "$k   :   $CSIPatientData($k)"
		}


	return [array get CSIPatientData]

    } else {return -1}

}

::itcl::body chellyDBBasic::SaveFile {objeect} {

    #    set filename [tk_getSaveFile]
    $object Save ""
    return [$object cget -filename]
    
}

::itcl::body chellyDBBasic::LoadFile {object filename desc} {
    
    set obj $object
    set picknew "no"
    
    #If the filename has not been set, offer the option of setting it here.
    if {$filename == -1} {
	return -1
#	set picknew [tk_messageBox -type yesno -default no  -message "No filename has been specified for this object.  Would you like to select one?" -icon question]
    } else {
	
	#If the file exists, load it (this should be the normal case)
	if {[file exists $filename]} {
	    $obj Load $filename $desc
	} else {
	    #If the filename has been set, but the file doesn't exist, offer the option of resetting
	    set picknew [tk_messageBox -type yesno -default no \
			     -message "The file that this object points to does not appear to exist.  Would you like to specify a new one?" -icon question]
	}
	
    }; #end if filename == -1
    
    
    
    #---------------------------------------------------------------------------------
    #If picknew has been set to yes, choose a new file, and return it, else return 0
    if {$picknew == "yes"} {
	return 1	
    } else { return 0 }
    #---------------------------------------------------------------------------------
    
    
    
}; #end method LoadFile

::itcl::body chellyDBBasic::LoadTransformationFile {transobj filename} {

	if {$filename == -1} {
	    $transobj Load "" Transformation
	} else {  $transobj Load $filename Transformation }



}

::itcl::body chellyDBBasic::GetImageFileName { } {

    set desc "Image"

    set filename [info script]

	set typelist {
	    {"Analyze/NIFTI" {".hdr*" ".nii*" } }
	    {"Analyze Files" {.hdr*}}
	    {"Brain Voyager Files"  {.vtc}}
	    {"All Files" {*}}}

	set f2path [ file dirname $filename ]
	set f2tail [ file tail    $filename ]
	set fname  [tk_getOpenFile -title "Load $desc" -filetypes $typelist -initialfile $f2tail -initialdir $f2path ]
    
    if {[llength $fname]} {
	return $fname
    } else {return -1}
}

::itcl::body chellyDBBasic::GetSurfaceFileName { } {

    set desc "Surface"

    set filename [info script]

	set typelist {
	    {"Surface" {".vtk" } }
	    {"All Files" {*}}}

	set f2path [ file dirname $filename ]
	set f2tail [ file tail    $filename ]
	set fname  [tk_getOpenFile -title "Load $desc" -filetypes $typelist -initialfile $f2tail -initialdir $f2path ]
    
    if {[llength $fname]} {
	return $fname
    } else {return -1}
}

::itcl::body chellyDBBasic::GetLandmarkFileName { } {

    set desc "Landmark"

    set filename [info script]

	set typelist {
	    {"Landmark" {".land" } }
	    {"All Files" {*}}}

	set f2path [ file dirname $filename ]
	set f2tail [ file tail    $filename ]
	set fname  [tk_getOpenFile -title "Load $desc" -filetypes $typelist -initialfile $f2tail -initialdir $f2path ]
    
    if {[llength $fname]} {
	return $fname
    } else {return -1}
}

::itcl::body chellyDBBasic::GetElectrodeFileName { } {

    set desc "Electrode"

    set filename [info script]

	set typelist {
	    {"Electrode" {".mgrid" } }
	    {"All Files" {*}}}

	set f2path [ file dirname $filename ]
	set f2tail [ file tail    $filename ]
	set fname  [tk_getOpenFile -title "Load $desc" -filetypes $typelist -initialfile $f2tail -initialdir $f2path ]
    
    if {[llength $fname]} {
	return $fname
    } else {return -1}
}





::itcl::body chellyDBBasic::GetTransformationFileName { } {


    set desc "Transformation"

    set filename [info script]

	set typelist {
	    {"Matrix/Grid Files" {".matr" ".grd*" } }
	    {"Matrix Files" {.matr}}
	    {"Grid/Combo Transform Files"  {.grd*}}
	    {"Thin Plate Spline Transforms" {.tps}}
	    {"PolySimilarity Transforms" {.psim}}
	    {"Old Matrix Files" {.mat}}
	    {"All Files" {*}}}
	
	set f2path [ file dirname $filename ]
	set f2tail [ file tail    $filename ]
	set f [tk_getOpenFile -title "Load $desc" -initialfile $f2tail -filetypes $typelist -initialdir $f2path]

    if {[llength $f]} {
	return $f
    } else { return -1 }

}

::itcl::body chellyDBBasic::SaveTypeDefs { TypeArrayList } {

    set filename [tk_getSaveFile]

    if {[llength $filename]} {
	array set tmparray $TypeArrayList
	
	set f [ open $filename w ]
	puts $f "\#Chelly's TypeList File Format"
    
	set keylist [ array names tmparray ]
	
	for { set k 0 } { $k < [llength $keylist] } { incr k } {
	    set key [lindex $keylist $k]
	    set val $tmparray($key)
	    set ext [ file extension $val ]
	    
	    puts $f "$key  : $val"
	    
	}
	
	close $f

    } else {return -1}
}



::itcl::body chellyDBBasic::LoadTypeDefs { } {

    set typelist {
	{"All Files" {*}}
    }
    set filename [tk_getOpenFile -filetypes $typelist]

    if {[llength $filename]} {
	
	set fileid [open $filename r]
	
	gets $fileid line
	
	if { [ string compare $line "#Chelly's TypeList File Format" ] != 0 } {
	    
	    puts stderr " File is not in Chelly's TypeList File Format "
	    close $fileid
	    return 0
	}
	
	
	#    set OutTreeList [read $f]
	
	while { [ gets $fileid line ] >=0 } {
	    set index [string first ":" $line]
	    
	    if { $index > 0 }  {
		set len   [string length $line]
		
		set key   [string trim   [string range $line 0 [expr $index - 1]]]
		set value [string trim [string range $line [expr $index +1] [expr $len -1]]]
		set newdefarray($key)  $value 
		#puts stderr "New key = $key, value = \"$value\""
	    }
	}  
	close $fileid
	
	set newlist [ array get newdefarray ]
	return $newlist 
    } else { return -1 }

}

#------------------------------------------------------------------------------------------
#-----This class extends the Basic Class, and simply uses relative path names -------------
#-----for all saving and loading operations.  This allows for portability of --------------
#-----of the trees, and the potential to move all data contained within a tree-------------
#-----efficiently--------------------------------------------------------------------------
#------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------


::itcl::class chellyDBRelative {

    inherit chellyDBBasic

    #These two methods overload the methods in chellyDBBasic
    public method SaveDatatree { TreeArrayList {filename -1} }
    public method SaveDataTreeClean { TreeArrayList } 
    public method SaveDataTreeFilesReorg { TreeArrayList }
    public method LoadDatatree { {filename -1} }

    constructor { } { 

    }

}


::itcl::body chellyDBRelative::SaveDatatree { TreeArrayList {filename -1} } {

    if {$filename == -1} {
	set typelist {
	    {"Tree Definition File" {.tre}}
	    {"All Files" {*}}
	}

	set filename [tk_getSaveFile -filetypes $typelist]
    }

    if { [ string length $filename ] < 1 } {
	return -1
    }

    if { [ file extension $filename ] != ".tre" } {
	set filename "${filename}.tre"
    }

    set treepath [file dirname $filename]
    

    array set tmparray $TreeArrayList
    
    set f [ open $filename w ]
    puts $f "\#Chelly's Datatree File Format"
    
    set keylist [ array names tmparray ]
    set keylist [lsort $keylist]
    
    for { set k 0 } { $k < [llength $keylist] } { incr k } {
	
	#Look at each member of the array in order, and evaluate them for saving
	
	set key [lindex $keylist $k]
	
	#If the key is "filename" we have to trim it in order to support portability
	if {[string match -nocase {*filename} $key]} {
	    
	    set valmodified 0
	    for {set b 0} {$b < [string length $tmparray($key)]} {incr b} {
		if {[string match -nocase $treepath [string range $tmparray($key) 0 $b]]} {
		    set valmodified 1
		    set val [string range $tmparray($key) [expr $b + 2] end]
		    
		}
	    } 
	    if {!$valmodified} {
		set val $tmparray($key)
	    }
	    
	} else {
	    set val $tmparray($key)
	}
	set ext [ file extension $val ]
	if { $key != "serialized" } {
	    if { $ext != ".donotsave" } {
		puts $f "$key : $val"
	    } else {
		puts $f "$key :  "
	    }
	}
    }
    set key "serialized" 
    puts $f "$key : $tmparray($key)"
    close $f
    return 1

};# End SaveDataTree

::itcl::body chellyDBRelative::SaveDataTreeClean { TreeArrayList } {

#This method is obsolete by the SaveDataTreeFilesReorg method
#It never gets called from the main program

    set typelist {
	{"Tree Definition File" {.tre}}
	{"All Files" {*}}
    }

    set filename [tk_getSaveFile -filetypes $typelist]
    set treepath [file dirname $filename]

    if {[llength $filename]} {
	
	if { [ file extension $filename ] != ".tre" } {
	    set filename "${filename}.tre"
	}
	
	array set tmparray $TreeArrayList
	
	set f [ open $filename w ]
	puts $f "\#Chelly's Datatree File Format"
	
	set keylist [ array names tmparray ]
	set keylist [lsort $keylist]
	
	for { set k 0 } { $k < [llength $keylist] } { incr k } {

	    #Look at each member of the array in order, and evaluate them for saving

	    set key [lindex $keylist $k]

	    #-------------------------------------------------------------------------------------------
	    #If the key is "filename" we have to trim it in order to support portability,
	    #as well as save the filenames in a separate  array for later use in the new folder location
	    #-------------------------------------------------------------------------------------------
	    if {[string match -nocase {*filename} $key]} {
		
		set val $tmparray($key)
	
		set ext [ file extension $val ]
		if { $ext != ".donotsave" } {
		    if { $val != -1 } {
			
			set valFileNames($key) [file tail $val]
			set valDirNames($key) [file dirname $val]
			set valFolderLists($key) [file split $valDirNames($key)]
			
			#--Debug----------------------------------------
#			puts "$key  :  $valFolderLists($key)"
			#-----------------------------------------------
			
		    }
		}
		#End of file name stuff
			
	    } else {
		#This is for all other keys (that do not include the string "filename")
		set val $tmparray($key)
	    }
	    
	    set ext [ file extension $val ]
	    if { $key != "serialized" } {
		if { $ext != ".donotsave" } {
		    set SavingArray($key) "$key : $val"
		} else {
		    set SavingArray($key)  "$key : "
		}
	    }
	}
	
	
	#-----------------------------------------------------------------------------
	#Trim the filenames 
	#-----------------------------------------------------------------------------
	
	foreach r [array names valFolderLists] {
	    lappend listOfDirLists $valFolderLists($r)
	}
	set longest 0
	foreach l $listOfDirLists {
	    if {[llength $l] > $longest} {
		set longest [llength $l]
	    }
	}
	for {set i 0} {$i < $longest} {incr i} {
	    set remove($i) 1
	    for {set j 0} {$j < [llength $listOfDirLists]} {incr j} {
		if {[lindex [lindex $listOfDirLists $j] $i] != [lindex [lindex $listOfDirLists 0] $i]} {
		    set remove($i) 0
		    for {set pt $i} {$pt < $longest} {incr pt} {set remove($pt) 0}
		}		
	    }
	}
	
	set commonEnd 0
	set done 0
	while {$done == 0 } {
	    if {$commonEnd < $longest} {
		if {$remove($commonEnd) == 1} {
		    incr commonEnd
		} else {set done 1}
	    } else {set done 1}
	}


	
	#-----------------------------------------------------------------------------------------------
	#
	# If you comment this out, then no containing directory will be created, and the files will be
	# copied directly into the directory that holds the tree
	#
	#-----------------------------------------------------------------------------------------------
	set commonEnd [expr $commonEnd - 1]
	#-----------------------------------------------------------------------------------------------


	#Construct Full path
	for {set v 0} {$v < [llength [array names valFolderLists]]} {incr v} {
	    set ind [lindex [lsort [array names valFolderLists]] $v]
	    set endofpath [lrange $valFolderLists($ind) $commonEnd end ]

	    set pathEnd ""
	    for {set g 0 } {$g < [llength $endofpath]} {incr g} {
		set pathEnd [file join $pathEnd [lindex $endofpath $g]]
	    }

	    lappend dirstomake [file join $treepath $pathEnd]
	    set newfilename($ind) [file join $treepath $pathEnd $valFileNames($ind)]

	}

	#------------------------------------------------------------------------------------------
	# Make directories, and copy the file to its new location
	foreach direktory $dirstomake {
	    file mkdir $direktory
	}
	for {set w 0} {$w < [llength [array names newfilename]]} {incr w} {
	    set TheKey [lindex [lsort [array names valFolderLists]] $w]
	    puts stderr "$TheKey, $tmparray($TheKey)"
	    if {[string match -nocase {*trans*filename} $TheKey]} {
		#Create and Save a temporary transformation object
		set newobj [ [pxitcltransform \#auto ] GetThisPointer  ]
	    } else {
		set ext  [ file extension $newfilename($TheKey) ]
		if { $ext == ".mgrid" } {
		    set newobj [ [ pxitclelectrodemultigrid \#auto] GetThisPointer ]
		} elseif { $ext == ".land" } {
		    set newobj [ [ pxitcllandmarks \#auto] GetThisPointer ]
		} elseif { $ext == ".vtk" } {
		    set newobj [ [ pxitclsurface \#auto] GetThisPointer ]
		} else {
		    set newobj [ [ pxitclimage \#auto] GetThisPointer ]
		}
	    }
	    $newobj Load $tmparray($TheKey) 
	    $newobj Save $newfilename($TheKey)
	    ::itcl::delete object $newobj
	}

	#----------------------------------------------------------------------
	# Now trim each newly saved filename to support relative pathname saving in the tree
	#----------------------------------------------------------------------
	for {set w 0} {$w < [llength [array names newfilename]]} {incr w} {
	    set TheKey [lindex [lsort [array names valFolderLists]] $w]
	    set valmodified 0
	    for {set b 0} {$b < [string length $newfilename($TheKey)]} {incr b} {
		if {[string match -nocase $treepath [string range $newfilename($TheKey) 0 $b]]} {
		    set valmodified 1
		    set Thisval [string range $newfilename($TheKey) [expr $b + 2] end]
		    
		}
	    } 
	    if {!$valmodified} {
		set Thisval $newfilename($TheKey)
	    }

	    set ext [ file extension $Thisval ]
	    if { $TheKey != "serialized" } {
		if { $ext != ".donotsave" } {
		    set SavingArray($TheKey) "$TheKey : $Thisval"
		} else {
		    set SavingArray($TheKey) "$TheKey : "
		}
	    }
	    
	}

	

	#----------------------------------------------------------------------
	#Write the results to the file
	#----------------------------------------------------------------------
	foreach name [lsort [array names SavingArray]] {
	    
	    puts $f $SavingArray($name)
	    
	}
	
	set key "serialized" 
	puts $f "$key  : $tmparray($key)"
	close $f
	
	return [LoadDatatree $filename]
	
    } else {return -1}
    
}; #End SaveDataTreeClean method



::itcl::body chellyDBRelative::SaveDataTreeFilesReorg { TreeArrayList } {

    set typelist {
	{"Tree Definition File" {.tre}}
	{"All Files" {*}}
    }

    set filename [tk_getSaveFile -filetypes $typelist]
    set treepath [file dirname $filename]


    if {[llength $filename]} {

	if { [ file extension $filename ] != ".tre" } {
	    set filename "${filename}.tre"
	}

	#Add a key to every node in the this temporary tree that will contain a list of its parent folders
	array set tmparray $TreeArrayList
	set tempTree [	::struct::tree [pxvtable::vnewobj] deserialize $tmparray(serialized)]
	foreach child [$tempTree children -all [$tempTree rootname]] {
	    $tempTree set $child ffList ""
	}

	#Walk the tree in a breadth-first manner
	$tempTree walk [$tempTree rootname] -type bfs node {
	    if {$node != [$tempTree rootname]} {
		
		set par [$tempTree parent $node]

		if {$par != [$tempTree rootname]} {
		    set newffList [$tempTree get $par ffList]
		    if {[$tempTree get $par type] == "Folder" | [$tempTree get $par type] == "Patient"} {
			lappend newffList [string map {" " _} [$tempTree get $par title]]
		    }
		    $tempTree set $node ffList $newffList

		};#End if $par != root

		set newfilepath $treepath
		for {set r 0} {$r < [llength [$tempTree get $node ffList]]} {incr r} {
		    set newfilepath [file join $newfilepath [lindex [$tempTree get $node ffList] $r] ]	
		}	

		#Create a directory (this does not overwrite old directories, and intermediates are created if needed
		file mkdir $newfilepath

		foreach key [$tempTree keys $node] {
		    if { [string match -nocase {*filename} $key] } {
			if {[$tempTree get $node $key] != -1 && [file extension [$tempTree get $node $key]] != ".donotsave"} {
			    set NewFilename [ file join $newfilepath [file tail [$tempTree get $node $key]]]
			    #If it's a transformation, create a new trans object, and save it in the new place
			    #			    puts stderr "$NewFilename, $key"
			    if { [string match -nocase {*trans*filename} $key] } {
				set newtemptr [ [pxitcltransform \#auto ] GetThisPointer  ]
				$newtemptr Load [$tempTree get $node $key]
				$newtemptr Save $NewFilename
				::itcl::delete object $newtemptr
			    } else {
				#Otherwise, assume it's an image
				set ext  [ file extension $NewFilename ]
				if { $ext == ".mgrid" } {
				    set newtempimg [ [ pxitclelectrodemultigrid \#auto] GetThisPointer ]
				} elseif { $ext == ".land" } {
				    set newtempimg [ [ pxitcllandmarks \#auto] GetThisPointer ]
				} elseif { $ext == ".vtk" } {
				    set newtempimg [ [ pxitclsurface \#auto] GetThisPointer ]
				} else {
				    set newtempimg [ [ pxitclimage \#auto] GetThisPointer ]
				}
				
				$newtempimg Load [$tempTree get $node $key]
				$newtempimg Save $NewFilename
				::itcl::delete object $newtempimg
			    }
			    #set the key properly in the tree, and tmparray
			    $tempTree set $node $key $NewFilename

			    set alllowers [string tolower $key];#A lower-case key title
			    set tmparray($node,$alllowers) $NewFilename
			}
		    }
		}
		
	    };#End if $node != root
	};#End walk

	#Now unset all those temporary ffList keys in the tree
	foreach child [$tempTree children -all [$tempTree rootname]] {
	    $tempTree unset $child ffList
	}


	chellyDBRelative::SaveDatatree [array get tmparray] $filename 
	return [LoadDatatree $filename]
	
    } else {return -1}
    
}; #End SaveDataTreeFilesReorg method		


::itcl::body chellyDBRelative::LoadDatatree { {filename -1} } {

    if {$filename == -1} {
	set typelist {
	    {"Tree Definition File" {.tre}}
	    {"All Files" {*}}
	}
	set filename [tk_getOpenFile -filetypes $typelist]
    }

    if {[llength $filename]} {
	set treepath [file dirname $filename]

	set fileid [ open $filename r ]
	gets $fileid line
	
	if { [ string compare $line "#Chelly's Datatree File Format" ] != 0 } {
	    puts stderr " File is not in Chelly's Datatree File Format "
	    close $fileid
	    return 0
	}
	
	
	#    set OutTreeList [read $f]
	
	while { [ gets $fileid line ] >=0 } {
	    set index [string first ":" $line]
	    
	    if { $index > 0 }  {
		set len   [string length $line]
		set key   [string trim   [string range $line 0 [expr $index - 1]]]

		if {[string match -nocase {*filename} $key]} {

		    set tempvalue [string trim [string range $line [expr $index +1] [expr $len -1]]]
		    if {$tempvalue != -1} {
			set value [file join $treepath $tempvalue]
		    } else {
			set value $tempvalue
		    }

		} else {
		    set value [string trim [string range $line [expr $index +1] [expr $len -1]]]
		}

		if { [ llength $masterlist ] > 0 } {
		    
		    # Detect and change
		    set newindex [string first "filename" $key]
		    if { $newindex >= 0 } {
			set fname [ file tail $value ]
			set tt [ lsearch $masterlist $fname ]
			if { $tt >= 0 } {
			    set newfname [ file join $masterpath $fname ]
			    pxtkprint "DataTree: Found $fname, $value replacing with $newfname\n"
			    set value $newfname
			}
		    }
		}

		set newtree($key)  $value 
		#puts stderr "New key = \"$key\" \t\t value = \"$value\""
	    }
	}  
	close $fileid

	#Throw a couple keys into the array to tag its type, filename, etc.
	set newtree(ChellysTreeFormat) 1
	set newtree(ThisFileName) $filename
	set newlist [ array get newtree ]
	return $newlist 

    } else { return -1 }
}

