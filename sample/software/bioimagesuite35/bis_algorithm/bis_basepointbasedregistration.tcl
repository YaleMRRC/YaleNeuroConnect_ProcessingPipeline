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

package provide bis_basepointbasedregistration 1.0
package require bis_algorithm 1.0
package require bis_common 1.0
package require bis_pointbasedregistrationviewer 1.0


itcl::class bis_basepointbasedregistration {

    inherit bis_algorithm

    constructor { } { }
    public method InitializeBasePointBasedRegistration { }

    # Get Info about Algorithm for use in GUI Container
    public method IsImageToImage { } { return 0 }
    public method SetContainer { cont }  { set containerobject $cont }
    public method GetContainer { }  { return $containerobject }
    public method UpdateInputsFromContainer { }
    public method UpdateContainerWithOutput { } 
    public method ProgressCallback   { filter lab }  

    # Input and Output Methods
    public method GetReferenceSurface { }
    public method GetTransformSurface { }
    public method GetOutputTransformation { }
    public method GetOutputSurface { }
    public method GetInitialTransformation { }
    public method SetReferenceSurface { sur }
    public method SetTransformSurface { sur }
    public method SetInitialTransformation { xform }

    # Set Filenames etc
    public method    UpdateOutputFilenames { } 
    public method    CheckInputObjects { } 
    protected method SetCommonPointBasedRegistrationOptions { regobj }

    # Generate Resliced Image
    public method CreateWarpedSurface { }

    # Generate Method 
    public method GetExtension { } { return ".matr" }


    # Custom Viewer for RPM
    protected method CreateViewer { fr }
    public method UpdateRPMViewer { visib alg currentregistration }
    public method HasRPMGUI { } { }

    protected variable currentregistration 0
    protected variable registrationviewer  0
}


# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_basepointbasedregistration::InitializeBasePointBasedRegistration { } {


    # This assumes that a derived class has done some work here already

    PrintDebug "bis_basepointbasedregistration::Initialize" 

    set tmp $inputs
    set inputs { 
	{ reference_surface   "Reference Surface" pxitclsurface  ""  0}    
	{ transform_surface   "Transform Surface" pxitclsurface  ""  1}     
	{ initial_transform "Initial Transformation" pxitcltransform  "" 100  }
    }

    for { set i 0 } { $i < [ llength $tmp ] } { incr i } {
	lappend inputs [ lindex $tmp $i ]
    }
    
    #name,description,type,object,filename(if applicable),priority (optional)
    set tmp $outputs
    
    set outputs { 
	{ output_transform "Output Transformation"  pxitcltransform  "" }
	{ output_surface   "Transformed Surface" pxitclsurface  ""  200 }
    }

    for { set i 0 } { $i < [ llength $tmp ] } { incr i } {
    	lappend outputs [ lindex $tmp $i ]
    }
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    #    lappend options [ list outname  "output filename root" "Output" string ""     { "" }  -1000 ]
    lappend options [ list matchmode   "Match Mode either RPM or ICP" "Match Mode" { listofvalues } rpm { rpm icp } 0 ]
    lappend options [ list numpoints     "number of points "                                        "numpoints"      int  800 { 0 10000 }    1 ]
    lappend options [ list tstart "Initial temparature "                                "tstart"         real 5.0  { 0.0 100.0 }  2 ]
    lappend options [ list tstop  "Final temparature "                                  "tend"           real 2.0  { 0.0 100.0}    3 ]
    lappend options [ list useinitial "Use Initial Transformation" "Use Initial Xform"  boolean   0     { 0 1 } 25 ]
    lappend options [ list guiautosave       "AutoSave Result" "Autosave"  boolean  1 { 0 1 }  99 ]

    if { $defaultsuffix == "" } {
	set defaultsuffix { "_xform" }
    }


    set category    "Registration"
    
    if { $authors == "" } {
	set authors "hirohito.okuda@yale.edu, xenophon.papademetris@yale.edu."
    }

    $this AddDefaultOptions
}



# ----------------------------------------------------------
#
#  Input/Output Utility Stuff
#
# ----------------------------------------------------------

itcl::body bis_basepointbasedregistration::SetReferenceSurface  { sur } {
    $this SetInputObject reference_surface $sur
}

itcl::body bis_basepointbasedregistration::SetTransformSurface  { sur } {
    $this SetInputObject transform_surface $sur
}

itcl::body bis_basepointbasedregistration::SetInitialTransformation  { tr } {
    $this SetInputObject initial_transform $tr
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

itcl::body bis_basepointbasedregistration::GetReferenceSurface  { } {
    return [ $this GetInputObject reference_surface ]
}

itcl::body bis_basepointbasedregistration::GetTransformSurface  { } {
    return [ $this GetInputObject transform_surface ]
}

itcl::body bis_basepointbasedregistration::GetOutputTransformation  { } {
    return [ $this GetOutputObject output_transform ]
}

itcl::body bis_basepointbasedregistration::GetOutputSurface  { } {
    return [ $this GetOutputObject output_surface ]
}

itcl::body bis_basepointbasedregistration::GetInitialTransformation  {  } {
    return [ $this GetInputObject initial_transform ]
}

# ------------------------------------------------------------------------------------
#        Container Stuff 
# ------------------------------------------------------------------------------------

itcl::body bis_basepointbasedregistration::ProgressCallback   { filter lab }  {

    if { $containerobject == 0 } {
	if { $currentregistration != 0 } {
	    $this UpdateRPMViewer 0 $this $currentregistration
	}
	return [ ::bis_algorithm::ProgressCallback $filter $lab ]
    }

    

    set ok 0
    catch { set ok [ $containerobject HasRPMGUI ]  }

    if { $ok > 0 } {
	$containerobject UpdateRPMViewer 0 $this $currentregistration
    }
    return [ ::bis_algorithm::ProgressCallback $filter $lab ]
}

# ---------------------------------------------------------------------------------------

itcl::body bis_basepointbasedregistration::UpdateRPMViewer { visib alg currentreg } {


    if { $containerobject == 0 } {
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

    set ok 0
    catch { set ok [ $containerobject HasRPMGUI ]  }
    if { $ok !=0 } {
	$containerobject UpdateRPMViewer $visib $alg $currentreg
    }
}

# ---------------------------------------------------------------------------------------
itcl::body bis_basepointbasedregistration::UpdateInputsFromContainer { } {



    if { $containerobject == 0 } {    
	return
    }

    $this SetTransformSurface [ $containerobject GetTransformSurface ] 
    $this SetReferenceSurface [ $containerobject GetReferenceSurface ] 
    $this SetInitialTransformation [ $containerobject GetInitialTransformation ] 
    [ $this GetOutputTransformation ] configure -filename ""
    $this UpdateOutputFilenames

#    puts stderr "*************************** Updating Inputs From Container ************************************"
#    puts stderr " [ [ $this GetTransformSurface ] GetDescription ]"
#    puts stderr " [ [ $this GetOutputTransformation ] GetDescription ]"
    return

}
# --------------------------------------------------------------------------------------
itcl::body bis_basepointbasedregistration::UpdateContainerWithOutput { } {

    # Reslice on the fly and update viewer ......................

    if { $currentregistration != 0 } {
	return 0
    }

    set autosave [ $this GetOptionValue guiautosave ]

    if { $autosave > 0 } {
	$OutputsArray(output_transform) SaveObject
    }
    
    if { $containerobject == 0 } {

    } else {
	PrintDebug "Calling Container ($this, $containerobject) SetResultsFromObject" 
	#	puts stderr "Calling Container ($this, $containerobject) SetResultsFromObject" 
	$containerobject SetTransformationFromObject [ $this GetOutputTransformation ] $this
    }

}

# --------------------------------------------------------------------------------------------

itcl::body bis_basepointbasedregistration::UpdateOutputFilenames { } {


    set f1 [ [ $this GetOutputTransformation ] cget -filename ]

    if { [ string length $f1 ] > 1 } {
	return 1
    }

    set fname ""; 


    if { $fname == "" } {
	set f(0) [ $InputsArray(reference_surface) GetFileName ]
	set f(1) [ $InputsArray(transform_surface) GetFileName ]

	for { set i 0 } { $i <= 1 } { incr i } {
	    set l($i) [ ::bis_common::SplitFileNameGZ $f($i) ]
	    set f($i) [ file tail [ lindex $l($i) 0 ] ]
	}
	
	set fname [ file join [ file dirname $f(0) ] "$f(0)_$f(1)" ]
    }

    
    set outlist [ $this CreateDefaultOutputFileList $fname ]
    set force 0;    if { $guimode == "managed" } {	set force 1    }    
    
    $OutputsArray(output_transform) SetFileName "[ lindex $outlist 0 ][ $this GetExtension ]" $force

    return 1
}


itcl::body bis_basepointbasedregistration::CheckInputObjects { } {


    set Surface_in    [ $this GetReferenceSurface ]
    set d [ $Surface_in GetSurfaceSize ]

    if { $d < 2 } {
	return 0
    }

    set Surface_in    [ $this GetTransformSurface ]
    set d [ $Surface_in GetSurfaceSize ]

    if { $d < 2 } {
	return 0
    }

    return 1

}

itcl::body bis_basepointbasedregistration::SetCommonPointBasedRegistrationOptions { rpmxform } {

    set userpm          [ $OptionsArray(matchmode)        GetValue ]
    set numpoints       [ $OptionsArray(numpoints)     GetValue ]
    set tstart          [ $OptionsArray(tstart)        GetValue ]
    set tend            [ $OptionsArray(tstop)          GetValue ]

    $rpmxform SetAnnealRate 0.93
    $rpmxform SetInitialTemperature $tstart
    $rpmxform SetFinalTemperature   $tend
    if { $userpm == "rpm" } {
	$rpmxform SetMatchModeToRPMFast
    } else {
	$rpmxform SetMatchModeToICP
    }
    
    $rpmxform SetUseLabels  1
    $rpmxform SetUseWeightedLeastSquares 1
    $rpmxform SetFastThreshold 3.0
    $rpmxform SetMaximumNumberOfLandmarks $numpoints



    return 1
}


# --------------------------------------------------------------------------------------------------
#
#
#
#         Custom GUI Stuff from pxitclrpm
#
#
# --------------------------------------------------------------------------------------------------

itcl::body  bis_basepointbasedregistration::CreateWarpedSurface { } {

    set filt2m [ vtkTransformPolyDataFilter [ pxvtable::vnewobj ] ]
    $filt2m SetInput [ [ $this GetReferenceSurface ] GetSurface ]
    $filt2m SetTransform [ [ $this GetOutputTransformation ] GetTransformation ]
    $filt2m Update

    [ $this GetOutputSurface ] ShallowCopySurface [ $filt2m GetOutput ]
    $filt2m Delete

    if { $bis_viewer != 0 } {
	$bis_viewer UpdatePolygonalObject [ $this GetReferenceSurface ]   {  visible 0 } 0
	$bis_viewer UpdatePolygonalObject [ $this GetTransformSurface ]   {  opacity 1.0 visible 1 } 0
	$bis_viewer UpdatePolygonalObject [ $this GetOutputSurface ]   { color "1.0 0.8 0.0" opacity 0.9 visible 1 }  1
    }
}


# -----------------------------------------------------------------------------------------------------

itcl::body  bis_basepointbasedregistration::CreateViewer { par  } {

    set bis_viewer [ [ bis_viewer \#auto ] GetThisPointer ]
    $bis_viewer CreateGUI $par
    set vtk_viewer [ $bis_viewer GetViewer ]
    $bis_viewer AddOrReplacePolygonalObject [ $this GetReferenceSurface ]  1 { color "1.0 0.0 0.0" opacity 0.5 visible 1} 
    $bis_viewer AddOrReplacePolygonalObject [ $this GetTransformSurface ]  1 { color "0.0 1.0 0.0" opacity 1.0 visible 1} 
    $bis_viewer AddOrReplacePolygonalObject [ $this GetOutputSurface ]  1 { color "1.0 1.0 0.0" opacity 0.5 visible 0 dispmode Wireframe }  
    return 1
}

itcl::body  bis_basepointbasedregistration::HasRPMGUI { } {

    if { $containerobject == 0 } {
	if { $bis_viewer > 0 } {
	    return 1
	}
    }

    return [ $containerobject HasRPMGUI ]
}

