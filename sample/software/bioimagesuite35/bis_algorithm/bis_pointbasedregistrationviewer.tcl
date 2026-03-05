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

package provide bis_pointbasedregistrationviewer 1.0

itcl::class bis_pointbasedregistrationviewer {

    constructor { } { }
    public method Initialize { }

    # Custom Viewer for RPM
    public method CreateViewer { fr }
    public method GetThisPointer { } { return $this }

    # Protected Variable
    public method SetAlgorithm { alg } { set algorithm $alg }

    # Callbacks from surfaces
    public method SetSurfaceMode { sur } 
    public method ShowSurfaces { { applytransformation 0 } }
    public method Update { visib rpmfilter } 


    public method HasRPMGUI { } { return $has_rpm_gui }

    protected common guiparam
    protected variable renderwindow 0
    protected variable algorithm 0
    protected variable vtk_viewer 0
    protected variable bis_viewer 0

    protected variable refsur  0
    protected variable targsur 0
}


# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_pointbasedregistrationviewer::Initialize { } {
    


}



# ----------------------------------------------------------
#
#  Input/Output Utility Stuff
#
# ----------------------------------------------------------

itcl::body  bis_pointbasedregistrationviewer::CreateViewer { par  } {

 
    set topframe [ LabelFrame:create  $par.cont -text "Display Controls" ]
    pack $par.cont -side top -fill x -pady 0 -expand false

    set b [ frame $topframe.1 ]
    set w2 [ frame $topframe.2 ]
    pack $b $w2     -side top -expand true -fill x
    set thisparam($this,gui_control2) [ button $b.b3 -text "Show Original Surfaces" ]
    set thisparam($this,gui_control3) [ button $b.b4 -text "Show Transformed Surfaces" ]
    eval "$thisparam($this,gui_control2) configure -command {  $this ShowSurfaces 0 }"
    eval "$thisparam($this,gui_control3) configure -command {  $this ShowSurfaces 1 }"
    pack $b.b3 $b.b4   -side left -fill x -padx 2 -expand true

     frame $par.bot
     pack $par.bot -side bottom -expand true -fill both
    
    set bis_viewer [ [ bis_viewer \#auto ] GetThisPointer ]
    $bis_viewer CreateGUI $par.bot
    set vtk_viewer [ $bis_viewer GetViewer ]

#    $bis_viewer AddPolygonalObject $itclgrid 1
#    $bis_viewer AddPolygonalObject $itclgrid 1
#    $bis_viewer AddPolygonalObject $itclgrid 1
#
#     set ren [ vtkRenderer [ pxvtable::vnewobj ]]

#     set renWidg [ vtkTkRenderWidget $wtop.r -width 500 -height 500 ]
#     pack $renWidg -side top -expand true -fill both
#     set renderwindow [ $renWidg GetRenderWindow ]
#     $renderwindow AddRenderer $ren

#     set vtk_viewer [ vtkpxGUIRenderer [ pxvtable::vnewobj ] ]
#     $vtk_viewer BindMouseEvents $renWidg "$this HandleMouseEvent" "$this HandleUpdateEvent"
#     $vtk_viewer SetNoPolyClipControls 1
#     $vtk_viewer Initialize $wtop.bot $ren 1
    
#     for { set j 1 } { $j <= 2 } { incr j } {
# 	set guiparam($this,gui_actor$j) [ vtkActor [ pxvtable::vnewobj ] ]
# 	set act $guiparam($this,gui_actor$j)
	
# 	set map [ vtkPolyDataMapper [ pxvtable::vnewobj ] ]
# 	$act SetMapper $map
	
# 	$map Delete
# 	$act SetVisibility 0
	
# 	[ $act GetProperty] SetRepresentationToWireframe
# 	[ $act GetProperty ] SetAmbient 1.0 
# 	[ $act GetProperty ] SetDiffuse 0.0
# 	[ $act GetProperty ] SetOpacity 1.0
# 	[ $act GetProperty ] SetLineWidth 1.0
# 	if { $j == 1 } {
# 	    [ $act GetProperty] SetColor 1.0 0.0 0.0
# 	} else {
# 	    [ $act GetProperty] SetColor 0.0 1.0 0.0
# 	}
	
# 	[ $vtk_viewer GetRenderer ] AddActor $act
#     }
#     [ $vtk_viewer GetRenderer ] SetBackground 0.2 0.2 0.3
#     puts stderr "I am now ($this) getting an rpm_gui"
    set has_rpm_gui 1

    #        wm geometry $basewidget 600x1500
}

# ---------------------------------------------------------------------------------
itcl::body bis_pointbasedregistrationviewer::ShowSurfaces { { applytransformation 0 } } {
 

    if { $algorithm == 0 } {
	return 0
    }

    if { $refsur == 0 } {
	set refsur  [ [ pxitclsurface \#auto ] GetThisPointer ]
	set targsur [ [ pxitclsurface \#auto ] GetThisPointer ]
    }

    set sourcesurface  [ [ $algorithm GetReferenceSurface ] GetSurface ]
    set targetsurface  [ [ $algorithm GetTransformSurface ] GetSurface ]

    $refsur ShallowCopySurface $sourcesurface

    set dat1 $sourcesurface
    set dat2 $targetsurface
    set dat_trn 0

    if { $applytransformation ==0 } {
	$targsur ShallowCopySurface $targetsurface
    } else {
	set dat_trn [ [ $algorithm GetOutputTransformation ] GetObject ]
	
	set filt2m [ vtkTransformPolyDataFilter [ pxvtable::vnewobj ] ]
	$filt2m SetInput $dat1
	$filt2m SetTransform $dat_trn
	$filt2m Update

	$targsur ShallowCopySurface [ $filt2m GetOutput ]
	$filt2m Delete 
    }

    $bis_viewer AddPolygonalObject $refsur 1
    $bis_viewer AddPolygonalObject $targsur 1
}


# ---------------------------------------------------------------------------------
#  Update  commands
# -----------------------------------------------------------------------------------

itcl::body bis_pointbasedregistrationviewer::Update { visib  regfilter } {


    if { $algorithm == 0 } {
	return
    }

    set sourcesurface [ [ $algorithm GetReferenceSurface ] GetSurface ]
    set targetsurface [ [ $algorithm GetTransformSurface ] GetSurface ]

    if { $refsur == 0 } {
	set refsur  [ [ pxitclsurface \#auto ] GetThisPointer ]
	set targsur [ [ pxitclsurface \#auto ] GetThisPointer ]
    }

    $refsur ShallowCopySurface $sourcesurface
    
    set dat1 $sourcesurface
    set dat2 $targetsurface

    set dat_trn  [ $regfilter GetCurrentTransformation ]

    set filt2m [ vtkTransformPolyDataFilter [ pxvtable::vnewobj ] ]
    $filt2m SetInput $dat1
    $filt2m SetTransform $dat_trn
    $filt2m Update
    $targsur ShallowCopySurface [ $filt2m GetOutput ]
    $filt2m Delete 

    
    $bis_viewer AddPolygonalObject $refsur 1
    $bis_viewer AddPolygonalObject $targsur 1

    update idletasks
}



