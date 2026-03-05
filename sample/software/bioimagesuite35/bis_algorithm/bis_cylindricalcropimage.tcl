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

package provide bis_cylindricalcropimage 1.0

#
# smooth image
#

itcl::class bis_cylindricalcropimage {

    inherit bis_imagetoimagealgorithm

     constructor { } {
	 $this Initialize
     }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "C-Blank Image" }

    # Override these methods
    public method UpdateInputsFromContainer { }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_cylindricalcropimage::Initialize { } {

    PrintDebug "bis_cylindricalcropimage::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ centerx   "Cylinder Center X-coordinate (voxels)" "Center X"  { integer default }    0 { 0 1000 }  0 }
	{ centery   "Cylinder Center Y-coordinate (voxels)" "Center Y"  { integer default }    0 { 0 1000 }  0 }
	{ radius    "Cylinder Radius (voxels)" "Radius"  { integer default }    20 { 0 1000 }  0 }
    }

    set defaultsuffix { "_ccrop" }
    
    set scriptname bis_cylindricalcropimage
    set completionstatus "Done"
    #
    #document
    
    set description "Blanks an image with a specific cylinder."
    set description2 "Values inside the cylinder are preserved, outside are set to 0"
    set backwardcompatibility "Reimplemented from GUI code in pxitclimageutility.tcl.  "
    set authors "xenophon.papademetris@yale.edu."

    $this InitializeImageToImageAlgorithm
}

itcl::body bis_cylindricalcropimage::UpdateInputsFromContainer { } {

    bis_imagetoimagealgorithm::UpdateInputsFromContainer 

    # This happens when image has changed 
    set currentimage  [ $InputsArray(input_image) GetObject ]


    scan [ [ $currentimage GetImage ] GetDimensions ] "%d %d %d" dim(0) dim(1) dim(2)

    $OptionsArray(centerx) SetValueRange [ list 1  [ expr $dim(0) -2 ] ]
    $OptionsArray(centerx) SetValue  [ expr int($dim(0) /2) ]
    $OptionsArray(centery) SetValueRange [ list 1  [ expr $dim(1) -2 ] ]
    $OptionsArray(centery) SetValue  [ expr int($dim(1) /2) ]
}


# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_cylindricalcropimage::Execute {  } {

    PrintDebug "bis_cylindricalcropimage::Execute"

    set cx   [ $OptionsArray(centerx) GetValue ]
    set cy   [ $OptionsArray(centery) GetValue ]
    set r   [ $OptionsArray(radius) GetValue ]

    set currentimage  [ $InputsArray(input_image) GetObject ]
    set currentresults [ $OutputsArray(output_image) GetObject ]


    set crop [ vtkpxImageCylindricalCrop [ pxvtable::vnewobj ] ]
    $crop SetInput  [ $currentimage GetImage ]
    $crop SetCenter $cx $cy 0
    $crop SetRadius $r
    SetFilterCallbacks $crop "Cylindrical Blanking Image"
    $crop Update

	
    $currentresults CopyImageHeader [ $currentimage GetImageHeader ]
    $currentresults ShallowCopyImage [ $crop GetOutput ] 
    [ $currentresults GetImageHeader ] AddComment [ $this GetCommandLine full ]  0
    
    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_cylindricalcropimage.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_cylindricalcropimage [pxvtable::vnewobj]]
    $alg MainFunction 
}





