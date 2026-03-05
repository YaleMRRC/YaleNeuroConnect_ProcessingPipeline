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

package provide bis_surfacetosurfacealgorithm 1.0
package require bis_algorithm 1.0


# -----------------------------------------------------------------------------------------
#  Header Stuff
# -----------------------------------------------------------------------------------------
itcl::class bis_surfacetosurfacealgorithm {

    inherit bis_algorithm

    constructor { } { }
    public method InitializeSurfacetoSurfaceAlgorithm { }
    public method Execute { } { puts stderr "Nothing to Do" }


    # Get Info about Algorithm for use in GUI Container
    public method IsSurfacetoSurface { } { return 1 }
    public method SetContainer { cont }  { set containerobject $cont }
    public method GetContainer { }  { return $containerobject }
    public method UpdateInputsFromContainer { }
    public method UpdateContainerWithOutput { } 

    # Input and Output Methods
    public method GetInput { }
    public method GetOutput { }
    public method SetInput { sur }

    # Set Filenames etc
    public method  UpdateOutputFilenames { } 
    public method  CheckInputObjects { } 

    
}


# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_surfacetosurfacealgorithm::InitializeSurfacetoSurfaceAlgorithm { } {


    # This assumes that a derived class has done some work here already

    PrintDebug "bis_surfacetosurfacealgorithm::Initialize" 

    set tmp $inputs
    set inputs { { input_surface "Input Surface" pxitclsurface  "" 2 }    }
    for { set i 0 } { $i < [ llength $tmp ] } { incr i } {
	lappend inputs [ lindex $tmp $i ]
    }
    
    #name,description,type,object,filename(if applicable),priority (optional)
    set tmp $outputs
    
    set outputs { { output_surface "Output Surface"  pxitclsurface  "" 1 }}
    for { set i 0 } { $i < [ llength $tmp ] } { incr i } {
    	lappend outputs [ lindex $tmp $i ]
    }
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    #    lappend options [ list outname  "output filename root" "Output" string ""     { "" }  -1000 ]


    if { $defaultsuffix == "" } {
	set defaultsuffix { "_out" }
    }
    
    

    #
    #document stuff
    #

    if { $category =="" } {
	set category    "Surface Processing"
    }
    
    if { $authors == "" } {
	set authors "hirohito.okuda@yale.edu, xenophon.papademetris@yale.edu."
    }

    $this AddDefaultOptions
}

# ----------------------------------------------------------
#
#  Container Stuff ....
#
# ----------------------------------------------------------
itcl::body bis_surfacetosurfacealgorithm::SetInput  { sur } {

    $this SetInputObject input_surface $sur
}

itcl::body bis_surfacetosurfacealgorithm::GetInput  { } {

    return [ $this GetInputObject input_surface ]
}

itcl::body bis_surfacetosurfacealgorithm::GetOutput { } {

    return [ $this GetOutputObject output_surface ]
}


itcl::body bis_surfacetosurfacealgorithm::UpdateInputsFromContainer { } {


    if { $containerobject == 0 } {	return    }
    $this SetInput [ $containerobject GetSurface ]
    $this UpdateOutputFilenames

}

itcl::body bis_surfacetosurfacealgorithm::UpdateContainerWithOutput { } {

    set sur  [ $this GetOutput ] 


    PrintDebug "In Update Container With Output $this, $sur [ $sur GetDescription ]\n"
    
    if { $containerobject == 0 } {
	if { $bis_viewer !=0 } {
	    $bis_viewer AddOrReplacePolygonalObject $sur
	}
    } else {
	PrintDebug "Calling Container ($this, $containerobject) SetResultsFromObject" 
	$containerobject SetResultsFromObject $sur $this
    }
}

# --------------------------------------------------------------------------------------------

itcl::body bis_surfacetosurfacealgorithm::UpdateOutputFilenames { } {

    set fn [ $InputsArray(input_surface) GetFileName ]
    set outlist [ $this CreateDefaultOutputFileList $fn ]

    set l [ ::bis_common::SplitFileNameGZ $fn ]
    set ext [ lindex $l 1 ]
    set m [ lindex $outlist 0 ]

    set force 0;    if { $guimode == "managed" } {	set force 1    }    
    $OutputsArray(output_surface) SetFileName "${m}${ext}" $force
    return 1

}


itcl::body bis_surfacetosurfacealgorithm::CheckInputObjects { } {


    set surface_in    [ $this GetInput ]
    set d [ [ $surface_in GetSurface ] GetNumberOfPoints ]
    if { $d < 4 } {
	return 0
    }


    return 1

}
