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

package provide bis_imagemedian 1.0
package require bis_imagetoimagealgorithm 1.0


#
# smooth image
#

itcl::class bis_imagemedian {

    inherit bis_imagetoimagealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Median Filter" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_imagemedian::Initialize { } {

    PrintDebug "bis_imagemedian::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ windowsize "kernel size [voxels]" "Filter Size"  {  listofvalues  } 3 { 3 5 7 9 }  0 }
	{ dimension  "2 or 3 to to do smoothin in 2D or 3D" "Dimensionality"  { listofvalues radiobuttons }    3 { 2  3 }  -999 }

    }

    set defaultsuffix { "_med" }
    
    set scriptname bis_imagemedian
    set completionstatus "Done"

    #
    #document
    #
    
    set description "Smoothes an image using median filtering"
    set description2 " "
    set backwardcompatibility "New"

    $this InitializeImageToImageAlgorithm
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_imagemedian::Execute {  } {

    PrintDebug "bis_imagemedian::Execute"

    set windowsize   [ $OptionsArray(windowsize) GetValue ]
    set dimension   [ $OptionsArray(dimension)    GetValue ]
    set image_in    [ $InputsArray(input_image) GetObject ]

    PrintDebug "windowsize = $windowsize, dimension = $dimension "
    set smooth  [ vtkImageMedian3D [ pxvtable::vnewobj ]  ]
    set r $windowsize

    if { $dimension == 3 } {
	$smooth SetKernelSize $r $r $r
    } else {
	$smooth SetKernelSize $r $r 1
    }
    $smooth SetInput [ $image_in GetImage ]
    $this SetFilterCallbacks $smooth "Median Smoothing Image"
    $smooth Update


    set image_out [ $smooth GetOutput ]

    [ $OutputsArray(output_image) GetObject ] ShallowCopyImage $image_out 

    # Output orientation etc. is same as input
    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]

    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0

    $smooth Delete

    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_imagemedian.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_imagemedian [pxvtable::vnewobj]]
    $alg MainFunction 
}





