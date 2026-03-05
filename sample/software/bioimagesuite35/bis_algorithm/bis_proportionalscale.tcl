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
lappend auto_path [ file join [file join [ file dirname [ info script ]] ".." ] base]
lappend auto_path [ file join [file join [ file dirname [ info script ]] ".." ] apps]

package provide bis_proportionalscale     1.0
package require bis_imagetoimagealgorithm 1.0
package require bis_castimage             1.0
package require bis_shiftscaleimage       1.0
package require bis_thresholdimage        1.0

itcl::class bis_proportionalscale {

    inherit bis_imagetoimagealgorithm

     constructor { } {	 $this Initialize  }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Proportional Scale Image" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_proportionalscale::Initialize { } {

    PrintDebug "bis_proportionalscale::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ mean      "The mean to which the image is scaled to"     "image mean" real    50.0 { 0.0 200.0 }  0 }
	{ threshold "Images with be thresholded at threshold*mean" "threshold"  real    0.8  { 0.0 2.0 }    0 }

    }

    set defaultsuffix { "_ps" }
    
    set scriptname bis_proportionalscale
    set completionstatus "Done"

    #
    #document
    #
    
    set description "Proportional scales input images to the mean specified in the options."
    set description2 "sets all voxels of intensity less than threshold*mean to zero"
    set backwardcompatibility ""
    set authors "dustin.scheinost@yale.edu"

    $this InitializeImageToImageAlgorithm
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_proportionalscale::Execute {  } {

    PrintDebug "bis_proportionalscale::Execute"

    set mean      [ $OptionsArray(mean)      GetValue ]
    set threshold [ $OptionsArray(threshold) GetValue ]
    set image_in  [ $this GetInput ]

    set pscale [ vtkdsSpectUtil [ pxvtable::vnewobj ] ]    
    set cast   [ bis_castimage       [ pxvtable::vnewobj ] ] 
    set shift  [ bis_shiftscaleimage [ pxvtable::vnewobj ] ] 
    set thrsh  [ bis_thresholdimage  [ pxvtable::vnewobj ] ] 

    set imgMean [ $pscale imageMean [ $image_in GetObject ] -1 ] 
    set imgMean [ $pscale imageMean [ $image_in GetObject ] [ expr $imgMean/8.0 ] ]

    $cast InitializeFromContainer $this 
    $cast SetInput                $image_in
    $cast SetOptionValue          type float
    $cast Execute

    $shift InitializeFromContainer $this 
    $shift SetInput                [ $cast GetOutput ]
    $shift SetOptionValue          scale [ expr $mean/$imgMean ]
    $shift Execute
    
    $thrsh InitializeFromContainer $this 
    $thrsh SetInput                [ $shift GetOutput ]
    $thrsh SetOptionValue          minth [ expr $mean*$threshold ]
    $thrsh SetOptionValue          maxth 10000000
    $thrsh Execute

    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage ShallowCopyImage [ [ $thrsh GetOutput ] GetObject ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]

    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0

    itcl::delete object $thrsh $shift $cast
    $pscale Delete

    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_proportionalscale.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_proportionalscale [pxvtable::vnewobj]]
    $alg MainFunction 
}





