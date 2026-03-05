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

package provide bis_smoothimage 1.0
package require bis_imagetoimagealgorithm 1.0


itcl::class bis_smoothimage {

    inherit bis_imagetoimagealgorithm

     constructor { } {	 $this Initialize  }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Smooth Image" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_smoothimage::Initialize { } {

    PrintDebug "bis_smoothimage::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ blursigma "kernel size [mm/voxel] of FWHM filter size" "Filter Size"  { real triplescale 100 }    2.0 { 0.0 20.0 }  0 }
	{ unit      "kernel size unit mm or voxels " "Units" { listofvalues default }  mm { mm voxels }   1}
	{ radius    "radius factor of the gaussian in voxel units " "Filter Radius" real  1.5   { 0.0 5.0 }  -1 }
	{ dimension  "2 or 3 to to do smoothing in 2D or 3D" "Dimensionality"  { listofvalues radiobuttons }    3 { 2  3 }  -999 }
    }


    set defaultsuffix { "_sm" }
    
    set scriptname bis_smoothimage
    set completionstatus "Done"

    #
    #document
    #
    
    set description "Smoothes an image with a specific gaussian kernel."
    set description2 "Smoothing kernel size blursigma (in mm by default ) represents the FWHM filter size."
    set backwardcompatibility "Reimplemented from pxmat_smoothimage.tcl. unit and radius options are  added. Multiple image processing eliminated,which will be recovered upon request. "

    $this InitializeImageToImageAlgorithm
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_smoothimage::Execute {  } {

    PrintDebug "bis_smoothimage::Execute"

    set blursigma   [ $OptionsArray(blursigma) GetValue ]
    set unit        [ $OptionsArray(unit)      GetValue ]
    set radius      [ $OptionsArray(radius)    GetValue ]
    set dimension   [ $OptionsArray(dimension)    GetValue ]
    set image_in    [ $this GetInput ]

    set spacing [[ $image_in GetImage ] GetSpacing ]

    if { $unit == "mm"} {
	for { set j 0 } { $j <=2 } { incr j } {
	    set sigma($j) [ expr $blursigma * 0.4247 / [ lindex $spacing $j ]]
#	    puts stdout "Axis = $j Voxels in=$blursigma out=$sigma($j)  (spacing=[lindex $spacing $j ])"
	}
    } else {
	for { set j 0 } { $j <=2 } { incr j } {
	    set sigma($j) [ expr $blursigma * 0.4247 ]
#	    puts stdout "Axis = $j MM in=$blursigma out=$sigma($j)  (spacing=[lindex $spacing $j ])"
	}
    }

    set radiusz $radius
    if { $dimension == 2 } {
	set radiusz 0
	set sigma(2) 0.0
    }


    $this PrintMessage "Smoothing radius = $radius,$radius,$radiusz, sigma = $sigma(0) $sigma(1) $sigma(2)\n"
    set smooth  [ vtkImageGaussianSmooth [ pxvtable::vnewobj ]  ]
    $smooth SetStandardDeviations $sigma(0) $sigma(1) $sigma(2)
    $smooth SetRadiusFactors $radius $radius $radiusz
    $smooth SetInput [ $image_in GetObject ]
    $this SetFilterCallbacks $smooth "Smoothing Image"
    $smooth Update

    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage ShallowCopyImage [ $smooth GetOutput ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]


    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0

    $smooth Delete

    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_smoothimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_smoothimage [pxvtable::vnewobj]]
    $alg MainFunction 
}





