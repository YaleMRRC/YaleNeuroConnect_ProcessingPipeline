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

package provide bis_guirpmcontainer 1.0
package require bis_guicontainer 1.0


itcl::class bis_guirpmcontainer {

    inherit bis_guicontainer

    constructor { } { $this InitializeGUIRpmContainer  }

    # Create Input/Output GUI Controls for Objects in standalone mode
    protected method InitializeGUIRpmContainer { }
    public method DelayedCreateGUI { }


    # Methods for chaining into other tools
    public method SetTransformationFromObject { tr obj } 

    # Update Stuff
    public method UpdateContainedAlgorithms { }


    # transform/weight surface control
    public method CreateInputOutputControl { nt }
    public method InputsModified { args }

    # Update Stuff
    public method HasRPMGUI { } { return 1 }
    public method UpdateRPMViewer { visib alg currentregistration } 

    # methods for getting stuff
    public method GetTransformation { }
    public method GetOutputTransformation { } { return [ $this GetTransformation ] }
    public method GetReferenceSurface { }
    public method GetTransformSurface { }
    public method GetOutputSurface { }
    public method GetInitialTransformation { }
    public method UpdateInputTransformation { args } 

    # Other Stuff STORAGE
    #protected variable transformation_control 0
}

#------------------------------------------------------------------------------------------
itcl::body bis_guirpmcontainer::InitializeGUIRpmContainer { } {

    set inputs { 
	{ reference_surface   "Reference Surface"   pxitclsurface  ""  }
	{ transform_surface    "Target    Surface"   pxitclsurface  ""  }
	{ initial_transform "Initial Transformation" pxitcltransform  "" 100  }
    }

    set outputs { 
	{ output_transform "Output Transformation"  pxitcltransform  "" }
	{ output_surface   "Transformed Surface" pxitclsurface  ""  200 }
    }


    
    set scriptname "bis_guirpmcontainer"
    set category "Graphical-User-Interface-Module"
    set description " Utility Class for containing a variety of registration and image merge algorithms."
    set backwardcompatibility "See pxitcloverlaytool.tcl"
    set authors "xenophon.papademetris@yale.edu."

    set completionstatus "ongoing  -- Xenios needs to revisit"

    # does not contain extract surface and mapfunctional
    set componentnamelist [ list  bis_linearpointregister bis_nonlinearpointregister ]

    $this AddDefaultOptions

    set extratablist { "Transformations" "Weight Images" "Image Compare" "4D Image Compare" }

}


#------------------------------------------------------------------------------------------
::itcl::body bis_guirpmcontainer::DelayedCreateGUI { } {

    if { $fullyinitialized == 1 } {
	return 1
    }

    if { $basewidget == 0 } {
	return 0
    }

    set tp [ toplevel $basewidget ];  wm withdraw $tp
    eval "wm protocol $basewidget WM_DELETE_WINDOW { wm withdraw $basewidget  }"

    set basewidget $tp

    set buttonbar [ frame $basewidget.bt ]
    set bbt [ frame $basewidget.bt2 -bg black -height 5 ]
    
    pack $buttonbar $bbt -side bottom -expand false -fill x 
    
    $this CreateProgressBar $buttonbar

    eval "button $buttonbar.close   -text Close -command { wm withdraw $basewidget }"
    pack $buttonbar.close -side right


    set main [ frame $basewidget.top ]
    pack $main -side top -expand true -fill both

    set nt [ $this CreateMainNotebook  $main.nt ]
    set w  [ frame $main.middle -width 2 -bg black ]
    set vr [ frame $main.right ]
    pack $nt $w -side left -expand false -fill y
    pack $vr -side right -expand true -fill both


    set maintabnotebook $nt

    set bis_viewer [ [ bis_viewer \#auto ] GetThisPointer ]
    $bis_viewer CreateGUI $vr
    set vtk_viewer [ $bis_viewer GetViewer ]
    #    $bis_viewer AddOrReplacePolygonalObject [ $this GetReferenceSurface ]  1 { color "1.0 0.0 0.0" opacity 0.5 visible 0} 
    #    $bis_viewer AddOrReplacePolygonalObject [ $this GetTransformSurface ]  1 { color "0.0 1.0 0.0" opacity 1.0 visible 0} 
    #    $bis_viewer AddOrReplacePolygonalObject [ $this GetOutputSurface ]  1 { color "1.0 1.0 0.0" opacity 0.5 visible 0 dispmode Wireframe }  

    $this CreateInputOutputControl $nt
    $this CreateContainedAlgorithmsGUIs $nt


    $nt view "Input/Output"

    $this SetTitle "BioImageSuite::Point-Based Registration Utility v2 (bis_algo)"
    set fullyinitialized 1
    return 1
}


# ------------------------------------------------------------------------------------
# Transformation Interface
# ------------------------------------------------------------------------------------
::itcl::body bis_guirpmcontainer::UpdateContainedAlgorithms {  } { 
    set l [ llength $componentlist ]
    for { set i 0 } { $i < $l } { incr i } {
	set alg [ lindex $componentlist $i ]
	$alg UpdateInputsFromContainer
    }
}


#------------------------------------------------------------------------------------------

itcl::body bis_guirpmcontainer::InputsModified { args  } {


    set ind [ lindex $args 0 ]
    if { $ind == 0 || $ind ==1 || $ind ==4 } {
	$bis_viewer AddOrReplacePolygonalObject [ $this GetReferenceSurface ]  1 { color "1.0 0.0 0.0" opacity 0.5 visible 1} 
	$bis_viewer AddOrReplacePolygonalObject [ $this GetTransformSurface ]  1 { color "0.0 1.0 0.0" opacity 1.0 visible 1} 
	$bis_viewer AddOrReplacePolygonalObject [ $this GetOutputSurface ]  1 { color "1.0 1.0 0.0" opacity 0.5 visible 0 dispmode Wireframe }  
    }
    $this UpdateContainedAlgorithms

}

# -----------------------------------------------------------------------------------------

itcl::body bis_guirpmcontainer::CreateInputOutputControl { nt } {

    set w2 [ $nt add -label "Input/Output" ]
    set slist [ list $InputsArray(reference_surface) $InputsArray(transform_surface) $InputsArray(initial_transform) $OutputsArray(output_transform) $OutputsArray(output_surface) ]
    for { set i 0 } { $i < [ llength $slist ] } { incr i } {
	set obj [ lindex $slist $i ]
	$obj CreateObjectGUI $w2.$i [ expr ($i >2) ] "" $this
	$obj SetUpdateCallback  "$this InputsModified $i"
	pack $w2.$i -side top -expand false -fill x -pady 5 -padx 5
    }
    $this UpdateContainedAlgorithms
}


# -------------------------------------------------------------------------------
::itcl::body bis_guirpmcontainer::GetTransformation { }  {
    
    return [ $this GetOutputObject output_transform ]
}

::itcl::body bis_guirpmcontainer::GetReferenceSurface { }  {
    
    return [ $this GetInputObject reference_surface ]
}

::itcl::body bis_guirpmcontainer::GetTransformSurface { }  {
    
    return [ $this GetInputObject transform_surface ]
}

::itcl::body bis_guirpmcontainer::GetInitialTransformation { }  {
    
    return [ $this GetInputObject initial_transform ]
}

itcl::body bis_guirpmcontainer::GetOutputSurface  { } {
    return [ $this GetOutputObject output_surface ]
}


# -------------------------------------------------------------------------------

::itcl::body bis_guirpmcontainer::UpdateInputTransformation { args }  {
    [ $this GetOutputObject initial_transform ] Copy $tr [ $containerobject GetTransformation ]
    [ $OutputsArray(initial_transform) GetObjectGUI ] Update
    $this InputsModified
}


# -------------------------------------------------------------------------------

itcl::body bis_guirpmcontainer::SetTransformationFromObject { tr obj } {

    [ $this GetOutputObject output_transform ] Copy $tr
    [ $OutputsArray(output_transform) GetObjectGUI ] Update
    if { $containerobject !=0 } {
	$containerobject SetTransformationFromObject $tr $obj 
    }
    return 1
}

# --------------------------------------------------------------------------------------
itcl::body bis_guirpmcontainer::UpdateRPMViewer { visib alg currentreg } {

    if {  $currentreg == 0 || $bis_viewer == 0 } {
	return 0
    }
    set dat_trn  [ $currentreg GetCurrentTransformation ]
    set filt2m [ vtkTransformPolyDataFilter [ pxvtable::vnewobj ] ]
    $filt2m SetInput [ [ $this GetReferenceSurface ] GetSurface ]
    $filt2m SetTransform $dat_trn
    $filt2m Update
    
    [ $this GetOutputSurface ] ShallowCopySurface [ $filt2m GetOutput ]
    $filt2m Delete 
    
    $bis_viewer UpdatePolygonalObject [ $this GetReferenceSurface ]   {  visible 0 } 0
    $bis_viewer UpdatePolygonalObject [ $this GetTransformSurface ]   {  opacity 1.0 visible 1 } 0
    $bis_viewer UpdatePolygonalObject [ $this GetOutputSurface ]     { color "1.0 1.0 0.0" opacity 0.5 visible 1 dispmode Wireframe }   1
    return 1
}

# --------------------------------------------------------------------------------------
