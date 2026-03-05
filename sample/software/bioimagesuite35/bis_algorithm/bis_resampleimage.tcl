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

package require bis_imagetoimagealgorithm 1.0
package provide bis_resampleimage 1.0

#
# resample image
#

itcl::class bis_resampleimage {

    inherit bis_imagetoimagealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Resample Image" }

    #reimplemented from base class 
    public method SetArguments { parameterlist commandline  } 
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_resampleimage::Initialize { } {

    PrintDebug "bis_resampleimage::Initialize" 

    #In case vox2 or vox3 not specified, voxx1 will be used for vox2 and vox3
    set options {
	{ blurmode  "0 or 1 to blur with appropriate FHWM filter" "Blurmode"  boolean    1 { 0  1 }  0 }
	{ vox1      "x voxel size [mm] " "X spacing" real   2.0 { 0.05 80.0 }  1 }
	{ vox2      "y voxel size [mm] " "Y spacing" real   2.0 { 0.05 80.0 }  2 }
	{ vox3      "z voxel size [mm] " "Z spacing" real   2.0 { 0.05 80.0 }  3 }
    }

    set defaultsuffix { "_resampled" }
    
    set scriptname bis_resampleimage
    set completionstatus "Done"
    #
    #document
    #

    
    set description  "Resamples an image to a specific resolution with optional blurring."
    set description2 "Ths output dimensions of the voxels in mm are set using vox1, vox2 and vox3 options.If only vox1 is specified, vox1 will be used for vox2 and vox3, and isotropic image is generated."
    set backwardcompatibility "Reimplemented from pxmat_resampleimage.tcl."
    

    $this InitializeImageToImageAlgorithm

}

# -----------------------------------------------------------------------------------------
# reimplemented
# -----------------------------------------------------------------------------------------
itcl::body bis_resampleimage::SetArguments { parameterlist commandline  } {

    set ret 1
    set ret [ bis_basealgorithm::SetArguments $parameterlist $commandline  ]

    if { $ret ==1 } {
	set tmp -1
	set v1 [$OptionsArray(vox1) GetValue] 
	#In case vox2 or vox3 is not specified, vox1 will be substituted as vox2
	if { [lsearch $parameterlist vox2 ]  < 0 } {
	    PrintDebug "voxel size 2 not specified.voxel size 1  will be substituted"  
	    $OptionsArray(vox2) SetValue $v1 
	}
	if { [lsearch $parameterlist vox3 ]  < 0 } {
	    PrintDebug "voxel size 3 not specified.voxel size 1  will be substituted"  
	    $OptionsArray(vox2) SetValue $v1
	}
    }

    return $ret
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_resampleimage::Execute {  } {

    PrintDebug "bis_resampleimage::Execute"

    set blurmode    [ $OptionsArray(blurmode) GetValue ]
    set spacing(0)  [ $OptionsArray(vox1)     GetValue ]
    set spacing(1)  [ $OptionsArray(vox2)     GetValue  ]
    set spacing(2)  [ $OptionsArray(vox3)     GetValue  ]

    PrintDebug "blurmode = $blurmode, spacing = $spacing(0), $spacing(1), $spacing(2)"

    set image_in    [ $InputsArray(input_image) GetObject ]

    if { $blurmode == 1 } {
	set input_spacing [[ $image_in GetImage ] GetSpacing ]
	for { set j 0 } { $j <=2 } { incr j } {
	    set sigma($j) [ expr $spacing($j) * 0.4247 / [ lindex $input_spacing $j ]]
	} 
	set smooth  [ vtkImageGaussianSmooth [ pxvtable::vnewobj ]  ]
	$smooth SetStandardDeviations $sigma(0) $sigma(1) $sigma(2)
	$smooth SetRadiusFactors 1.5 1.5 1.5
	$smooth SetInput [ $image_in GetObject ]
	$smooth Update

	set image_tmp [ $smooth GetOutput ]

    } else {
	set image_tmp [  $image_in GetObject ]
    }

    PrintDebug "spacing = $spacing(0) $spacing(1) $spacing(2)"

    set resl [ vtkbisImageResample [ pxvtable::vnewobj ]]
    $resl SetAxisOutputSpacing 0 $spacing(0)
    $resl SetAxisOutputSpacing 1 $spacing(1)
    $resl SetAxisOutputSpacing 2 $spacing(2)
    $resl SetInput $image_tmp
    $resl InterpolateOn
    $resl SetDimensionality 3
    $this SetFilterCallbacks $resl "Resampling Image"
    $resl Update
    set image_out [$resl GetOutput ]

    [ $OutputsArray(output_image) GetObject ] ShallowCopyImage $image_out 

    # Output orientation etc. is same as input
    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]

    # Dimensions and Spacings are automatically set.
    set comment [ format "BIS::bis_resampleimage.tcl" ] 
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0


    if { $blurmode == 1 } { $smooth Delete }

    $resl Delete
    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_resampleimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [ bis_resampleimage [pxvtable::vnewobj]]
    $alg MainFunction 
}

