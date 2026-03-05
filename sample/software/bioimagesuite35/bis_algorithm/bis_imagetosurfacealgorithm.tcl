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

package provide bis_imagetosurfacealgorithm 1.0
package require bis_surfacetosurfacealgorithm 1.0

# -----------------------------------------------------------------------------------------
#  Header Stuff
# -----------------------------------------------------------------------------------------
itcl::class bis_imagetosurfacealgorithm {

    inherit bis_surfacetosurfacealgorithm

    constructor { } { }
    public method InitializeImageToSurfaceAlgorithm { }
    public method Execute { } { puts stderr "Nothing to Do" }


    # Get Info about Algorithm for use in GUI Container
    public method IsImageToSurface { } { return 1 }
    public method SetContainer { cont }  { set containerobject $cont }
    public method GetContainer { }  { return $containerobject }
    public method UpdateInputsFromContainer { }


    # Input and Output Methods
    public method GetInput { }
    public method GetOutput { }
    public method SetInput { img }

    # Set Filenames etc
    public method  UpdateOutputFilenames { } 
    public method  CheckInputObjects { } 

    # Keep track of GUI elements in standalonemode
    protected method CreateInputGUIInterface { fr }
    public method OutputModified { }
    public method InputModified { } { }

}


# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_imagetosurfacealgorithm::InitializeImageToSurfaceAlgorithm { } {


    # This assumes that a derived class has done some work here already

    PrintDebug "bis_imagetosurfacealgorithm::Initialize" 

    set tmp $inputs
    set inputs { { input_image "Input Image" pxitclimage  ""  }    }
    for { set i 0 } { $i < [ llength $tmp ] } { incr i } {
	lappend inputs [ lindex $tmp $i ]
    }
    
    #name,description,type,object,filename(if applicable),priority (optional)
    set tmp $outputs
    
    set outputs { { output_surface "Output Surface"  pxitclsurface  "" }}
    for { set i 0 } { $i < [ llength $tmp ] } { incr i } {
    	lappend outputs [ lindex $tmp $i ]
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
	set category    "Image to Surface Algorithms"
    }
    
    if { $authors == "" } {
	set authors "alark.joshi@yale.edu, xenophon.papademetris@yale.edu."
    }

    $this AddDefaultOptions
}


# ----------------------------------------------------------
# Standalone GUI Stuff
# ----------------------------------------------------------

itcl::body bis_imagetosurfacealgorithm::CreateInputGUIInterface { fr } {

    return [ ::bis_algorithm::CreateInputGUIInterface $fr ]
}

itcl::body bis_imagetosurfacealgorithm::OutputModified { } {
    
    if { $bis_surfacecontrol != 0 } {
	$bis_surfacecontrol SetResultsFromObject [ $this GetOutput ] $this
    }
}

# ----------------------------------------------------------
#
#  Container Stuff ....
#
# ----------------------------------------------------------

itcl::body bis_imagetosurfacealgorithm::SetInput  { img } {

    $this SetInputObject input_image $img
}

itcl::body bis_imagetosurfacealgorithm::GetInput  { } {

    return [ $this GetInputObject input_image ]
}

itcl::body bis_imagetosurfacealgorithm::GetOutput { } {

    return [ $this GetOutputObject output_surface ]
}


itcl::body bis_imagetosurfacealgorithm::UpdateInputsFromContainer { } {

    if { $containerobject == 0 } {	return    }

    set img [ $this GetInput ]
    $img ShallowCopy [ $containerobject GetImage ] 
    $this UpdateOutputFilenames
}

# --------------------------------------------------------------------------------------------

itcl::body bis_imagetosurfacealgorithm::UpdateOutputFilenames { } {

    set fn [ $InputsArray(input_image) GetFileName ]
    set outlist [ $this CreateDefaultOutputFileList $fn ]

    set l [ ::bis_common::SplitFileNameGZ $fn ]
    set ext ".vtk"
    set m [ lindex $outlist 0 ]

    set force 0;    if { $guimode == "managed" } {	set force 1    }    
    $OutputsArray(output_surface) SetFileName "${m}${ext}" $force
    return 1

}


itcl::body bis_imagetosurfacealgorithm::CheckInputObjects { } {


    set image_in    [ $this GetInput ]
   	set d [ $image_in GetImageSize ]
    if { $d < 27 } {
		return 0
    }


    return 1

}
