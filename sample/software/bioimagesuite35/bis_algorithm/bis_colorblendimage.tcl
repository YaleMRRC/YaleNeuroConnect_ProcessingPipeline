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

package require bis_dualimagereslicetransformationalgorithm 1.0
package provide bis_colorblendimage 1.0

#
# blend image
#

itcl::class bis_colorblendimage {

    inherit bis_dualimagereslicetransformationalgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Color Blend Image"}
    public method UpdateInputsFromContainer { }

}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_colorblendimage::Initialize { } {

    PrintDebug "bis_colorblendimage::Initialize" 

    set options {
	{ mode "Color Combination to Use" "ColorMode"  listofvalues RedGreen { RedGreen RedBlue GreenBlue Red Green Blue }   0 }
	{ background  "Background Level used to fill voxels outside of mapped area" "Background Value"  real 0.0 { -100000 100000 }  -100 }
    }
    lappend options [ list  default1   "Default Scaling for Image 1" "Default Scale 1"  boolean   1    { 0 1  } 0  ]
    lappend options [ list  minth1 "Image 1: Lower Window" "Image 1 Low"   real    0 { -100000000.0 100000000.0 }  1 ]
    lappend options [ list  maxth1 "Image 1: Upper Window" "Image 1 High"  real    255 { -100000000.0 100000000.0 }  2 ]
    lappend options [ list  default2   "Default Scaling for Image 2" "Default Scale 2"  boolean   1    { 0 1  } 10  ]
    lappend options [ list  minth2 "Image 2: Lower Window" "Image 2 Low"   real    0 { -100000000.0 100000000.0 }  13 ]
    lappend options [ list  maxth2 "Image 2: Upper Window" "Image 2 High"  real    255 { -100000000.0 100000000.0 }  14 ]


	
    set defaultsuffix { "_colorblend" }
    
    set scriptname bis_colorblendimage
    set completionstatus "Done"
    #
    #document
    #

    set category "Image Processing Dual"
    set description "Creates colorblend image"
    set description2 "a useful check of the quality of the transformations"
    set backwardcompatibility "Reimplemented from pxmat_blendimage.tcl."
    set authors "hirohito.okuda@yale.edu, xenophon.papademetris@yale.edu."

    $this InitializeDualImageTransformationAlgorithm
}


# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_colorblendimage::Execute {  } {

    PrintDebug "bis_colorblendimage::Execute"

    set mode [ $OptionsArray(mode) GetValue ]


    set lst [ $this ResliceImageIfNeeded ]
    set reslimage [ lindex $lst 0 ]
    set minval(1) [ $OptionsArray(minth1) GetValue ]
    set minval(2) [ $OptionsArray(minth2) GetValue ]
    set maxval(1) [ $OptionsArray(maxth1) GetValue ]
    set maxval(2) [ $OptionsArray(maxth2) GetValue ]
    set default(1) [ $OptionsArray(default1) GetValue ]
    set default(2) [ $OptionsArray(default2) GetValue ]


    set img(1)  $reslimage 
    set img(2) [  [ $this GetInput ] GetImage ]

    set appnd [ vtkpxAppendComponents [ pxvtable::vnewobj ]]


    if { $mode == "RedGreen" } {
	set index(1) 1
	set index(2) 2
	set index(3) 2
	set null     3
    } elseif { $mode == "RedBlue" } {
	set index(1) 1
	set index(2) 2
	set index(3) 2
	set null     2
    } elseif { $mode == "Red" } {
	set index(1) 1
	set index(2) 1
	set index(3) 1
	set null     { 2 3 }
    } elseif { $mode == "Green" } {
	set index(1) 1
	set index(2) 1
	set index(3) 1
	set null     { 1 3 }
    } elseif { $mode == "Blue" } {
	set index(1) 1
	set index(2) 1
	set index(3) 1
	set null     { 1 2 }
    }  else { 
	set index(1) 1
	set index(2) 1
	set index(3) 2
	set null     1
    }
	



    for { set i 1 } { $i <=3 } { incr i } {

	if { $default($index($i)) > 0 } {
	    set r [ [ [ $img($index($i)) GetPointData ] GetScalars ] GetRange ]
	    set rmin [ lindex $r 0 ]
	    set rmax [ lindex $r 1 ]
	    set $minval($index($i)) $rmin
	    set $maxval($index($i)) $rmax
	} else {
	    set rmin $minval($index($i))
	    set rmax $maxval($index($i))
	}

	#	puts stdout "Using $i range $rmin:$rmax"
	set rmax [ expr $rmax - $rmin ]
	if { $rmax < 1.0 } {
	    set rmax 1.0
	}
	

	set sc [ vtkImageShiftScale New ]
	$sc SetInput $img($index($i))
	$sc SetShift $rmin
	$sc ClampOverflowOn

	if {  [ lsearch -exact $null $i  ] >=0 } {
	    $sc SetScale 0.0
	} else {
	    if { $rmax > 0 }  {
		$sc SetScale [ expr 255.0/$rmax ]
	    } else {
		$sc SetScale 1.0
	    }
	}
	$sc SetOutputScalarTypeToUnsignedChar
	$sc Update

	$appnd AddInput [ $sc GetOutput ]
    }
    $appnd Update

    [ $OutputsArray(output_image) GetObject ] ShallowCopyImage [ $appnd GetOutput ]
    $appnd Delete

    # Output orientation etc. is same as input
    set outimage [ $this GetOutput ] 
    set pimage   [ $this GetSecondInput ] 

    $outimage CopyImageHeader [ $pimage GetImageHeader ]

    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0


    $this DeleteResliceAlgorithmIfNeeded $lst 

    return 1
}

itcl::body bis_colorblendimage::UpdateInputsFromContainer { } {

    set ok [ bis_dualimagetransformationalgorithm::UpdateInputsFromContainer ]

    set imglist(1)  [ $this GetInput ]  
    set imglist(2)  [ $this GetSecondInput ]  

    set r1 0
    set r2 0
    catch { set r1 [  [$img GetImage ]  GetScalarRange ] }
    catch { set r2 [  [$img GetImage ]  GetScalarRange ] }
    if { $r1 ==0 || $r2 ==0 } {
	return
    }

    for { set i 1 } { $i <= 2 } { incr i } {
	set img $imglist($i)
	set r [  [$img GetImage ]  GetScalarRange ]
	set rmin [ lindex $r 0 ]
	set rmax [ expr [ lindex $r 1 ] ]
	if { $rmax == $rmin } {
	    set rmax [ expr $rmin +1 ]
	}

	$OptionsArray(minth$i) SetValueRange [ list $rmin [ expr 2*$rmax ] ]
	$OptionsArray(maxth$i) SetValueRange [ list $rmin [ expr 2*$rmax ] ]
	if { [ $OptionsArray(minth$i) GetValue ] == [ $OptionsArray(minth$i) GetDefaultValue ] } {
	    $OptionsArray(minth$i) SetValue $rmin
	}

	if { [ $OptionsArray(maxth$i) GetValue ] == [ $OptionsArray(maxth$i) GetDefaultValue ] } {
	    $OptionsArray(maxth$i) SetValue $rmax
	}
    }

}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_colorblendimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

   

    set alg [bis_colorblendimage [pxvtable::vnewobj]]
    $alg MainFunction 
}

