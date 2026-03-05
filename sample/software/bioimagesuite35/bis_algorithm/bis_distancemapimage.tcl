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

package provide bis_distancemapimage 1.0
package require bis_imagetoimagealgorithm 1.0


itcl::class bis_distancemapimage {

    inherit bis_imagetoimagealgorithm

     constructor { } {	 $this Initialize  }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Signed DistanceMap" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_distancemapimage::Initialize { } {

    PrintDebug "bis_distancemapimage::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{  minth "Lower Threshold value" "Low Threshold"   real  1.0 { -100000000.0 100000000.0 }  1 }
	{  maxth "Upper Threshold value" "High Threshold"  real 200000.0 { -100000000.0 100000000.0 }  -22 }
	{  invalue "In Threshold value" "In Value"  real  3000.0 { -100000000.0 100000000.0 } 3 }
	{  outvalue "Out Threshold value" "Out Value"  real 0.0 { -100000000.0 100000000.0 }  -21 }
	{  radius  "Radius used in dilation filter " "Radius"  integer 1 { 0 10 }  2 }
    }

    set defaultsuffix { "_dmap" }
    
    set scriptname bis_distancemapimage
    set completionstatus "Done"

    #
    #document
    #
    
    set description "Create a distance map from a binarized image"
    set description2 ""
    set backwardcompatibility "None"

    $this InitializeImageToImageAlgorithm
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_distancemapimage::Execute {  } {

    PrintDebug "bis_distancemapimage::Execute"

    set minth   [ $OptionsArray(minth) GetValue ]
    set maxth   [ $OptionsArray(maxth) GetValue ]
    set invalue   [ $OptionsArray(invalue) GetValue ]
    set outvalue   [ $OptionsArray(outvalue) GetValue ]
    set radius      [ $OptionsArray(radius)    GetValue ]

    set image_in [ $this GetInput ]

    set distancemap  [ vtkjwsSignedDanielssonDistanceMapImageFilter New ]
    $distancemap SetLowerThreshold $minth
    $distancemap SetUpperThreshold $maxth
    $distancemap SetInValue $invalue
    $distancemap SetOutValue $outvalue
    $distancemap SetRadius $radius
    $distancemap SetInput [ $image_in GetImage ]
    $this SetFilterCallbacks $distancemap "Computing Distancemap from Image"
    $distancemap Update

    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage ShallowCopyImage [ $distancemap GetOutput ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]

    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0

    $distancemap Delete

    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_distancemapimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_distancemapimage [pxvtable::vnewobj]]
    $alg MainFunction 
}





