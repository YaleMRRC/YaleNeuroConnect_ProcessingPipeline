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

package provide bis_guisurfacecontrol 1.0
package require pxitclsurface 1.0



itcl::class bis_guisurfacecontrol {

    constructor { } { 
	set currentsurface [ [ pxitclsurface \#auto ] GetThisPointer ]
	set currentresults [ [ pxitclsurface \#auto ] GetThisPointer ]

    }
    destructor { 
	itcl::delete object $currentsurface
	itcl::delete object $currentresults
	catch { 
	    itcl::delete object $surfacecontrol 
	    itcl::delete object $resultscontrol 
	}
    }
    # Create Input/Output GUI Controls for Objects in standalone mode
    protected method InitializeGUISurfacecontrol { }


    # Methods for chaining into other tools
    public method SetResultsFromObject { sur obj } 
    public method SetSurfaceFromObject { sur obj } 
    public method CopyResultsToSurface { }

    public method GetSurface { } { return $currentsurface }
    public method GetResults { } { return $currentresults }
    public method GetThisPointer { } { return $this }
    
    # multisurfacegui control
    public method CreateGUI { container basew { modifiedcallback "" } { displayonly 0 } }
    public method Callback_SurfaceModified { mode args }
    public method UpdateActorProperties { mode attribute args }
    public method ColorDialog { mode } 

    protected method GetOrthoViewer {  } 
    protected method CreateActors { }
    protected method InvokeCallback { }

    # SURFACE INFO STORAGE
    protected variable actorarray    
    protected variable surfacecontrol 0
    protected variable resultscontrol 0

    protected variable surfacemode 0
    protected variable resultsmode 0
    protected variable currentsurface 0
    protected variable currentresults 0
    protected variable hasactors 0
    protected variable surfacecolor { 1 0 0 }
    protected variable resultscolor { 0 1 0 }
    protected variable callback ""
    protected variable containerobject 0
    protected variable displayonlymode 0
}



#------------------------------------------------------------------------------------------
#  Called by surfacetosurface filter to pass output back up the chain
#------------------------------------------------------------------------------------------

::itcl::body bis_guisurfacecontrol::SetSurfaceFromObject { sur obj }  { 
    
    $currentsurface ShallowCopy $sur
    $surfacecontrol Update
    $this Callback_SurfaceModified surface
}
::itcl::body bis_guisurfacecontrol::SetResultsFromObject { sur obj }  { 

    $currentresults ShallowCopy $sur
    $resultscontrol Update
    $this Callback_SurfaceModified results 
}


#------------------------------------------------------------------------------------------

itcl::body bis_guisurfacecontrol::InvokeCallback { } {

    if { $callback ==0 || $callback == "" } {
	return
    }

    return [ eval $callback ]
}



itcl::body bis_guisurfacecontrol::CreateGUI { container basew { modifiedcallback "" } { displayonly 0 } } { 


    set displayonlymode [ expr $displayonly > 0 ]
    set callback $modifiedcallback
    set containerobject $container
    set w $basew
    frame $w.top; pack $w.top -side top -expand false -fill x

    set w2 $w.top

    if { $displayonlymode == 0 } {
	eval "button $w2.bot -text \"Copy Results to Surface\" -command { $this CopyResultsToSurface }"
	pack $w2.bot -side bottom -expand false -fill x -pady 2
    }

    set surfacecontrol [ [ pxitclsurfaceGUI \#auto  ] GetThisPointer ]
    if { $displayonlymode == 0 } {
	$surfacecontrol configure -description "Surface"
    } else {
	$surfacecontrol configure -description "Input Surface"
    }
    $surfacecontrol Initialize $w2.a
    if { $displayonlymode == 0 } {
	$surfacecontrol configure -callback "$this Callback_SurfaceModified surface"
    }

    frame $w2.b

    set surfacemode [ [ bis_option \#auto ] GetThisPointer ]
    $surfacemode SetAllProperties "-metric" "" "Surface Mode" listofvalues Surface { None Points Wireframe Surface } 102
    $surfacemode CreateGUIElement $w2.b.1 [ itcl::code $this Callback_SurfaceModified surface ]
    $surfacemode HideHelpButton
    eval "button $w2.b.2 -text Color -command { $this ColorDialog surface }"
    pack $w2.b.1 $w2.b.2  -side left -expand true -fill x

    frame $w2.c

    set slinewidth [ [ bis_option \#auto ] GetThisPointer ]
    $slinewidth SetAllProperties "-linewidth" "Line width" "Line width" real 2.0 { 1.0 10.0 } 1 
    $slinewidth CreateGUIElement $w2.c.1 [ itcl::code $this UpdateActorProperties surface linewidth ] 
    $slinewidth SetValueRange { 1.0 10.0 }

    set spointsize [ [ bis_option \#auto ] GetThisPointer ]
    $spointsize SetAllProperties "-pointsize" "Point Size" "Point size" real 2.0 { 1.0 10.0 } 2
    $spointsize CreateGUIElement $w2.c.2 [ itcl::code $this UpdateActorProperties surface pointsize ] 
    $spointsize SetValueRange { 1.0 10.0 } 
    pack $w2.c.1 $w2.c.2  -side left -expand true -fill x

    frame $w2.d  -height 3 -bg black
    pack $w2.a $w2.b $w2.c $w2.d -side top -expand false -fill x


    set resultscontrol [ [ pxitclsurfaceGUI \#auto  ] GetThisPointer ]
    if { $displayonlymode == 0 } {
	$resultscontrol configure -description "Results"
    } else {
	$resultscontrol configure -description "Output Surface"
    }
    $resultscontrol Initialize $w2.e

    if { $displayonlymode == 0 } {
	$resultscontrol configure -callback "$this Callback_SurfaceModified results"
    }

    frame $w2.f

    set resultsmode [ [ bis_option \#auto ] GetThisPointer ]
    $resultsmode SetAllProperties "-metric" "" "Results Mode" listofvalues Surface { None Points Wireframe Surface } 102
    $resultsmode CreateGUIElement $w2.f.1 [ itcl::code $this Callback_SurfaceModified results ]
    $resultsmode HideHelpButton
    eval "button $w2.f.2 -text Color -command { $this ColorDialog results }"
    pack $w2.f.1 $w2.f.2 -side left -expand true -fill x

    frame $w2.g

    set rpointsize [ [ bis_option \#auto ] GetThisPointer ]
    $rpointsize SetAllProperties "-pointsize" "Point Size" "Point size" real 2.0 { 1.0 10.0 } 3
    $rpointsize CreateGUIElement $w2.g.1 [ itcl::code $this UpdateActorProperties results pointsize ]
    $rpointsize SetValueRange { 1.0 10.0 } 

    set rlinewidth [ [ bis_option \#auto ] GetThisPointer ]
    $rlinewidth SetAllProperties "-linewidth" "Line width" "Line width" real 2.0 { 1.0 10.0 } 4
    $rlinewidth CreateGUIElement $w2.g.2 [ itcl::code $this UpdateActorProperties results linewidth ]
    $rlinewidth SetValueRange { 1.0 10.0 }
    pack $w2.g.1 $w2.g.2 -side left -expand false -fill x

    pack $w2.e $w2.f $w2.g -side top -expand false -fill x


    if { $displayonlymode == 1 } {
	set slist [ list $surfacecontrol $resultscontrol ]
	for { set i 0 } { $i <=1 } { incr i } {
	    set c [ lindex $slist $i ]
	    catch {
		pack forget [ $c cget -loadbutton ]
		pack forget [ $c cget -savebutton ]
		pack forget [ $c cget -clearbutton ]
		pack forget [ $c cget -browsebutton ]
	    }
	}
    }
	

    $this CreateActors

}



#------------------------------------------------------------------------------------------
itcl::body bis_guisurfacecontrol::GetOrthoViewer {  } {

    if { $containerobject == 0 } {
	return
    } 
    
    set viewer [ $containerobject GetViewer ]
    if { $viewer ==0 } {
	return 0
    }

    set tmp 0;    catch { set tmp [ $viewer IsA "vtkpxGUIOrthogonalViewer" ] }

    if { $tmp == 0 } {
	return 0
    }

    return $viewer
}



#------------------------------------------------------------------------------------------
itcl::body bis_guisurfacecontrol::CopyResultsToSurface { } {

    $currentsurface Copy $currentresults 1
    $surfacecontrol Update
    $this Callback_SurfaceModified "surface"
}



#------------------------------------------------------------------------------------------
itcl::body bis_guisurfacecontrol::CreateActors {  } {

    $currentsurface configure -filename "surface.vtk"
    $surfacecontrol SetObject $currentsurface
    $currentresults configure -filename "results.vtk"
    $resultscontrol SetObject $currentresults

    set slist [ list $currentsurface $currentresults ]


    
    set viewer [ $this GetOrthoViewer ]
    if { $viewer == 0 } {
	return 0    
    }

    

    for { set k 0 } { $k <= 1 } { incr k } {
	set ns [ lindex $slist $k ]
	for { set i 0 } { $i <=3 } { incr i } {
	    set map [ vtkPolyDataMapper New ]
	    $map SetInput [ $ns GetSurface ]
	    
	    set act [ vtkActor New ]
	    set actorarray($ns,$i) $act
	    $act SetMapper $map
	    $act SetVisibility 1
	    [ [ $viewer GetRenderer $i ] GetRenderer ] AddActor $act
	    if { $k == 0 } {
		[ $act GetProperty ] SetColor [ lindex $surfacecolor 0 ]  [ lindex $surfacecolor 1 ]  [ lindex $surfacecolor 2 ] 
	    } else {
		[ $act GetProperty ] SetColor [ lindex $resultscolor 0 ]  [ lindex $resultscolor 1 ]  [ lindex $resultscolor 2 ] 
	    }
	}
    }
	
    set hasactors 1
    $surfacemode SetValue "Surface"
    $resultsmode SetValue "Surface"
    $this Callback_SurfaceModified "both"
}


#-----------------------------------------------------------------------------------------
itcl::body bis_guisurfacecontrol::ColorDialog { mode } {

    if { $hasactors == 0 } {
	return
    }

    set viewer [ $this GetOrthoViewer ]
    if { $viewer == 0 } {
	return
    }

    if { $mode == "surface" } { 
	set surfacecolor [ pxtclutil::ColorBox "Set Color for Surface" $surfacecolor $basewidget ]
	set c $surfacecolor
	set ns $currentsurface
    } else {
	set resultscolor [ pxtclutil::ColorBox "Set Color for Results" $resultscolor $basewidget ]
	set c $resultscolor
	set ns $currentresults 
    }
	
    for { set i 0 } { $i <=3 } { incr i } {
	set act $actorarray($ns,$i) 
	[ $act GetProperty ] SetColor [ lindex $c 0 ]  [ lindex $c 1 ]  [ lindex $c 2 ] 
    }
    $viewer UpdateDisplay
}



itcl::body bis_guisurfacecontrol::UpdateActorProperties { mode attribute args } {

    if { $hasactors == 0 } {
	return 0
    }

    set input_value [ lindex $args 1 ]
	
    set slist [ list $currentsurface $currentresults ]
    set viewer [ $this GetOrthoViewer ]
    if { $viewer == 0 } {	return 0    }
    

    if { $mode == "surface" } { 
	set k 0
    } else  {
	set k 1 
    }
    set ns [ lindex $slist $k ]
    set md [ $surfacemode GetValue ]
    if { $k == 1 } {
	set md [ $resultsmode GetValue ]
    }
    
    for { set i 0 } { $i <=3 } { incr i } {
	set act $actorarray($ns,$i) 
	set map [ $act GetMapper ] 
	$map SetInput [ $ns GetSurface ]
	
	if { $md == "None" } {
	    $act SetVisibility 0
	} elseif { $md == "Wireframe"} { 
	    [ $act GetProperty ] SetRepresentationToWireframe 
	    [ $act GetProperty ] SetLineWidth $input_value
	    $act SetVisibility 1
	} elseif { $md == "Points"} { 
	    [ $act GetProperty ] SetRepresentationToPoints
	    [ $act GetProperty ] SetPointSize $input_value
	    $act SetVisibility 1
	} else {
	    [ $act GetProperty ] SetRepresentationToSurface
	    $act SetVisibility 1
	}
    }    
    $viewer UpdateDisplay
}





itcl::body bis_guisurfacecontrol::Callback_SurfaceModified { mode args } {

    if { $hasactors == 0 } {
	return 0
    }

    #    puts [ lindex $args 0 ]
    #    puts [ lindex $args 1 ]

    set slist [ list $currentsurface $currentresults ]
    set viewer [ $this GetOrthoViewer ]
    if { $viewer == 0 } { return 0    }
    
    for { set k 0 } { $k <= 1 } { incr k } {
	set ns [ lindex $slist $k ]
	set md [ $surfacemode GetValue ]
	if { $k == 1 } {
	    set md [ $resultsmode GetValue ]
	}
	
	for { set i 0 } { $i <=3 } { incr i } {
	    set act $actorarray($ns,$i) 
	    set map [ $act GetMapper ] 
	    $map SetInput [ $ns GetSurface ]
	    
	    if { $md == "None" } {
		$act SetVisibility 0
	    } elseif { $md == "Wireframe"} { 
		[ $act GetProperty ] SetRepresentationToWireframe 
		#		[ $act GetProperty ] SetLineWidth
		$act SetVisibility 1
 	    } elseif { $md == "Points"} { 
		[ $act GetProperty ] SetRepresentationToPoints
		$act SetVisibility 1
	    } else {
		[ $act GetProperty ] SetRepresentationToSurface
		$act SetVisibility 1
	    }
	}    
    }

    if { $displayonlymode == 0 } {
	if { $mode != "results" } {
	    $this InvokeCallback
	}
    }
    $viewer UpdateDisplay
}


