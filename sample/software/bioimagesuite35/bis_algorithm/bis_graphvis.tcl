#!/bin/sh
# the next line restarts using wish \
    exec vtk "$0" -- "$@"

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


lappend auto_path [ file dirname [ info script ]]
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] base]
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] apps]

package provide bis_graphvis 1.0
package require bis_imagetosurfacealgorithm 1.0


itcl::class bis_graphvis {

    inherit bis_imagetosurfacealgorithm

     constructor { } {	 $this Initialize  }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "Connectivity Graph Visualization" }
    public method RenderGraph { alg ren red green blue size stippleStyle vradius } 
    public method StartInteractor { v }

    protected variable view 0

}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_graphvis::Initialize { } {

    PrintDebug "bis_graphvis::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
    { vertexradius "Radius of the Vertex" "Vertex Radius"  { real triplescale 100 }    4.0 { 0.0 20.0 }  0 }
	{ lowerthreshold     "Lower Threshold" "Lower Threshold" { real triplescale 100 }    0.2 { -5.0 5.0 }  1 }
	{ higherthreshold    "Higher Threshold" "Higher Threshold" { real triplescale 100 }    1.0 { -5.0 5.0 }  2 }
	{ linewidth  "Width of the Edges" "Edge Width"  { real triplescale 100 }    4.0 { 1.0 10.0 }  3 }
	{ radiochoice  "Positive/Negative/Both" "Show "  { listofvalues radiobuttons }    Positive { Positive  Negative Both }  4 }
	{ mname  "specify the measures file used to compute the correlations" "Measures File"   { filename default } "" { text { .txt } }   5 }
    }

    set defaultsuffix { "_connectivity" }
    
    set scriptname bis_graphvis

    #
    #document
    #
    
     set category "Surface Processing"
	 set description  "Extract a surface from an image"
	 set description2 ""
	set backwardcompatibility "Newly added."
    set authors "alark.joshi@yale.edu"

    $this InitializeImageToSurfaceAlgorithm
}

itcl::body bis_graphvis::StartInteractor {  v } {
    if { $v == 0 } {
	return 
    }

    [ $v GetRenderWindow ] SetWindowName "Graph View -- press `q'"
    [ $v GetInteractor ] Initialize
    $v SetInteractionModeTo3D 
    $v Render 
    [$v GetInteractor ] Start 

}
# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_graphvis::Execute {  } {

    PrintDebug "bis_graphvis::Execute"

    set vertexradius   [ $OptionsArray(vertexradius) GetValue ]
    set lowerthreshold        [ $OptionsArray(lowerthreshold)      GetValue ]
    set higherthreshold      [ $OptionsArray(higherthreshold)    GetValue ]
    set linewidth   [ $OptionsArray(linewidth)    GetValue ]
    set radiochoice   [ $OptionsArray(radiochoice)    GetValue ]
    set inputfilename   [ $OptionsArray(mname)    GetValue ]
    
    set image_in    [ $this GetInput ]

	# Create a graph
	set graph [ vtkMutableUndirectedGraph New]
	# $graph SetDirected 0

	# Create points
	set pts [vtkPoints New]
	     
	#puts "The input file name is [.fsb get]"
	puts "In create connectivity selected $radiochoice"
		
	set inputfile [ open $inputfilename "r" ] 
    # set inputfile [open [.fsb get] "r"]
    gets $inputfile fileType
        
    set checkstring "#Connectivity file"
    # trimright trims trailing white spaces
	set filecheck [string compare [ string trimright $fileType ] $checkstring]   

	if {$filecheck == 0} {
		puts "Connectivity file loaded"
	} else {
		puts "Incorrect Connectivity File Format"
		return
	}
    
    gets $inputfile pointsType
    #puts $pointsType
    
    gets $inputfile num_of_centroids
    #puts "Number of points: $num_of_centroids"
    
    gets $inputfile headerCategories
        
    set nameArray [vtkStringArray New]
    $nameArray SetName "VertexLabel"
    
    set indpathlength [ vtkDoubleArray New ] 
    $indpathlength SetName "indpathlength"
    
    set globalEfficiency [ vtkDoubleArray New ] 
    $globalEfficiency SetName "globalEfficiency" 
    
    set cCentrality [ vtkDoubleArray New ] 
    $cCentrality SetName "ClosenessCentrality"
    
    set numTriangles [ vtkIntArray New ] 
    $numTriangles SetName "numTriangles" 

	set vertDegree [ vtkIntArray New ] 
	$vertDegree SetName "vertDegree"

	set localEfficiency [ vtkDoubleArray New ] 
	$localEfficiency SetName "localEfficiency"

	set betweennessCentrality [ vtkDoubleArray New ] 	
	$betweennessCentrality SetName "BetweennessCentrality" 
	
    for {set i 0} {$i < $num_of_centroids} {incr i} {
	    
	    gets $inputfile pt1
		scan $pt1 "%d %f %f %f %s %f %f %f %d %d %f %f" index px py pz name_of_roi pathlength globalEff closenessCentrality numTri vdegrees localEff BetweenCentrality
		
		set xval [expr {$px * 1.17 }]
		set yval [expr {$py * 1.17 }]
		set zval [expr {$pz * 1.17 }]

		
		$graph AddVertex
		$pts InsertNextPoint $xval $yval $zval
		
		$nameArray InsertNextValue $name_of_roi
		$indpathlength InsertNextValue $pathlength
		$globalEfficiency InsertNextValue $globalEff
		$cCentrality InsertNextValue $closenessCentrality
		$numTriangles InsertNextValue $numTri
		$vertDegree InsertNextValue $vdegrees
		$localEfficiency InsertNextValue $localEff
	  	$betweennessCentrality InsertNextValue $BetweenCentrality
		
    }    
       
    ## Process edges now 
    
    gets $inputfile connections
    #puts $connections 
    
    gets $inputfile num_of_connections
    puts $num_of_connections 
    
    set edgeStrengthArray [vtkDoubleArray New]
        
    for {set i 0} {$i < $num_of_connections} {incr i} {
   
	   gets $inputfile edge_info
	   scan $edge_info "%d %d %f" edge_src edge_dist edge_strength
	  #  puts "Edge source and destination are $edge_src and $edge_dist" 	   
	   
	   $graph AddGraphEdge $edge_src $edge_dist 
	   
	   $edgeStrengthArray InsertNextValue $edge_strength

	}
	
  $edgeStrengthArray SetName "EdgeStrength"
  
   $graph SetPoints $pts     
       
    [$graph GetVertexData] AddArray $nameArray      
	[$graph GetVertexData ] AddArray $indpathlength
	[$graph GetVertexData ] AddArray $globalEfficiency
	[$graph GetVertexData ] AddArray $cCentrality 
	[$graph GetVertexData ] AddArray $numTriangles
	[$graph GetVertexData ] AddArray $vertDegree 
	[$graph GetVertexData ] AddArray $localEfficiency
	[$graph GetVertexData ] AddArray $betweennessCentrality
    
  [$graph GetEdgeData] AddArray $edgeStrengthArray
  
  	set layout [vtkGraphLayout New]
  	$layout SetInput $graph
  	
  	set passthrough [vtkPassThroughLayoutStrategy New]
  	$layout SetLayoutStrategy $passthrough 
  		  
  		  
	#################################################################################################  		  
    if { $view == 0 } {
  	set view [ vtkGraphLayoutView New ]
    }
		    	
    	$view DisplayHoverTextOn
	# $view SetLayoutStrategyToCircular
	$view SetLayoutStrategyToPassThrough 
	# $view SetLayoutStrategyToForceDirected 

	$view SetVertexLabelArrayName [ $nameArray GetName ]
	$view VertexLabelVisibilityOn
	$view SetVertexColorArrayName [$betweennessCentrality GetName ] 
	$view ColorVerticesOn
	$view SetVertexLabelFontSize 24

	$view SetRepresentationFromInputConnection [ $layout GetOutputPort ] 
	$view SetEdgeColorArrayName [ $edgeStrengthArray GetName ] 
	$view ColorEdgesOn
	$view SetEdgeLabelArrayName [$edgeStrengthArray GetName ]
	$view EdgeLabelVisibilityOn
	$view SetEdgeLabelFontSize 10

	set theme [ vtkViewTheme New ] 
	$theme SetLineWidth 5.0
	$view ApplyViewTheme $theme
	$view Update

	# Need to figure this out for hovering labels 
	# vtkRenderedGraphRepresentation* rep = vtkRenderedGraphRepresentation::SafeDownCast(view->GetRepresentation());
	# $rep [ $view GetRepresentation ] 
	#$rep SetVertexHoverArrayName [ $betweennessCentrality GetName ] 
	# $rep SetEdgeHoverArrayName [ $edgeStrengthArray GetName ]
	 

	$view SetHideEdgeLabelsOnInteraction 1
  	$view ResetCamera


    after 100 eval "$this StartInteractor $view"

  
    #################################################################################################
  	# 1st Extraction 
  	
	#puts "Testing threshold selection..." 
	set threshold [vtkSelection New]
	set thresholdnode [vtkSelectionNode New]
	$threshold AddNode $thresholdnode
	# Set ContentType to 'Thresholds' = 7
	$thresholdnode SetContentType 7 
	# Set FieldType to 'Edge' = 4
	$thresholdnode SetFieldType 4 
	
	set thresholdArr [vtkDoubleArray New]		
	$thresholdArr SetName "value"
	$thresholdArr InsertNextValue $lowerthreshold
	$thresholdArr InsertNextValue $higherthreshold
	
	$thresholdnode SetSelectionList $thresholdArr 
		
	set extractThreshold [vtkExtractSelectedGraph New]
	$extractThreshold SetInputConnection 0 [$layout GetOutputPort]	
	$extractThreshold SetInput 1 $threshold	
	
	
	# 2nd graph 
	set threshold2 [vtkSelection New]
	set threshold2node [vtkSelectionNode New]
	$threshold2 AddNode $threshold2node
	$threshold2node SetContentType 7
	$threshold2node SetFieldType 4
	
	set thresholdArr2 [vtkDoubleArray New]
	$thresholdArr2 SetName "value"
	$thresholdArr2 InsertNextValue 0.0
	$thresholdArr2 InsertNextValue 0.4
		
	$threshold2node SetSelectionList $thresholdArr2 
	
	set layout2 [vtkGraphLayout New]
	$layout2 SetInput $graph

	set passthrough2 [vtkPassThroughLayoutStrategy New]
	$layout2 SetLayoutStrategy $passthrough2 			
		
	set extractThreshold2 [vtkExtractSelectedGraph New]
	$extractThreshold2 SetInputConnection 0 [$layout GetOutputPort]		
	$extractThreshold2 SetInput 1 $threshold2
	
	# Raw Viewer
	set ortho [ $this GetViewer ]
	$ortho SetDisplay3DMode 1

	set ren [ [ $ortho GetRenderer 3 ] GetRenderer ] 
	puts stderr "Viewer = [ $ren GetClassName ]"
	
	
	############ RenderGraph $layout $ren 0.5 0.5 0.5 2.0 65535 $vertexradius

	
	############RenderGraph $extractThreshold $ren 0.8 1.0 0.2 $linewidth 65535 $vertexradius
	
	set graphToPoly [vtkGraphToPolyData New]
	$graphToPoly SetInputConnection [ $layout GetOutputPort]
	$graphToPoly Update 

	set surface_out [ $graphToPoly GetOutput ]

    # Store Results in output
    [ $OutputsArray(output_surface) GetObject ] DeepCopySurface $surface_out 
    
    # set comment [ format " [ $this GetCommandLine full ]" ]


    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_graphvis.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_graphvis [pxvtable::vnewobj]]
    $alg MainFunction 
}


itcl::body bis_graphvis::RenderGraph { alg ren red green blue size stippleStyle vradius} {
	
	set centroid_sphere [vtkSphereSource New]
	$centroid_sphere SetRadius $vradius
	$centroid_sphere SetPhiResolution 12
	$centroid_sphere SetThetaResolution 12 

	set graphToPoly [vtkGraphToPolyData New]
	$graphToPoly SetInputConnection [$alg GetOutputPort]
	
	set edgeMapper [vtkPolyDataMapper New]
	$edgeMapper SetInputConnection [$graphToPoly GetOutputPort]
	
	set edgeActor [vtkActor New]
	$edgeActor SetMapper $edgeMapper
	[$edgeActor GetProperty] SetColor $red $green $blue
  	[$edgeActor GetProperty] SetLineWidth $size
 	[$edgeActor GetProperty] SetLineStipplePattern $stippleStyle
	[$edgeActor GetProperty] SetLineStippleRepeatFactor 2  	  	
	 
 	 set glyph [vtkGlyph3D New]
	$glyph SetInputConnection 0 [$graphToPoly GetOutputPort]
	$glyph SetInputConnection 1 [$centroid_sphere GetOutputPort]

	set vertMapper [vtkPolyDataMapper New]
	$vertMapper SetInputConnection [$glyph GetOutputPort]
	
	set vertActor [vtkLODActor New]
	$vertActor SetMapper $vertMapper
  	[$vertActor GetProperty] SetColor $red $green $blue
  	   
  	 set labelMapper [vtkLabeledDataMapper New]
	 $labelMapper SetInputConnection [$graphToPoly GetOutputPort]
	 $labelMapper SetLabelFormat "%s"
	 $labelMapper SetLabelModeToLabelFieldData	 
 	 $labelMapper SetFieldDataName "VertexLabel"
	 
	set labelActor [vtkActor2D New]
	$labelActor SetMapper $labelMapper  	
	
	$vertActor Modified
	
	$ren AddActor $edgeActor
	$ren AddActor $vertActor
	$ren AddActor $labelActor
	
	
	$graphToPoly  Update 
		
  	$labelActor Delete
  	$vertActor Delete
  	$edgeActor Delete
  	$labelMapper Delete
 	
}

