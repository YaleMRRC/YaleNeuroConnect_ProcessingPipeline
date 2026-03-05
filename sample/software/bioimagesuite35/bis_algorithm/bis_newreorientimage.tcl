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
package provide bis_newreorientimage 1.0

#
# newreorient image
#

itcl::class bis_newreorientimage {

    inherit bis_imagetoimagealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "ReOrient Image" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_newreorientimage::Initialize { } {

    PrintDebug "bis_newreorientimage::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ orientation "orientation of output image eiter axial LPS or axial RAS, coronal LIP or RSA or saggital PSR or ASR" "Orientation"  { listofvalues  } LPS { LPS RAS LIP RSA PSR ASR }  0 }
    }

    set defaultsuffix { "" }
    
    set scriptname bis_newreorientimage
    set completionstatus "Done -- needs testing"
    #
    #document
    #
    
    set description "newreorients an image to a given orientation."
    set description2 " Output orientation is one of default six including LPS or RAS. The input orientation is detected automatically. This tool does not reslice oblique images, it simply permutes/flips the axis only."
    set backwardcompatibility ""
    

    $this InitializeImageToImageAlgorithm

}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_newreorientimage::Execute {  } {

    PrintDebug "bis_newreorientimage::Execute"

    set out   [ $OptionsArray(orientation) GetValue ]
    set image_in          [ $InputsArray(input_image) GetObject ]
    set orientation_in    [ $image_in GetOrientation ]


    #vtk object
    set vtk_image_in [ $image_in GetObject ]
    set header [ $image_in GetImageHeader ]
    set outimage [ $OutputsArray(output_image) GetObject ]

    set f [ vtkbisImageReOrient New ]
    $f SetInput $vtk_image_in
    $f SetInputImageHeader $header
    #    $f SetOutputOrientationToLPS
    $f SetOutputOrientationTo$out
    $f Update

    # Output orientation etc. is same as input
    $outimage CopyImageHeader  [ $f GetOutputImageHeader ]
    $outimage ShallowCopyImage [ $f GetOutput ] 
    [ $outimage GetImageHeader ] AddComment "[ $this GetCommandLine full ]" 0

    $f Delete
    
    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_newreorientimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_newreorientimage [pxvtable::vnewobj]]
    $alg MainFunction 
}

