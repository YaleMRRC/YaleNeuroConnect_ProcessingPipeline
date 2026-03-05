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

package provide pxtclreadvarianheader 1.0

# 	$Id: pxtclreadvarianheader.tcl,v 1.1 2002/02/20 18:07:50 Xenios Exp Xenios $	







package require pxvtable 1.0
package require vtkpxcontrib 1.0

namespace eval ::pxtclreadvarianheader {

    proc ReadVarianHeader { fname } {
	
	if { [string length $fname] < 1 } {
	    return 0
	}
	
	if { [ file exists $fname ]  == 0 } {
	    return 0
	}
	
	set element [ vtkXMLDataElement New ]
	$element SetAttribute "studyid" "__none__"
	$element SetAttribute "array_index" 1
	$element SetAttribute "array_dimension" 1
	$element SetAttribute "slice_no" 1
	$element SetAttribute "slices" 1
	$element SetAttribute "matrix" "0"
	
	set fileid [open $fname r ]
	set foundend 0
	while { [ gets $fileid line ] >=0 && $foundend ==0 } {
	    if { [ string length $line ] == 1 } {
		set foundend 1
	    } else {
		set index [string first "\#" $line]
		if { $index != 0 } {
		    set index [string first "=" $line]
		    set len   [string length $line]
		    set key   [string trim   [string range $line 0 [expr $index - 1]]]
		    set value [string trim [string range $line [expr $index +1] [expr $len -1]]]
		    
		    regsub -all " +" $key " " key
		    regsub -all "\\\[" $key "" key
		    regsub -all "\\\]" $key "" key
		    regsub -all "\\\*" $key "" key
		    
		    regsub -all "," $value " " value
		    regsub -all "\{" $value "" value
		    regsub -all "\}" $value "" value
		    regsub -all "\\\;" $value "" value
		    regsub -all " +" $value " " value
		    regsub -all "\"" $value "" value
		    
		    set key2 [ lindex [  split $key " "   ]  1 ]
		    
		    $element SetAttribute $key2 $value
		}
	    }
	}
	close $fileid
	
	set fz [ file size $fname ]
	set val [ $element GetAttribute "matrix" ]
	
	set n 1
	for { set i 0 } { $i < [ llength $val ] } { incr i } {
	    set n [ expr $n * [ lindex $val $i ] ]
	}
	
	set bits [ expr [ $element GetAttribute "bits" ] / 8 ]
	
	$element SetAttribute bis_HeaderSize [ expr $fz - $n*$bits ]
	$element SetAttribute bis_OriginalFileName $fname
	
	set mat [ $element GetAttribute "matrix" ]
	if { [ llength $mat  ] < 3 } {
	    lappend mat 1
	}
	set fov  [ $element GetAttribute "roi" ]
	set units [ $element GetAttribute "abscissa" ]
	if { $units == "" } {
	    set units "mm mm mm"
	}

	for { set i 0 } { $i <=2 } { incr i } {
	    set spa($i) [ expr [ lindex $fov $i ]/ (0.000+ [ lindex $mat $i ] ) ]
	    set ut [ lindex $units $i ]
	    if { $ut == "cm" } {
		set spa($i) [ expr $spa($i) * 10.0 ]
	    }
	    set dim($i) [ lindex $mat $i ]
	    $element SetAttribute "bis_Dimension$i" $dim($i)
	    $element SetAttribute "bis_Spacing$i"   $spa($i)
	}

	set orient [ $element GetAttribute orientation ]
	for { set i 0 } { $i < [ llength $orient ] } { incr i } {
	    $element SetAttribute "bis_Orient$i" [ lindex $orient $i ]
	}

	return $element
	
    }
    
    proc PrintHeaderList { element } {
	
	set n [ $element GetNumberOfAttributes ]
	for { set  i 0 } { $i < $n } { incr i } {
	    set a [ $element GetAttributeName $i ]
	    set b [ $element GetAttributeValue $i ]
	    puts stdout "$a-->$b"
	}
    }
    
    proc GetVarianScaleFactor { img } {

	set r [ [ [ $img GetPointData ] GetScalars ] GetRange ]
	set dt [ $img GetScalarType ]
	if { $dt !=11 && $dt!=10 } {
	    #puts stdout "dt=$dt"
	    return 1.0
	}
	
	set r1 [ lindex $r 1 ]
	set r0 [ lindex $r 0 ]
	#	puts stdout "R1=$r1, ro=$r0"
	if {  ($r1 > $r0 ) && [ expr ($r1 - $r0) ] < 1.0 } {
	    set vl 10000.0
	    return $vl
	} 
	return 1.0
    }

    proc ReadVarianImage { element { parobj 0 } } {
	
	set hd [ $element GetAttribute "bis_HeaderSize" ]
	set bits [ $element GetAttribute "bits" ]

	for { set i 0 } { $i <=2 } { incr i } {
	    set spa($i) [ $element GetAttribute bis_Spacing$i ]
	    set dim($i) [ $element GetAttribute bis_Dimension$i ]
	}


	set fname [ $element GetAttribute bis_OriginalFileName ]
	set anar [ vtkpxAnalyzeImageSourceOld New ]
	
	$anar SetVoxelDimensions $spa(0) $spa(1) $spa(2)
	$anar SetHeaderInfo $dim(0) $dim(1) $dim(2) 1 0 [ expr $bits / 8 ]
	$anar SetHeaderSize $hd
	$anar SetFilePrefix $fname
	if { $parobj !=0 } { $parobj SetFilterCallbacks $anar "Reading Varian Image" }
	$anar Update


	set img [ vtkImageData New ]

	set vl [ GetVarianScaleFactor [ $anar GetOutput ] ]
	if { $vl > 1.0 } {
	    puts stdout "Scaling Varian image by $vl"
	    set shift [ vtkImageShiftScale New ]
	    $shift SetInput [ $anar GetOutput ]
	    $shift SetScale $vl
	    $shift SetShift 0.0
	    $shift Update
	    $img ShallowCopy [ $shift GetOutput ]
	    $shift Delete
	} else {
	    $img ShallowCopy [ $anar GetOutput ]
	}
	$anar Delete
	return $img
    }
    
    proc WriteNIIImage { img outname } {

	set anaw [ vtkpxAnalyzeImageWriter New ]
	$anaw SetInput $img
	$anaw Save $outname 
	$anaw Delete
    }


    proc Test { argv } {
	set fname [ lindex $argv 0 ]
	
	set element [ ReadVarianHeader $fname ]
	if { $element ==0 } {
	    exit
	}
	

	
	if { [ llength $argv ] > 1 } {
	    set outname [ lindex $argv 1 ]
	} else {
	    set outname "[ file rootname $fname].nii.gz"
	}
	
	set img [ ReadImage $element ]
		PrintHeaderList $element
	#	WriteImage $img $outname 
	$element Delete
	$img Delete
    }
}

