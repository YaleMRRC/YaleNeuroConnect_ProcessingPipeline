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

package provide bis_imageandsurfacetosurfacealgorithm 1.0
package require bis_surfacetosurfacealgorithm 1.0

# -----------------------------------------------------------------------------------------
#  Header Stuff
# -----------------------------------------------------------------------------------------
itcl::class bis_imageandsurfacetosurfacealgorithm {

    inherit bis_surfacetosurfacealgorithm

    constructor { } { }
    public method InitializeImageandSurfacetoSurfaceAlgorithm { }
    public method Execute { } { puts stderr "Nothing to Do" }


    # Get Info about Algorithm for use in GUI Container
    public method SetContainer { cont }  { set containerobject $cont }
    public method GetContainer { }  { return $containerobject }
    public method UpdateInputsFromContainer { }

    # Input and Output Methods
    public method GetInputImage { }
    public method GetInputSurface { }
    public method GetOutput { }
    public method SetInput { img sur}

    # Set Filenames etc
    public method  UpdateOutputFilenames { } 
    public method  CheckInputObjects { } 

    # GUI Extra Stuff
    public method InputModified { }
}


# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_imageandsurfacetosurfacealgorithm::InitializeImageandSurfacetoSurfaceAlgorithm { } {

    # This assumes that a derived class has done some work here already

    PrintDebug "bis_imageandsurfacetosurfacealgorithm::Initialize" 

    set tmp $inputs
    set inputs { { input_image "Input Image" pxitclimage  "" 3 } }
    for { set i 0 } { $i < [ llength $tmp ] } { incr i } {
	lappend inputs [ lindex $tmp $i ]
    }

    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    #    lappend options [ list outname  "output filename root" "Output" string ""     { "" }  -1000 ]


    if { $defaultsuffix == "" } {
	set defaultsuffix { "_surfout" }
    }
    
    
    #
    #document stuff
    #

    if { $category =="" } {
	set category    "Image+Surface Processing"
    }
    
    if { $authors == "" } {
	set authors "alark.joshi@yale.edu, xenophon.papademetris@yale.edu."
    }

    $this InitializeSurfacetoSurfaceAlgorithm

}

# ----------------------------------------------------------
# GUI Stuff
# ----------------------------------------------------------
itcl::body bis_imageandsurfacetosurfacealgorithm::InputModified { } {
    
    if { $bis_surfacecontrol != 0 } {
	$bis_surfacecontrol SetSurfaceFromObject [ $this GetInput ] $this
    }
}

# ----------------------------------------------------------
#
#  Container Stuff ....
#
# ----------------------------------------------------------

itcl::body bis_imageandsurfacetosurfacealgorithm::SetInput  { img sur } {

    $this SetInputObject input_image   $img
    $this SetInputObject input_surface $sur

}

itcl::body bis_imageandsurfacetosurfacealgorithm::GetInputImage  { } {

    return [ $this GetInputObject input_image ]
}

itcl::body bis_imageandsurfacetosurfacealgorithm::GetInputSurface  { } {

    return [ $this GetInputObject input_surface ]
}


itcl::body bis_imageandsurfacetosurfacealgorithm::GetOutput { } {

    return [ $this GetOutputObject output_surface ]
}

# -----------------------------------------------------------------------------------------
itcl::body bis_imageandsurfacetosurfacealgorithm::UpdateInputsFromContainer { } {

    if { $containerobject == 0 } {	return    }

    set img [ $this GetInputImage ]
    $img ShallowCopy [ $containerobject GetImage ] 

    set sur [ $this GetInputSurface ]
    $sur ShallowCopy [ $containerobject GetSurface ] 

    $this UpdateOutputFilenames
}



# --------------------------------------------------------------------------------------------

itcl::body bis_imageandsurfacetosurfacealgorithm::UpdateOutputFilenames { } {

    set f1 [ [ $this GetOutput ] cget -filename ]
    set fn [ $InputsArray(input_image) GetFileName ]
    set outlist [ $this CreateDefaultOutputFileList $fn ]

    set l [ ::bis_common::SplitFileNameGZ $fn ]
    set ext ".vtk"
    set m [ lindex $outlist 0 ]

    set force 0;    if { $guimode == "managed" } {	set force 1    }    

    $OutputsArray(output_surface) SetFileName "${m}${ext}" $force
    return 1

}


itcl::body bis_imageandsurfacetosurfacealgorithm::CheckInputObjects { } {

    # Checking Input Image 
    set image_in    [ $this GetInputImage ]
   	set d [ $image_in GetImageSize ]
    if { $d < 27 } {
		return 0
    }

    ## Checking for input surface
   set surface_in    [ $this GetInputSurface ]
    set d [ [ $surface_in GetSurface ] GetNumberOfPoints ]
    if { $d < 4 } {
	return 0
    }

    return 1

}
