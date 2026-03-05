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


package provide bis_manualreslice 1.0
package require bis_imagetoimagealgorithm 1.0


#
# reslice image
#

itcl::class bis_manualreslice {

     inherit bis_imagetoimagealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName { } { return "Manual Reslice"}
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_manualreslice::Initialize { } {

    PrintDebug "bis_manualreslice::Initialize" 
        
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
    { rotx    "Custom Rotation of image around X-axis" "Rotation-X"  real 0.0 { -360.0 360.0 } 0 }
    { roty    "Custom Rotation of image around Y-axis" "Rotation-Y"  real 0.0 { -360.0 360.0 } 1 }
    { rotz    "Custom Rotation of image around Z-axis" "Rotation-Z"  real 0.0 { -360.0 360.0 } 2 }
    
	{ interp    "Interpolation Mode that is used when reslicing the image" "Interpolation Mode"  listofvalues Linear { "NearestNeighbor" "Linear" "Cubic" }  3 }
	{ background  "Background Level used to fill voxels outside of mapped area" "Background Value"  real 0.0 { -100000 100000 }  -100 }
	
    }

    set defaultsuffix { "_resl" }
    
    set scriptname bis_manualreslice
    set completionstatus "Done"
    #
    #documents
    #

    set category "Image Processing Dual"
    set description "reslices an image using one or more transformations."
    set description2 ""
    set backwardcompatibility "Reimplemented from pxmat_manualreslice.tcl."
    set authors "hirohito.okuda@yale.edu, xenophon.papademetris@yale.edu."

    $this InitializeImageToImageAlgorithm
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_manualreslice::Execute {  } {

    PrintDebug "bis_manualreslice::Execute"

	set rotx 	   [ $OptionsArray(rotx) GetValue ]
	set roty 	   [ $OptionsArray(roty) GetValue ]
	set rotz 	   [ $OptionsArray(rotz) GetValue ]
	
    set mode       [ $OptionsArray(interp) GetValue ]
    set interp 1
    switch -exact $mode {
	"NearestNeighbor" { set interp 0 }  
	"Cubic" { set interp 3 }
    }

    #vtkobject
    set image_in    [ $this GetInput ]
    set spa [[ $image_in GetImage ] GetSpacing ]
    set dim [[ $image_in GetImage ] GetDimensions ]

    
    for { set i 0 } { $i <= 2 } { incr i } {
		set pos($i) [ expr 0.5*[lindex $dim $i]*[lindex $spa $i ] ]
		set min($i) [ expr -1.0*$pos($i) ]
	}

    set trans [ vtkGeneralTransform [ pxvtable::vnewobj ]]
    $trans Identity
    $trans PostMultiply
    $trans Translate $min(0) $min(1) $min(2)
    $trans RotateX $rotx
    $trans RotateY $roty
    $trans RotateZ $rotz
    $trans Translate $pos(0) $pos(1) $pos(2)

    set resl [  vtkbisImageReslice [ pxvtable::vnewobj ] ]
    $resl SetInput  [ $image_in GetObject ]
    
    # set resl [ vtkbisImageReslice [ pxvtable::vnewobj ]]
    #$resl SetInput             $image_in
    #$resl SetInformationInput  [ $image_in GetObject ]
    $resl SetInterpolationMode $interp
    $resl SetBackgroundLevel   [ $OptionsArray(background) GetValue ]
    $resl OptimizationOff
    $resl SetResliceTransform $trans
    $resl AutoCropOutputOn
    $resl Update
    

    # set image_out [$resl GetOutput ]
    #[ $OutputsArray(output_image) GetObject ] ShallowCopyImage $image_out 

	set outimage [ $OutputsArray(output_image) GetObject ]
	$outimage ShallowCopyImage [ $resl GetOutput ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]
    
        
    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0

    $trans Delete
    $resl Delete

#    puts stderr "\t\t\t Reslicing Done\n"

    return 1
}


# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_manualreslice.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_manualreslice [pxvtable::vnewobj]]
    $alg MainFunction 
}

