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

package provide bis_guiimageutility 1.0
package require bis_guicontainer 1.0


itcl::class bis_guiimageutility {

    inherit bis_guicontainer

    constructor { { 4dmode 0 }  } { 
	$this InitializeGUIImageUtility $4dmode 
    }

    # Create Input/Output GUI Controls for Objects in standalone mode
    protected method InitializeGUIImageUtility { { 4dmode 0 } }


    # The following methods are needed by pxitclbaseimageviewer 
    #                  type main applications
    # Change Current Working Directory
    # 
    public method SetImageFromObject { img obj  } 
    public method SetImage { img { img2 0 } } 

    # Methods for chaining into other tools
    public method SetResultsFromObject { img obj } 
    public    method DelayedCreateGUI   { }

    # Public Method -- data model control
    public method CreateInputOutputControl { nt } 
    public method SecondImageModified { args  }
    public method GrabViewerImage { args }

    # protected variables for GUIs
    protected variable image_gui 0
    protected variable second_gui 0
    protected variable fourdmode 0
}



#------------------------------------------------------------------------------------------
itcl::body bis_guiimageutility::InitializeGUIImageUtility { { 4dmode 0 } } {

    set inputs { 
	{ input_image "Input Image" pxitclimage  ""  }
	{ second_image "Second Input Image" pxitclimage  ""  }
    }
    
    set outputs {
	{ output_image "Output Image"  pxitclimage  "" }
    }
    
    set scriptname bis_guiimageutility
    set category "Graphical-User-Interface-Module"
    set description "Image Utility Clss for containing a variety of image-to-image algorithms."
    set backwardcompatibility "An upgrade of pxitclimageutility.tcl. "
    set authors "xenophon.papademetris@yale.edu."

    set completionstatus "ongoing  -- Xenios needs to revisit"

    set fourdmode $4dmode

    if { $fourdmode == 0 } {
	set componentnamelist [ list { 0 Smooth } bis_smoothimage bis_convolveimage bis_nonlinearsmoothimage bis_imagemedian bis_imagedilate bis_edgedetectimage \
				    { 0 Relabel }  bis_relabelimage  bis_newreorientimage \
				    { 0 Threshold } bis_thresholdimage bis_listthresholdimage bis_clusterthresholdimage \
				    { 0 Modify } bis_castimage bis_logimage bis_shiftscaleimage bis_piecewiseimagemap bis_distancemapimage \
				    { 0 Bias_Field } bis_sliceinhomogeneity bis_biasfield \
				    { 1 Segment } bis_stripskull bis_intsegment \
				    { 1 Crop/Resample }   bis_flipimage bis_resampleimage bis_manualreslice bis_cropimage bis_cylindricalcropimage \
				    { 2 Statistics } bis_fdr bis_rtotmap bis_rtopvalue bis_tmaptopvalue bis_tmaptozscore bis_computecorrelations \
				    { 0 FFT}  bis_fftimage bis_rfftimage ]
    } else {
	set componentnamelist [ list { 0 "4D Processing"}  bis_combineframes bis_interleave  bis_preprocessimage bis_temporalsmoothimage bis_mediantemporalsmoothimage bis_imageremoveframes bis_exponentialfitimage bis_exponentialfitt1 ]
    }

    $this AddDefaultOptions
}



::itcl::body bis_guiimageutility::DelayedCreateGUI { } {

    if { $fullyinitialized == 1 } {
	return 1
    }

    ::bis_guicontainer::DelayedCreateGUI 

    if { $fourdmode == 0 } {
	wm geometry $basewidget 600x850
    } else {
	wm geometry $basewidget 600x400
    }

    if { $fullyinitialized == 0 } {
	return 0
    }

     if { $containerobject !=0 } {
 	eval "button $buttonbar.l1  -text \"Copy Results To Image\" -command { $containerobject CopyResultsToImage }"
 	pack $buttonbar.l1 -side left
     }


    if { $fourdmode == 0 } {
	$this SetTitle "BioImageSuite::Image Utility v2 (bis_algo)"
    } else {
	$this SetTitle "BioImageSuite::4D Image Utility v2 (bis_algo)"
    }
    set fullyinitialized 1


    return 1
}
#------------------------------------------------------------------------------------------


::itcl::body bis_guiimageutility::SetImageFromObject { img obj  }  {
    $this SetImage $img
}

::itcl::body bis_guiimageutility::SetImage { img { img2 0 }  }  { 

    #    PrintDebug "\n\n\n\n\n\n .... GetImage \n\n\n\n"


    set timg [ $this GetFirstInputObject ]
    $timg ShallowCopy $img
    if { $image_gui !=0 } {
	$image_gui Update
    }

    

    if { $img2 != 0 } {
	set timg2 [ $this GetSecondInputObject ]
	$timg2 ShallowCopy $img2
	if { $second_gui !=0 } {
	    $second_gui Update
	}
    }

    set l [ llength $componentlist ]
    for { set i 0 } { $i < $l } { incr i } {
	set alg [ lindex $componentlist $i ]
	PrintDebug "In $this SetImage, going to call $alg UpdateInputsFromImageutility"
	$alg UpdateInputsFromContainer
#	puts stderr "Updated algorithm $alg , number of inputs= [ llength [ $alg GetInputsList ] ], [ $alg GetInputsList ]"
    }
}


::itcl::body bis_guiimageutility::SetResultsFromObject { img obj }  { 

    set out [ $this GetFirstOutputObject ]
    $out ShallowCopy $img
    PrintDebug "In $this SetResultsFromObject, going to updatecontainerwithoutput, $containerobject\n\n\n"

    $containerobject SetResultsFromObject $out $this
}


::itcl::body bis_guiimageutility::GrabViewerImage { args } {
    set vv 0
    set vv [ $this GetViewer ]
    if { $vv !=0 } {
	# This has a problem with headers -- hence save is disabled, mostly used to create masks etc.
	set timg2 [ $this GetSecondInputObject ]
	$timg2 ShallowCopyImage [ $vv GetImage ]
	$second_gui Update
	$this SecondImageModified
    }
}

    
::itcl::body bis_guiimageutility::SecondImageModified { args } {

    set l [ llength $componentlist ]
    for { set i 0 } { $i < $l } { incr i } {
	set alg [ lindex $componentlist $i ]
	if { [ llength [ $alg GetInputsList ] ] > 2 } {
	    #	    puts stdout "Updating $alg"
	    $alg UpdateInputsFromContainer
	}
    }
}

::itcl::body bis_guiimageutility::CreateInputOutputControl { nt } {
 
    set inputoutputtab [ $nt add -label "Inputs" ]   
    set w $inputoutputtab

    set image_gui [ [ pxitclimageGUI \#auto  ] GetThisPointer ]
    $image_gui configure -description "Input Image"

    set second_gui [ [ pxitclimageGUI \#auto  ] GetThisPointer ]
    $second_gui configure -description "Second Input Image"

    set slist [ list $image_gui $second_gui ]
    for { set i 0 } { $i <=1 } { incr i } {
	set c [ lindex $slist $i ]
	$c Initialize $w.$i
	
	if { $i == 0 } {
	    pack forget [ $c cget -loadbutton ]
	    pack forget [ $c cget -clearbutton ]
	    pack forget [ $c cget -browsebutton ]
	} else {
	    pack forget [ $c cget -savebutton ]
	    $c AddFunction "$this GrabViewerImage" "Grab From Viewer" "$this"
	}

	pack $w.$i -side top -expand false -fill x -pady 5 -padx 5
    }
    
    
    $image_gui SetObject [ $this GetFirstInputObject ]
    $second_gui SetObject [ $this GetSecondInputObject ]
    $second_gui configure -callback "$this SecondImageModified"
}
