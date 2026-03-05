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

package provide bis_guisurfaceutility 1.0
package require bis_guicontainer 1.0
package require pxitclsurface 1.0
package require bis_guisurfacecontrol 1.0



itcl::class bis_guisurfaceutility {

    inherit bis_guicontainer

    constructor { } { $this InitializeGUISurfaceUtility  }

    # Create Input/Output GUI Controls for Objects in standalone mode
    protected method InitializeGUISurfaceUtility { }
    public method DelayedCreateGUI { }

    # Methods for chaining into other tools
    public method SetResultsFromObject { sur obj } 
    public method SetImageFromObject { img obj } 
    public method SetImage { img   } 

    #
    public method UpdateContainedAlgorithms { } 
    public method CopyResultsToSurface { }

    # multisurfacegui control
    public method CreateInputOutputControl { nt }

    # methods for getting stuff
    public method GetImage   { } { return [ $this GetInputObject current_image ] }
    public method GetSurface { } 

    protected variable bis_surfacecontrol 0
}



#------------------------------------------------------------------------------------------
itcl::body bis_guisurfaceutility::InitializeGUISurfaceUtility { } {

    set inputs { 
	{ current_image   "Current Image"   pxitclimage  ""  }
    }

    
    set scriptname bis_guisurfaceutility
    set category "Graphical-User-Interface-Module"
    set description "Surface Utility Class for containing a variety of surface-to-surface algorithms."
    set backwardcompatibility "See vtkpxGUIPolyDataControl "
    set authors "xenophon.papademetris@yale.edu."

    set completionstatus "ongoing  -- Xenios needs to revisit"

    # does not contain extract surface and mapfunctional
    set componentnamelist [ list bis_smoothsurface  bis_computenormals bis_curvatures 0 bis_decimate  bis_subdivide bis_connect bis_cleansurface bis_triangulate  bis_delaunay3D 0   bis_extractsurface bis_mapfunctional bis_extractobjectmap bis_thresholdpoints ] 

    set bis_surfacecontrol  [ [ bis_guisurfacecontrol \#auto ] GetThisPointer ]

    set extratablist "Surfaces"

    $this AddDefaultOptions
}


 
::itcl::body bis_guisurfaceutility::GetSurface { }  {
    return [ $bis_surfacecontrol GetSurface ]
}



#------------------------------------------------------------------------------------------

::itcl::body bis_guisurfaceutility::DelayedCreateGUI { } {

    if { $fullyinitialized == 1 } {
	return 1
    }

    ::bis_guicontainer::DelayedCreateGUI 

    wm geometry $basewidget 700x440

    if { $fullyinitialized == 0 } {
	puts stderr "Can not create gui in bis_guisurfaceutility"
	return 0
    }

    
    $this SetTitle "BioImageSuite::Surface Utility v2 (bis_algo)"
    set fullyinitialized 1
    return 1
}




#------------------------------------------------------------------------------------------
#  Called by surfacetosurface filter to pass output back up the chain
#------------------------------------------------------------------------------------------
::itcl::body bis_guisurfaceutility::SetResultsFromObject { sur obj }  { 

    $bis_surfacecontrol SetResultsFromObject $sur $obj
    
}

::itcl::body bis_guisurfaceutility::SetImageFromObject { img obj  }  {

    $this SetImage $img
}

::itcl::body bis_guisurfaceutility::SetImage { img   }  { 

    PrintDebug "\n\n\n\n\n\n .... GetImage \n\n\n\n"

    set timg [ $this GetImage ]
    $timg ShallowCopy $img
    $this UpdateContainedAlgorithms
}


#------------------------------------------------------------------------------------------
#  Called to update contained algorithms
#------------------------------------------------------------------------------------------

::itcl::body bis_guisurfaceutility::UpdateContainedAlgorithms { } { 

    set l [ llength $componentlist ]
    for { set i 0 } { $i < $l } { incr i } {
	set alg [ lindex $componentlist $i ]
	PrintDebug "In $this SetImage, going to call $alg UpdateInputsFromSurfaceUtility"
	$alg UpdateInputsFromContainer
    }
}


#------------------------------------------------------------------------------------------

itcl::body bis_guisurfaceutility::CreateInputOutputControl { nt } {


    set inputoutputtab [ $nt add -label "Surfaces" ]
    
    set w $inputoutputtab
    eval "$bis_surfacecontrol CreateGUI $this $inputoutputtab \"$this UpdateContainedAlgorithms\" "
}


#------------------------------------------------------------------------------------------
itcl::body bis_guisurfaceutility::CopyResultsToSurface { } {

    $bis_surfacecontrol CopyResultsToSurface $sur $obj
}

#------------------------------------------------------------------------------------------


