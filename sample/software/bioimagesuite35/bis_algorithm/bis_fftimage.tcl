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

package provide bis_fftimage 1.0

#
# fft image
#

itcl::class bis_fftimage {

    inherit bis_imagetoimagealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Fourier Transform" }

}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_fftimage::Initialize { } {

    PrintDebug "bis_fftimage::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ dimension "dimension of fourier transform operation. The default value is 3. " "dimension"  int   3 { 2 3 }  0 }
  	{ fftoperation "if true, the algorithm will shift the zeroth frequency to the center of the image" "operations"  { boolean checkbutton } 0 { 0 1 } 1 }
    }
    set defaultsuffix { "_fft" }
    
    set completionstatus "Done  --  needs testing"

    set scriptname bis_fftimage


    set description "computes the fourier transformation of an image."
    set description2 "outputs can either of the zero frequency at the center or at the corners depending on options"
    set backwardcompatibility "N/A"
    set authors "hirohito.okuda@yale.edu.,"

    $this InitializeImageToImageAlgorithm

}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_fftimage::Execute {  } {

    PrintDebug "bis_fftimage::Execute"

    set dimension   [ $OptionsArray(dimension)    GetValue  ]
    set image_in    [ $InputsArray(input_image)   GetObject ]

   
    #vtkImageFFT
    set fft [vtkImageFFT [pxvtable::vnewobj]] 
    set callback "FFT Transforming Image"

    $fft SetDimensionality $dimension
    $fft SetInput [$image_in GetObject]
    $this SetFilterCallbacks $fft $callback
    $fft Update
    set image_out [ $fft GetOutput ]

    if { [ $OptionsArray(fftoperation) GetValue  ] } {
	set cfft [vtkImageFourierCenter [pxvtable::vnewobj]]
	$cfft SetDimensionality $dimension
	$cfft SetInput $image_out
	$cfft Update
	set image_out [ $cfft GetOutput ]
    }

    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage ShallowCopyImage $image_out 
    $outimage CopyImageHeader [ $image_in GetImageHeader ]

    [ $outimage GetImageHeader ] AddComment "[ $this GetCommandLine full ]" 0

    $fft Delete
    if { [ info exist cfft ] } { $cfft Delete }
    return 1
}


# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_fftimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_fftimage [pxvtable::vnewobj]]
    $alg MainFunction 
}

