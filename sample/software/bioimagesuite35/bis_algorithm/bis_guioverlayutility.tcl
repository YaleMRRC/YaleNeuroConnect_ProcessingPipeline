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

package provide bis_guioverlayutility 1.0
package require bis_guicontainer 1.0
package require bis_guicompareutility 1.0



itcl::class bis_guioverlayutility {

    inherit bis_guicontainer

    constructor { } { $this InitializeGUIOverlayUtility  }

    # Create Input/Output GUI Controls for Objects in standalone mode
    protected method InitializeGUIOverlayUtility { }
    public method DelayedCreateGUI { }


    # Methods for chaining into other tools
    public method SetResultsFromObject { img obj } 
    public method SetTransformationFromObject { tr obj } 
    public method SetImageFromObject { img obj } 

    #
    public method UpdateContainedAlgorithms { { includereslice 1 } }
    public method SetSecondContainerObject { cont2 } { set containerobject2 $cont2 }


    # methods for getting stuff
    public method GetReferenceImage   { } { return [ $this GetInputObject reference_image ] }
    public method GetTargetImage      { } { return [ $this GetInputObject target_image    ] }
    public method GetReslicedImage    { } { return [ $this GetInputObject resliced_image  ] }
    public method GetTransformation   { } 
    public method SetTransformation   { newtr args } 
    public method LoadAndAddTransformation { fname } 
    public method AddTransformation { tr { name "" }  }

    public method SetReslicedImageAndTransformation { alg }


    protected method UpdateTransformation   { } 
    public method UpdateTransformationCallback   { } 

    # transform/weight image control
    public method CreateInputOutputControl { nt }
    protected method CreateManualControl { base }
    public method WeightImagesModified { args }

    # Force image reslice if needed as input for various algorithms
    protected method CheckCachedReslicedSecondInputIsCorrect { } 
    public method EnsureCachedReslicedSecondInputIsCorrect { { force 0 } } 


    # Other Stuff STORAGE
    protected variable inputoutputtab 0
    protected variable transformation_control 0
    protected variable containerobject2 0

    protected variable current_transformation  [ [ pxitcltransform \#auto ] GetThisPointer ]
    protected variable owns_current_transformation 1
    protected variable reslice_alg 0

    # protected variables for GUIs
    protected variable ref_weight_gui 0
    protected variable trg_weight_gui 0
    
    # Compare utility
    protected variable compareutility 0
    public method GetCompareUtility { } { return $compareutility }


    # Manual Transformation Related
    public   method CreateManualTransformGUI { parent}
    public   method ClearManualTransformGUI { }
    public   method SetManualTransform { }
    public   method ExtractLinearTransform { in_xform image_ref image_trn numparam }
    public   method SetManualTransformGUI { }

    protected variable manualparam

    # Modified Times
    
}


#------------------------------------------------------------------------------------------
itcl::body bis_guioverlayutility::InitializeGUIOverlayUtility { } {

    set inputs { 
	{ reference_image   "Reference Image"   pxitclimage  ""  }
	{ target_image    "Target    Image"   pxitclimage  ""  }
	{ resliced_image    "Resliced Image"   pxitclimage  ""  }
	{ reference_weight_image   "Reference Weight Image"   pxitclimage  ""  }
	{ target_weight_image    "Target Weight Image"   pxitclimage  ""  }

    }

    set outputs { 
	{ output_image "Results Image" pxitclimage  ""  }
    }

    
    set scriptname "bis_guioverlayutility"
    set category "Graphical-User-Interface-Module"
    set description " Utility Class for containing a variety of registration and image merge algorithms."
    set backwardcompatibility "See pxitcloverlaytool.tcl"
    set authors "xenophon.papademetris@yale.edu."

    set completionstatus "ongoing  -- Xenios needs to revisit"

    # does not contain extract surface and mapfunctional
    set componentnamelist [ list  bis_createoverlayimage bis_manualregistration { 0 Combine Images }  bis_stitchimage  bis_blendimage bis_maskimage bis_colorblendimage bis_checkerboardimage { 0 Compare Images } bis_imagemathoperations bis_singlejacobian  bis_computesimilarity bis_computeoverlap bis_fdr { 0 Registration }  bis_linearintensityregister bis_nonlinearintensityregister bis_nonlineardistortioncorrection  bis_computedisplacementfield bis_visualizetransformation  ]
    $this AddDefaultOptions

    set extratablist { "Transformations" "Weight Images" "Image Compare" "4D Image Compare" }
    
    package require bis_resliceimage
    set reslice_alg [ [ bis_resliceimage \#auto ] GetThisPointer ]
    $reslice_alg InitializeFromContainer [ $this GetThisPointer ]
}


#------------------------------------------------------------------------------------------
::itcl::body bis_guioverlayutility::DelayedCreateGUI { } {

    if { $fullyinitialized == 1 } {
	return 1
    }

    ::bis_guicontainer::DelayedCreateGUI 
    wm geometry $basewidget 720x540

    if { $fullyinitialized == 0 } {
	#	puts stderr "Can not create gui in bis_guioverlayutility"
	return 0
    }

     if { $containerobject !=0 } {
	 eval "button $buttonbar.l1  -text \"Copy Results To Image\" -command { $containerobject CopyResultsToImage }"
	 pack $buttonbar.l1 -side left
     }


    
    $this SetTitle "BioImageSuite::Overlay/Registration Utility v2 (bis_algo)"
    set fullyinitialized 1
    return 1
}



#------------------------------------------------------------------------------------------
#  Called by surfacetosurface filter to pass output back up the chain
#------------------------------------------------------------------------------------------
::itcl::body bis_guioverlayutility::SetResultsFromObject { img obj }  { 

    set out [ $this GetFirstOutputObject ]
    $out ShallowCopy $img
    PrintDebug "In $this SetResultsFromObject, going to updatecontainerwithoutput, $containerobject\n\n\n"
    $containerobject SetResultsFromObject $out $this

    set keep 0

    if { $obj == $reslice_alg } { set keep 1 } 
    
    if { $keep == 1 } {
	[ $this GetReslicedImage ] ShallowCopy $img
	$this UpdateContainedAlgorithms 0
    }
}

::itcl::body bis_guioverlayutility::SetTransformationFromObject { tr obj }  { 

    # add the incoming tr
    $this DelayedCreateGUI

    if { $transformation_control == 0 } {
	return 0
    }

    $transformation_control AddInternalObject 
    set basetr [ $transformation_control GetCurrentObject ]
    $basetr Copy $tr

    $transformation_control CurrentObjectModified


}

# --------------------------------------------------------------------------------------

::itcl::body bis_guioverlayutility::SetImageFromObject { img obj  }  {



    if { $obj == $containerobject } {
	$this SetInputObject target_image $img
    } else {
	$this SetInputObject reference_image $img
    }

    #    puts stderr "Getting Image $img from obj=$obj ($containerobject), updating contained algorithms"
    $this UpdateContainedAlgorithms 
}


# ------------------------------------------------------------------------------------
# Transformation Interface
# ------------------------------------------------------------------------------------

::itcl::body bis_guioverlayutility::GetTransformation   { }  {

    $this UpdateTransformation
    return $current_transformation 
}

itcl::body bis_guioverlayutility::LoadAndAddTransformation { fname } {

    $this DelayedCreateGUI
    $transformation_control AddInternalObject 
    set basetr [ $transformation_control GetCurrentObject ]
    $basetr Load [ pxtclutil::GetAbsoluteFileName $fname ]
    $transformation_control CurrentObjectModified
}


itcl::body bis_guioverlayutility::AddTransformation { tr { name "" } } {

    $this DelayedCreateGUI
    set ind [ $transformation_control GetNextObjectIndex ]

    if { $name == "" } {
	$transformation_control AddInternalObject 
    } else {
	$transformation_control AddObject  "$name.$ind"
    }
    set basetr [ $transformation_control GetCurrentObject ]

    set vtkmode 1
    catch { 
	if { [ $obj isa pxitcltransform ] == 1 } {
	    set vtkmode 0
	}
    }
    
    if { $vtkmode == 0 } {
	$basetr Copy $tr
    } else {
	$basetr CopyTransformation $tr
    }
    $transformation_control CurrentObjectModified
    return $ind
}
# -----------------------------------------------------------------------

itcl::body bis_guioverlayutility::SetTransformation { newtr args } {

    set mode "modify"

    if { [ llength $args ] > 0 } {
	set mode [ lindex $args 0 ]
    }

    $this DelayedCreateGUI


    if { $mode == "add" } {
	$transformation_control AddInternalObject 
    }

    set basetr [ $transformation_control GetCurrentObject ]
    $basetr CopyTransformation $newtr
    $transformation_control CurrentObjectModified
    update idletasks
}

# -------------------------------------------------------------------

::itcl::body bis_guioverlayutility::SetReslicedImageAndTransformation { alg } {

    set ok 0
    if { $alg == $reslice_alg } {
	return
    }

    if { $alg != $reslice_alg } {
	set ok [ $this CheckCachedReslicedSecondInputIsCorrect ]
    }

    if { $ok == 1 } {
	$alg SetSecondInput [ $this GetReslicedImage ]
	[ $alg GetTransformation ] Clear 
    } else {
	$alg SetSecondInput [ $this  GetTargetImage ]
	$alg SetTransformation [ $this GetTransformation ]
    }
}


::itcl::body bis_guioverlayutility::UpdateTransformation   { }  {
    
    if { $transformation_control == 0 } { return 0 } 

    if {  $owns_current_transformation == 1 } {
	itcl::delete object $current_transformation
	set owns_current_transformation 0
    }
    set current_transformation [ $transformation_control GetObject -1 ]

}

::itcl::body bis_guioverlayutility::UpdateTransformationCallback   { }  {

    [ $this GetReslicedImage ] Clear
    $this UpdateTransformation
    $this UpdateContainedAlgorithms
}

#------------------------------------------------------------------------------------------
#  Called to update contained algorithms
#------------------------------------------------------------------------------------------

::itcl::body bis_guioverlayutility::UpdateContainedAlgorithms { { includereslice 1 } } { 

    if { $includereslice > 0 } {
	$reslice_alg UpdateInputsFromContainer
    }

    set l [ llength $componentlist ]
    for { set i 0 } { $i < $l } { incr i } {
	set alg [ lindex $componentlist $i ]
	catch { $alg SetResliceAlgorithm $reslice_alg  }
	$alg UpdateInputsFromContainer
    }

}


#------------------------------------------------------------------------------------------

itcl::body bis_guioverlayutility::WeightImagesModified {  } {

#    puts stderr "Weight Images Changed..."
    set l [ llength $componentlist ]
    for { set i 0 } { $i < $l } { incr i } {
	set alg [ lindex $componentlist $i ]
	if { [ $alg isa bis_baseintensityregistration  ] == 1 } {
	    #	puts stderr "Updating $alg"
	    $alg SetInputObject weight_image  [ $this GetInputObject reference_weight_image ]
	    $alg SetInputObject weight_image2  [ $this GetInputObject target_weight_image ]
	}
    }
}

# -----------------------------------------------------------------------------------------

itcl::body bis_guioverlayutility::CreateInputOutputControl { nt } {


    set inputoutputtab [ $nt add -label "Transformations" ]
    
    set w $inputoutputtab


    set transformation_control [ [ pxitclmultiTransformGUI \#auto  ] GetThisPointer ]
    $transformation_control Initialize $w.b
    $transformation_control AddTransformation "Default"
    eval "$transformation_control configure -callback \"$this UpdateTransformationCallback\""
    $this UpdateTransformation

    pack $w.b -side top -expand false -fill x

    iwidgets::labeledframe $w.c  -labeltext "Image Reslice"   
    pack $w.c -side bottom -expand true -fill x

    set isdual 0 ; catch { set isdual [ $reslice_alg IsDualImage ] }
    if { $isdual } { 
	lappend dualImageList $reslice_alg
    }
    $reslice_alg SetGUIMode managed
    $reslice_alg CreateGUI [ $w.c childsite ]
    
    set w2 [ $nt add -label "Weight Images" ]   
    label $w2.top -bg black -fg white -text "Use these to specify registration weights"

    set ref_weight_gui [ [ pxitclimageGUI \#auto  ] GetThisPointer ]
    $ref_weight_gui configure -description "Reference Image Weight"

    set trg_weight_gui [ [ pxitclimageGUI \#auto  ] GetThisPointer ]
    $trg_weight_gui configure -description "Transform Image Weight"


    set slist [ list $ref_weight_gui $trg_weight_gui ]
    for { set i 0 } { $i <=1 } { incr i } {
	set c [ lindex $slist $i ]
	$c InitializeLite $w2.$i 3
	$c configure -callback "$this WeightImagesModified"
	pack $w2.$i -side top -expand false -fill x -pady 5 -padx 5
    }
    
    
    $ref_weight_gui SetObject [ $this GetInputObject reference_weight_image ]
    $trg_weight_gui SetObject [ $this GetInputObject target_weight_image   ]

    set compareutility  [ [ bis_guicompareutility \#auto ] GetThisPointer ]
    $compareutility InitializeFromContainer $this
    $compareutility CreateGUI $maintabnotebook
    $compareutility SetMainTabNotebook $maintabnotebook
    $compareutility DelayedCreateGUI 

}



itcl::body bis_guioverlayutility::CheckCachedReslicedSecondInputIsCorrect {  } {

    set image_ref     [ [ $this GetReferenceImage ] GetImage ]
    set image_trn     [ [ $this GetTargetImage    ] GetImage ]
    set resliced_tmap [ [ $this GetReslicedImage  ] GetImage ]
    
    set r [ $image_ref GetMTime ]
    set t [ $image_trn GetMTime ]
    set x [ [ [ $this GetTransformation ] GetTransformation ] GetMTime ]
    set o [ $resliced_tmap GetMTime ]
    if { $o > $r && $o > $t && $o > $x } {

	#	puts stdout "Perhaps no Update Needed, [ expr $o - $r ] ,[ expr $o - $t ],  [ expr $o - $x ]"

	set dim1 [ $image_ref GetDimensions ]
	set dim2 [ $image_trn GetDimensions ]
	if { [lindex $dim2 0 ] <2 || [ lindex $dim1 0 ] < 2 } { 
	    #	puts stderr "Bad Image Sizes ..."
	    return -1
	}
    
	scan [ $image_ref GetDimensions ] "%d %d %d" dx1 dy1 dz1
	scan [ $resliced_tmap  GetDimensions ] "%d %d %d" dx2 dy2 dz2
	
	if { $dx1==$dx2 && $dy1==$dy2 && $dz1 == $dz2 } {
	    #	puts stderr "Size is Correct .... "
	    return 1
	}
    }

#    puts stdout "CachedResliced is Bad Update Needed, [ expr $o - $r ] ,[ expr $o - $t ],  [ expr $o - $x ]"
    return 0
}

itcl::body bis_guioverlayutility::EnsureCachedReslicedSecondInputIsCorrect { { force 0 } } {

    if { $force == 0 } {
	set ok [ $this CheckCachedReslicedSecondInputIsCorrect ]
	if { $ok !=0 } {
	    return $ok
	}
    }

    $reslice_alg UpdateInputsFromContainer
    $reslice_alg Execute
    [ $this GetReslicedImage ] ShallowCopy [ $reslice_alg GetOutput ] 

    if { $force == 1 } {
	$containerobject SetResultsFromObject [ $reslice_alg GetOutput ] $this
    }

    return 1
}


# -----------------------------------------------------------------------
#   Manual Transform GUI
# -----------------------------------------------------------------------
itcl::body bis_guioverlayutility::CreateManualTransformGUI { parentw  } {

    for { set i 0 } { $i <= 2 } { incr i } {

	if { $i ==0 } { 
	    set name "x"
	} elseif { $i ==1 } {
	    set name "y"
	} else {
	    set name "z"
	}

	set f [ frame ${parentw}.$name ] ; pack $f -side top -expand t -fill x

	iwidgets::entryfield $f.1 -labeltext "${name}-Shift:" -fixed 6 -width 6 -validate real -textvariable [ itcl::scope  manualparam($this,manxf_shift${name}) ]
	iwidgets::entryfield $f.2 -labeltext "${name}-Rotate:" -fixed 6 -width 6 -validate real -textvariable [ itcl::scope  manualparam($this,manxf_rotate${name}) ]
	iwidgets::entryfield $f.3 -labeltext "${name}-Scale:" -fixed 6 -width 6 -validate real -textvariable [ itcl::scope  manualparam($this,manxf_scale${name}) ]
	pack $f.1 $f.2 $f.3 -side left -expand f -fill x
    }
    
    $this ClearManualTransformGUI
    set f [ frame $parentw.bot] 
    pack $f -side bottom -expand t -fill x
    
    eval "button $f.1 -text \"Set Xformation\" -command { $this SetManualTransform }"
    eval "button $f.2 -text \"Set & Apply\" -command { $this SetManualTransform ; $this EnsureCachedReslicedSecondInputIsCorrect 1}"
    eval "button $f.3 -text \"Extract!\" -command { $this SetManualTransformGUI  }"
    eval "button $f.4 -text \"Clear Values\" -command { $this ClearManualTransformGUI }"
    pack $f.1 $f.2 $f.3 $f.4 -side left -padx 5


}
# ----------------------------------------------------------------------------------------------
itcl::body bis_guioverlayutility::ClearManualTransformGUI { } {

    for { set i 0 } { $i <=2 } { incr i } {

	if { $i == 0 } { 
	    set pname "x"
	} elseif { $i == 1 } {
	    set pname "y"
	} else {
	    set pname "z"
	}

	set manualparam($this,manxf_scale$pname) 100
	set manualparam($this,manxf_rotate$pname) 0
	set manualparam($this,manxf_shift$pname) 0
    }
}



itcl::body bis_guioverlayutility::SetManualTransform { } {
    
    for { set i 0 } { $i <=2 } { incr i } {
	
	if { $i == 0 } { 
	    set pname "x"
	} elseif { $i == 1 } {
	    set pname "y"
	} else {
	    set pname "z"
	}

	set scale($pname) $manualparam($this,manxf_scale$pname)
	if { $scale($pname) < 10 } { 
	    set scale($pname) 10 
	} elseif { $scale($pname) > 1000.0 } {
	    set scale($pname) 1000.0
	}

	set dshift($pname) $manualparam($this,manxf_shift$pname)
	if { $dshift($pname) < -2000 } { 
	    set dshift($pname) -2000
	} elseif { $dshift($pname) > 2000.0 } {
	    set dshift($pname) 2000.0
	}
				     
	set drotate($pname) $manualparam($this,manxf_rotate$pname)
	if { $drotate($pname) < -360 } { 
	    set drotate($pname) 360
	} elseif { $drotate($pname) > 360.0 } {
	    set drotate($pname) 360.0
	}

    }

    set image_trn  [ $this GetTargetImage ] 
    set image_ref  [ $this GetReferenceImage ]

    set sp(x) [ lindex [ [  $image_ref GetImage ] GetSpacing  ] 0 ]
    set sp(y) [ lindex [ [  $image_ref GetImage ] GetSpacing  ] 1 ]
    set sp(z) [ lindex [ [  $image_ref GetImage ] GetSpacing  ] 2 ]



    set tr2 [ vtkTransform [ pxvtable::vnewobj ]]
    set xform [ vtkpxLinearTransform [ pxvtable::vnewobj ]]
    $xform ManualSetParameters [expr $dshift(x)*$sp(x) ] [ expr $dshift(y) * $sp(y) ] [ expr $dshift(z)*$sp(z) ] $drotate(x) $drotate(y) $drotate(z) $scale(x) $scale(y) $scale(z)  [ $image_ref GetImage ] [ $image_ref GetOrientation ] [  $image_trn GetImage ] [ $image_trn GetOrientation ] $tr2
    $this SetTransformation $tr2
    $xform Delete
    $tr2 Delete
}


itcl::body bis_guioverlayutility::ExtractLinearTransform { in_xform image_ref image_trn numparam } {

    set image_trn  [ $this GetTargetImage ] 
    set image_ref  [ $this GetReferenceImage ]

    
    set xform [ vtkpxLinearTransform [ pxvtable::vnewobj ]]
    $xform ExtractParameters [ $in_xform GetTransformation ] 9  [ $image_ref GetImage ] [ $image_ref GetOrientation ] [  $image_trn GetImage ] [ $image_trn GetOrientation ]

    for { set k $numparam } { $k < 15 } { incr k } {
	$xform Put $k 0
    }
    return $xform
}

itcl::body bis_guioverlayutility::SetManualTransformGUI {  } {

    set in_xform [ $this GetTransformation ]


    set image_trn  [ $this GetTargetImage ] 
    set image_ref  [ $this GetReferenceImage ]


    set xform [ $this ExtractLinearTransform $in_xform $image_ref $image_trn 9 ]
    set or [ list [ $xform  Get 3 ] [ $xform  Get 4 ] [ $xform  Get 5 ] ]
    set sc [ list [ $xform  Get 6 ] [ $xform  Get 7 ] [ $xform  Get 8 ] ]
    set tr [ list [ $xform  Get 0 ] [ $xform  Get 1 ] [ $xform  Get 2 ] ]

    set sp(x) [ lindex [ [  $image_ref GetImage ] GetSpacing  ] 0 ]
    set sp(y) [ lindex [ [  $image_ref GetImage ] GetSpacing  ] 1 ]
    set sp(z) [ lindex [ [  $image_ref GetImage ] GetSpacing  ] 2 ]
    
    for { set i 0 } { $i <=2 } { incr i } {
	
	if { $i == 0 } { 
	    set pname "x"
	} elseif { $i == 1 } {
	    set pname "y"
	} else {
	    set pname "z"
	}
	
	set manualparam($this,manxf_scale$pname) [lindex $sc $i ]
	set manualparam($this,manxf_rotate$pname) [ lindex $or $i ]
	set manualparam($this,manxf_shift$pname) [ expr [ lindex $tr $i ] / $sp($pname) ]
    }
    $xform Delete
}


