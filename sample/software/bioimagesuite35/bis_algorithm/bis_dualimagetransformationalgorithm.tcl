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


package provide bis_dualimagetransformationalgorithm 1.0
package require bis_imagetoimagealgorithm 1.0


#
# This is a base class for things like overlay creator etc
#
#  container == Transform Viewer status
#  secondcontainer == Reference Viewer
#

itcl::class bis_dualimagetransformationalgorithm {

    inherit bis_imagetoimagealgorithm

    constructor { } { }
    public method InitializeDualImageTransformationAlgorithm { }

    # Get Info about Algorithm for use in GUI Container
    public method IsDualImageTransformation { } { return 1 }


    public method UpdateInputsFromContainer { }
    public method UpdateContainerWithOutput { } 

    # Input and Output Methods
    public method GetSecondInput { }
    public method SetSecondInput { img }


    public method GetTransformation { }
    public method SetTransformation { tr }
    public method SetVTKTransformation { tr }

    # Set Filenames etc
    public method  UpdateOutputFilenames { } 
    public method  CheckInputObjects { } 

    # Protected Method 


    # Flag to set whether to ask for transformation from parent
    # or already resliced image ... to replace pxitcloverlaytool.tcl

    public method SetUseReslicedImageAsInput { md } { set use_reslicedimage 1 }

    protected variable use_reslicedimage 0

}


# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_dualimagetransformationalgorithm::InitializeDualImageTransformationAlgorithm { } {


    # This assumes that a derived class has done some work here already

    PrintDebug "bis_dualimagetransformationalgorithm::Initialize" 

    set tmp $inputs
    set inputs { 
	{ second_image   "Overlay Image" pxitclimage  ""  20 }   
	{ transformation "Transformation" pxitcltransform  ""  101 }   
    }
    for { set i 0 } { $i < [ llength $tmp ] } { incr i } {
	lappend inputs [ lindex $tmp $i ]
    }

    if { $defaultsuffix == "" } {
	set defaultsuffix { "_resl" }
    }

    if { $category == "" } {
	set category    "Image Processing Dual"
    }
    if { $authors == "" } {
	set authors "hirohito.okuda@yale.edu, xenophon.papademetris@yale.edu."
    }
    
    $this InitializeImageToImageAlgorithm
}


# ----------------------------------------------------------
#
#  Container Stuff ....
#
# ----------------------------------------------------------

itcl::body bis_dualimagetransformationalgorithm::SetSecondInput  { img } {

    $this SetInputObject second_image $img
}

itcl::body bis_dualimagetransformationalgorithm::GetSecondInput  { } {

    return [ $this GetInputObject second_image ]
}


itcl::body bis_dualimagetransformationalgorithm::SetTransformation  { tr } {

    $this SetInputObject transformation $tr
}

itcl::body bis_dualimagetransformationalgorithm::SetVTKTransformation  { tr } {

    set t [ $this GetInputObject transformation ]
    #    puts stderr "$t copying transformation from $tr ([$tr GetClassName])"
    $t CopyTransformation $tr
    $t configure -filename [ $tr GetClassName ]
}

itcl::body bis_dualimagetransformationalgorithm::GetTransformation { } {

    return [ $this GetInputObject transformation ]
}


# ---------------------------------------------------------------------------------

itcl::body bis_dualimagetransformationalgorithm::UpdateInputsFromContainer { } {

    if { $containerobject == 0 } {    
	return
    }

    $this SetInput          [ $containerobject GetReferenceImage ] 

    if { $use_reslicedimage == 0 } {
	$this SetSecondInput    [ $containerobject GetTargetImage ] 
	$this SetTransformation [ $containerobject GetTransformation ] 
    } else {
	#puts stderr "$this Using Resliced Image"
	$containerobject SetReslicedImageAndTransformation $this
    }
	
	
    $this UpdateOutputFilenames
}

itcl::body bis_dualimagetransformationalgorithm::UpdateContainerWithOutput { } {

    set img  [ $this GetOutput ] 

    PrintDebug "In Update Container With Output $this, $img [ $img GetDescription ]\n"
    
    if { $containerobject == 0 } {
	if { $bis_viewer !=0 } {
	    $bis_viewer SetImage $img
	}  elseif { $vtk_viewer !=0 } {
	    $vtk_viewer SetImage [ $img GetImage ] [ $img GetOrientation ]
	}
    } else {
	PrintDebug "Calling Container ($this, $containerobject) SetResultsFromObject" 
	$containerobject SetResultsFromObject $img $this
    }
}

# --------------------------------------------------------------------------------------------

itcl::body bis_dualimagetransformationalgorithm::UpdateOutputFilenames { } {

    set f1 [ [ $this GetTransformation ] cget -filename ]

    set fname ""
    if { $fname == "" } {
	set f(0) [ $InputsArray(input_image) GetFileName ]
	set f(1) [ $InputsArray(second_image) GetFileName ]

	for { set i 0 } { $i <= 1 } { incr i } {
	    set l($i) [ ::bis_common::SplitFileNameGZ $f($i) ]
	    set f($i) [ file tail [ lindex $l($i) 0 ] ]
	    set ext($i) [ lindex $l($i) 1 ]
	}

	set fname [ file join [ file dirname $f(0) ] "$f(0)_$f(1)" ]
    } 
    
    set outlist [ $this CreateDefaultOutputFileList $fname ]
    set force 0; if { $guimode == "managed" } {	set force 1    }
    catch {     $OutputsArray(output_image) SetFileName "[ lindex $outlist 0 ]$ext(0)" $force }
    return 1

}


itcl::body bis_dualimagetransformationalgorithm::CheckInputObjects { } {


    set image_in    [ $this GetInput ]
    set d [ $image_in GetImageSize ]
    if { $d < 2 } {
	return 0
    }

    set image_in    [ $this GetSecondInput ]
    set n [ lindex [ array names InputsArray ] 1 ]
    set pr [ $InputsArray($n) GetPriority ]
    if { $pr < 100 } {
	set image_in [ $InputsArray($n) GetObject ]
	set d [ $image_in GetImageSize ]
	if { $d < 2 } {
	    return 0
	}
    }

    return 1

}


