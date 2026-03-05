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

package provide bis_imageremoveframes 1.0
package require bis_imagetoimagealgorithm 1.0


#
# smooth image
#

itcl::class bis_imageremoveframes {

    inherit bis_imagetoimagealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    protected method ParseFramesString { val usingseconds tr numframes offset { message "Parsing String"}  { debug 0 }} 
    public method GetGUIName    { } { return "Remove Frames" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_imageremoveframes::Initialize { } {

    PrintDebug "bis_imageremoveframes::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ framelist "List of frame pairs to remove e.g. \"1 2,7 22,40 52\", keep these in quotes. If in frames start at 1, if seconds start at 0.0" "Framelist"  {  string  } "" { "" }  0 }
	{ keep      "If set to 1 then the inverse operation is performed, i.e. the frame pairs are kept" "Keep Frames" boolean 0 {  0 1  } 1 }
	{ unit      "Frames defined in seconds or frames " "Unit" { listofvalues radiobuttons }  frames { frames seconds }   -1}
	{ offset    "Offset from specified values (to be added to the frame list in the same unit as the framelist)" "Offset" real  0.0   { 0.0 10.0 }  -2 }
	{ tr        "Length of each frame in seconds " "Time Dimension (TR)" real  1.0   { 0.01 100.0 }  -3 }
	
    }

    set defaultsuffix { "_crp" }
    
    set scriptname bis_imageremoveframes
    set completionstatus "Testing"

    #
    #document
    #
    
    set description "Extracts frames from a 4D image"
    set description2 " "
    set backwardcompatibility "New"
    set category "Image Processing-4D"

    $this InitializeImageToImageAlgorithm
}

# -----------------------------------------------------------------------------------------
itcl::body bis_imageremoveframes::ParseFramesString { val usingseconds tr numframes offset { message "Parsing String"}  { debug 0 }} {
    
#    puts stdout "Val=$val"

    regsub -all "," $val " " val2
    regsub -all "\"" $val2 " " val2
    regsub -all ";" $val2 " " val2
    regsub -all ":" $val2 " " val2
    regsub -all -- "-" $val2 " " val2
    regsub -all " +" $val2 " " val3
    set val3 [ string trim $val3 ]
    set n [ llength $val3 ]
    set m [ expr 2*(int($n/2)) - $n ]

    set val4 [ lsort -real -increasing $val3 ]

    if { $val4 != $val3 } {
	set errormessage "Error: Bad Definition for $message, frames ($val3) are not specified in ascending order"
	return 0
    }

    if { $debug > 0 } {
	puts stdout "+++++ Cleaned up  val=$val3 , number = $n (isodd = $m)\n"
    }

    if { $m != 0 } {
	set errormessage "Error: Bad Definition for $message, $n total elements ($val3), which is not an even number"
	return 0
    }
    set half [ expr int($n/2) ]
    set arr [ vtkIntArray New ]
    $arr SetNumberOfComponents 2

    set plist ""
    for { set i 0 } { $i < $half } { incr i } {
	
	set ind(0) [ expr $i *2 ]
	set ind(1) [ expr $ind(0) +1 ]
	
	if { $debug > 1 } {
	    puts  -nonewline stdout "\t\t\t Checking Pair [ expr $i+1 ]/$half  $ind(0):$ind(1)"
	}
	
	
	set op(0) -1
	set op(1) -1
	for { set k 0 } { $k <= 1 } { incr k } {
	    set op($k)   [ lindex $val3 $ind($k) ]

	    if { $usingseconds == "seconds"  } {
		set p($k) [ expr int(($op($k)+$offset)/$tr) ]
	    } else {
		set p($k) [ expr int($op($k)+$offset-1) ]
	    }
	    
	    if { $debug > 1 } {
		puts -nonewline stdout "p($k) = $op($k) sec --> $p($k) fr, "
	    }
	    
	    
	    if { $p($k) < 0 || $p($k) >= $numframes } {
		set errormessage "Error: Out of bounds Block Definition for $message, blockpart = [ expr $i+1 ] ( $op(0):$op(1)), numframes= $numframes, allowed range 0: [ expr $numframes-1]"
		$arr Delete
		return 0
	    }
	    
	    set p($k) [ expr $p($k)  ]
	    if { $debug > 1 } {
		puts -nonewline stdout "--> + $offset = $p($k) "
	    }
	}
	if { $debug > 0 } {
	    puts stdout ""
	}
	lappend plist [ list [ expr $p(0)+1 ] [ expr $p(1)+1 ] ]
	$arr InsertNextTuple2 $p(0) $p(1)
    }

    puts stdout "\n Final List plist in frames beginning at 1 = $plist"
    return $arr
    
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_imageremoveframes::Execute {  } {

    set ok [ pxtclvtkpxcontrib::ConditionalLoadLibrary  vtkbisConnectivityTCL vtkbisROICorrelation 0  ]
    if { $ok == 0 } {
	set errormessage "Failed to load library vtkbisConnectivityTCL"
	return 0
    }


    set framelist    [ $OptionsArray(framelist) GetValue ]
    set usingseconds [ $OptionsArray(unit) GetValue ]
    set offset       [ $OptionsArray(offset) GetValue ]
    set tr           [ $OptionsArray(tr) GetValue ]
    set keep         [ $OptionsArray(keep) GetValue ]
    set image_in    [ $InputsArray(input_image) GetObject ]




    set nframes [ [ $image_in GetImage ] GetNumberOfScalarComponents ]
    set arr [ $this ParseFramesString $framelist $usingseconds $tr $nframes $offset "parsing framelist" 0 ]

    if { $arr == 0 } {
	return 0
    }
    
    set tmp [ vtkImageData New ]
    set util [ vtkbisConnectivityUtility New ]


    

    if { $keep > 0 } {
	set ok  [ $util ExtractImageBlocks [ $image_in GetImage ] $tmp $arr ]
    } else {
	set ok  [ $util DiscardImageBlocks [ $image_in GetImage ] $tmp $arr ]
    }
    
    $arr Delete
    $util Delete

    if { $ok ==0 } {
	$tmp Delete
	return 0
    }
    

    [ $OutputsArray(output_image) GetObject ] ShallowCopyImage $tmp
    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]

    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0


    $tmp Delete

    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_imageremoveframes.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_imageremoveframes [pxvtable::vnewobj]]
    $alg MainFunction 
}





