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
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] main]

package require bis_algorithm 1.0
package require bis_newreorientimage 1.0

package provide bis_matvis2d 1.0

#
# Operations involving multisubject average for testing ....
#

itcl::class bis_matvis2d {

    inherit bis_algorithm
    
    constructor { } {
	$this Initialize
    }

    public method Initialize { }
    public method Execute { }
    public method PrintOutput { nn }
    public method GetGUIName { } { return "Matrix Visualization 2D" }
    public method UpdateOutputFilenames { } 
    public method UpdateContainerWithOutput { } 
    public method CheckInputObjects { } 

    protected variable modelist { All SingleNode SingleAttribute }

    public proc GetModeFromText { mode }
    public proc ComputeMeasuresMatrix { posmatrix negmatrix indexsur stem mode single thresholdmetric threshold attr dosave { suffix "" } }

}
# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_matvis2d::Initialize { } {

    PrintDebug "bis_matvis2d::Initialize" 

    #name,description,type,object,filename(if applicable),priority (optional)
    set inputs { 
	{ positive_matrix   "Positive Matrix" pxitclimage  ""  0}    
	{ negative_matrix   "Negative Matrix" pxitclimage  ""  1 }    
	{ nodeindexsurface  "Index Surface" pxitclsurface  ""  2 }    
    }

    set outputs { 
	{ circle  "Circle"  pxitclsurface  "" 1 }
	{ lobes   "Lobes"   pxitclsurface  "" 2 }
	{ positive_lines "Positive Lines"  pxitclsurface  "" 3 }
	{ negative_lines "Negative Lines"  pxitclsurface  "" 4 }
	{ grid    "Electrode Grid" pxitclelectrodemultigrid 101 }

    }

    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ guiautoupdate  "Auto Update display of lines on execute" "Auto-Update Display"  boolean 1 { 0 1 }  6 }
	{ guiautoupdate2  "Auto Update display of circle/lobe/numbers on execute" "Auto-Update Display Extra"  boolean 0 { 0 1 }  7 }
	{ guiautosave  "Auto save of results" "Auto Save"   boolean  0 { 0 1 }  7 }
	{ stem   "specify the filname stem for the output text file" "File Name Stem" string "" "" 0 }
	{ mode "Mode to filter connections 0=all, 1=singlenode,2=singleattribute" "Mode"  listofvalues  All { All SingleNode SingleAttribute } 1 }
	{ single "Singlenode/singlelobe/singlenetwork -- starts at 1" "SingleValue" integer 1 { 1 10000 } 2 }
	{ attribvalue "If mode =2 use this to select the column (e.g. 1=lobe,2=network,3=broadmann) etc." "AttribValue" integer 1 { 1 10 } 3 }
	{ threshold   "Threshold on metric value" "Threshold" integer 1 { 1 100000 } 4 }
	{ radius    "radius of circle" "CircleRadius" real  100      { 1.0 200.0 }   -1 }
	{ offset    "offset between circle halves" "Offset" real  10       { 1.0 50.0 }    -2 }
	{ thickness "thickness of circle" "Thickness" real  10       { 1.0 50.0 }    -3 }
	{ normallength "spline normal length" "Normallength" real  30.0       { 1.0 200.0 }    -4 }
	{ sphereradius "radius of sphere" "SphereRadius" real  1.5   { 0.5 5.0 }     -5 }
	{ circlecolorindex "index to color circle with 0=lobes,1=networks,2=..." "CircleColor" integer 0   { 0 3 }     -6 }
	{ linecolormode "Mode to Color Lines With 0=none,1=fixed,2=variable" "Line Color Mode" integer 1 { 0 2 } -7 }
	{ tmetric   "Threshold metric 0=pos,1=neg,2=sum,3=diff" "ThrMetric" integer 2 { 0 3 } -100 }
	{ positivehue "Hue  of positive stuff (red=0.02 blue=0.58, green=0.3)" "Positive Hue" real 0.02 { 0.0 1.0 } -101 }
	{ negativehue "Hue of negative stuff (red=0.02 blue=0.58, green=0.3)" "Negative Hue" real 0.58 { 0.0 1.0 } -102 }
	{ debugfiles "Save debug files files" "Debug"  int  0 { 0 2 }  -20 }
    }

    set defaultsuffix { "" }

    set scriptname bis_matvis2d
    set completionstatus ""
    #
    #document
    #
    set category "Utility"
    set description "This script computes 2D Visualizations of Connectivity Matrices"
    set description2 ""
    set backwardcompatibility ""
    set authors "xenophon.papademetris.yale.edu"

    $this AddDefaultOptions


}

itcl::body bis_matvis2d::UpdateOutputFilenames { } {

    set stem  [ $OptionsArray(stem) GetValue ]
    set md  [ $OptionsArray(mode) GetValue ]
    set single  [ $OptionsArray(single) GetValue ]
    set thr  [ $OptionsArray(threshold) GetValue ]
    set mode [ ::bis_matvis2d::GetModeFromText $md ]

    if { $stem == "" } {
	set fn1 [ $InputsArray(positive_matrix) GetFileName ]
	set fn2 [ $InputsArray(negative_matrix) GetFileName ]
	set stem [ file rootname $fn1 ]_[ file tail [ file rootname $fn2 ]]
	$OptionsArray(stem) SetValue $stem 
    }
    
    
    set tstring ""
    if { $thr !=0.0 } {
	set tstring "_t${thr}"
    }

    set nstring ""
    if { $mode == 1 } {
	set nstring "_node${single}"
    } elseif { $mode == 2 } {
	set nstring "_attr${single}"
    }

    $OutputsArray(positive_lines)  SetFileName "${stem}_2d_lines_pos${tstring}${nstring}.vtk" 1
    $OutputsArray(negative_lines)  SetFileName "${stem}_2d_lines_neg${tstring}${nstring}.vtk" 1
    $OutputsArray(grid)  SetFileName "${stem}_grid.mgrid" 1
    $OutputsArray(circle)  SetFileName "${stem}_circle.vtk" 1
    $OutputsArray(lobes)  SetFileName "${stem}_lobes.vtk" 1

    
    return 1

}
# --------------------------------------------------------------------------------------------------------------------------------------------
itcl::body bis_matvis2d::UpdateContainerWithOutput { }  {

    if { $containerobject == 0 } {
	if { [ $OptionsArray(guiautoupdate) GetValue ] > 0 } { 
	    $OutputsArray(positive_lines) DisplayObject 0 $bis_viewer
	    $OutputsArray(negative_lines) DisplayObject 0 $bis_viewer
	}
	if { [ $OptionsArray(guiautoupdate2) GetValue ] > 0 } { 
	    $OutputsArray(circle) DisplayObject 0 $bis_viewer
	    $OutputsArray(lobes)  DisplayObject 0 $bis_viewer
	    $OutputsArray(grid)   DisplayObject 0 $bis_viewer
	}
    }

}


itcl::body bis_matvis2d::CheckInputObjects { }  {

    return 1
}
# --------------------------------------------------------------------------------------------------------------------------------------------
itcl::body bis_matvis2d::GetModeFromText { md } {
    set mode 2
    if { $md =="SingleNode"} {
	set mode 1
    } elseif { $md == "All" } {
	set mode 0
    }
    return $mode
}

itcl::body bis_matvis2d::ComputeMeasuresMatrix { posmatrix negmatrix indexsur stem mode sing tm thr attr dosave { suffix "" } } {

    if { $mode == 1 } { 
	set thr 1
    }
    set lst { "Positive" "Negative" "Sum" "Diff" }
    set alst { "Orig" "Lobe" "Network" "Broadmann" }

    
    if { $mode == 0 } {
	set comment "Filter by [ lindex $lst $tm ] > $thr "
    } elseif { $mode == 1 } {
	set comment "Filter by singlenode=$sing"
    } elseif { $mode == 2 } {
	set comment "Filter by attribute=$attr (most likely [ lindex $alst $attr ])=$attr and  [ lindex $lst $tm ]>$thr "
    }
    #    puts stdout "+++++ $comment"
    
    # Create Measures matrix
    set parcutil  [ vtkbisParcellationVisualizationUtility New ]
    set metrics_matrix [ $parcutil ComputeMeasures  $posmatrix $negmatrix $indexsur $mode $sing $attr $thr $tm ]
    $parcutil Delete
    if { $dosave > 0 && $stem !="" } {
	if { $suffix =="" } {
	    set suffix "2dmeasures" 
	}
	set fname "${stem}_${suffix}.txt"
	set fout [ open $fname w ]
	puts $fout "$comment"
	puts $fout "Node No\tPositive\tNegative\tSum\tDiff\tPositive Status\tNegative Status\tSum Status\tDiff Status"
	for { set i 0 } { $i < [ $metrics_matrix GetNumberOfTuples ] } { incr i } {
	    puts $fout "[expr $i+1]\t[ $metrics_matrix GetComponent $i 0 ]\t[ $metrics_matrix GetComponent $i 1 ]\t[ $metrics_matrix GetComponent $i 2 ]\t[ $metrics_matrix GetComponent $i 3 ]\t[ $metrics_matrix GetComponent $i 4 ]\t[ $metrics_matrix GetComponent $i 5 ]\t[ $metrics_matrix GetComponent $i 6 ]\t[ $metrics_matrix GetComponent $i 7 ]"
	}
	close $fout
	puts "***** Measures saved in $fname"
    }
   return $metrics_matrix
}

# --------------------------------------------------------------------------------------------------------------------------------------------
itcl::body bis_matvis2d::Execute {  } {

    if { [ $this CheckInputObjects ] == 0 } {
	return 0
    }

    set posmatrix [ [ $this GetInputObject positive_matrix  ]  GetImage ]
    set negmatrix [ [ $this GetInputObject negative_matrix  ]  GetImage ]
    set indexsur  [  [ $this GetInputObject nodeindexsurface ] GetSurface ]
    set debugf [ $OptionsArray(debugfiles) GetValue ]
    set stem  [ $OptionsArray(stem) GetValue ]

    if { $stem == "" && $debugf > 0 } {
	set fn1 [ $InputsArray(positive_matrix) GetFileName ]
	set fn2 [ $InputsArray(negative_matrix) GetFileName ]
	set stem [ file rootname $fn1 ]_[ file tail [ file rootname $fn2 ]]
    }

    # -------------------------------------------------------------------------------------------
    # Compute Measures matrix -- this really should be a function shared by matvis2d and matvis3d
    # -------------------------------------------------------------------------------------------
    set md [ $OptionsArray(mode) GetValue ] 
    set mode [ ::bis_matvis2d::GetModeFromText $md ]
    set sing [ expr int([ $OptionsArray(single) GetValue ]) ]
    set md [ $OptionsArray(mode) GetValue ] 
    set tm  [ $OptionsArray(tmetric) GetValue ]
    set thr [ $OptionsArray(threshold) GetValue ]
    set attr [ $OptionsArray(attribvalue) GetValue ] 
    set metrics_matrix [ ::bis_matvis2d::ComputeMeasuresMatrix  $posmatrix $negmatrix $indexsur $stem $mode $sing $tm $thr $attr $debugf ]

    # -------------------------------------------------------------------------------------------
    # Visualization Options
    set radius [ $OptionsArray(radius) GetValue ]
    set thickness [ $OptionsArray(thickness) GetValue ]
    set offset [ $OptionsArray(offset) GetValue ]
    set sphradius [ $OptionsArray(sphereradius) GetValue ]
    set parcutil  [ vtkbisParcellationVisualizationUtility New ]

    # -------------------------------------------------------------------------------------------

    # -------------------------------------------------------------------------------------------
    # Create 2D Surfaces Lobes & Spheres
    # -------------------------------------------------------------------------------------------

    # create Lobes
    set circlepoly     [ $parcutil  CreateCircleSurface $indexsur $radius $offset $thickness 1 ]
    set output_lobes   [ $parcutil  CreateLobeSurface $circlepoly $radius $offset [ expr 0.3*$thickness ] $thickness ]
    [ $OutputsArray(lobes) GetObject ] DeepCopySurface $output_lobes
    $circlepoly Delete
    $output_lobes Delete

    # Create Spheres
    set circindex      [ $OptionsArray(circlecolorindex) GetValue ]
    set circlepoly2    [ $parcutil  CreateCircleSurface $indexsur $radius $offset $thickness $circindex ]

    set output_spheres [ $parcutil  CreateCircleSphereSurface $circlepoly2 $sphradius ]
    [ $OutputsArray(circle) GetObject ] DeepCopySurface $output_spheres
    $output_spheres Delete
    
    # Create Electrode Grid
    set egrid [ $parcutil CreateNumberedCircle $indexsur $circlepoly2 $radius $offset $thickness  ]
    [ $OutputsArray(grid) GetObject ] CopyElectrodeMultiGrid $egrid
    $egrid Delete
    
    set cmaputil [ vtkpxColorMapUtil New ]
    set lkup(3) [ vtkLookupTable New ]
    set hue1 [ $OptionsArray(positivehue) GetValue ]
    set hue2 [ $OptionsArray(negativehue) GetValue ]
    $cmaputil SetConstantHueColorMap $lkup(3) 1.0 $hue1 $hue2 20 -20 20 21 0 
    $parcutil CorrectOpacity $lkup(3)
    set lkup(2) [ $parcutil CreateDefaultSingleSidedLookupTable ]
    set lkup(0) [ $parcutil CreateDefaultPositiveLookupTable $lkup(3) ]
    set lkup(1) [ $parcutil  CreateDefaultNegativeLookupTable $lkup(3) ]

    if { $debugf > 1 } {
	for { set i 0 } { $i<=3 } { incr i } {
	    set fname "${stem}_lookuptable_$i.cmap"
	    $cmaputil SaveColormap $lkup($i) $fname
	    puts stdout "***** lookup table pos=$hue1 neg=$hue2 saved in $fname"
	}
    }

    $cmaputil Delete


    # -------------------------------------------------------------------------------------------
    # Draw Positive & Negative lines
    # -------------------------------------------------------------------------------------------
    for { set i 0 } { $i<=1 } { incr i } {
	if { $i  == 0 } {
	    set matrix $posmatrix
	    set name "pos"
	    set comment "Positive"
	} else {
	    set matrix $negmatrix
	    set name "neg"
	    set comment "Negative"
	}
	set n [ $lkup($i) GetNumberOfTableValues ]
	set c [ $lkup($i) GetTableValue [ expr $n -1 ] ]
	set c1 [ expr [ lindex $c 0 ]*255.0]
	set c2 [ expr [ lindex $c 1 ]*255.0]
	set c3 [ expr [ lindex $c 2 ]*255.0]	
	
	set lpairs [ $parcutil CreateLinePairs $matrix $metrics_matrix $i  0.5 ]
	set lincol [ $OptionsArray(linecolormode) GetValue ] 
	if { $debugf> 1 } {
	    set fname "${stem}_2d_lpairs_$name.txt"
	    set fout [ open $fname "w" ]
	    for { set ia 0 } { $ia < [ $lpairs GetNumberOfTuples ] } { incr ia } {
		puts $fout "[ $lpairs GetComponent $ia 0 ] [ $lpairs GetComponent $ia 1 ]"
	    }
	    close $fout
	    puts stdout "***** lpairs (numlines=[$lpairs GetNumberOfTuples ] saved in $fname"
	    puts stdout "***** Linecolormode=$lincol ($c1,$c2,$c3)"
	}

	set normallength [ $OptionsArray(normallength) GetValue ]
	set linesurface [ $parcutil Draw2DLines $circlepoly2 $lpairs $lincol $c1 $c2 $c3 0.2 $normallength $comment ]
	if { $i==0 } {
	    [ $OutputsArray(positive_lines) GetObject ] DeepCopySurface $linesurface
	} else {
	    [ $OutputsArray(negative_lines) GetObject ] DeepCopySurface $linesurface
	}
	$lpairs Delete
	$linesurface Delete
    }

    # -------------------------------------------------------------------------------------------
    # Cleanup
    $circlepoly2 Delete
    $parcutil Delete
    for { set i 0 } { $i<=3 } { incr i } {
	$lkup($i) Delete
    }
    # -------------------------------------------------------------------------------------------

    if { [ $OptionsArray(guiautosave) GetValue ] > 0 } {
	$this SaveObjects 
	puts stdout $resultmessage
    }

    return 1
}
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    

    set alg [bis_matvis2d [pxvtable::vnewobj]]
    $alg MainFunction 
}

