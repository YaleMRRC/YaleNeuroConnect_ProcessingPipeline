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
package require bis_matvis2d 1.0

package provide bis_matvis3d 1.0

#
# Operations involving multisubject average for testing ....
#

itcl::class bis_matvis3d {

    inherit bis_algorithm
    
    constructor { } {
	$this Initialize
    }

    public method Initialize { }
    public method Execute { }
    public method PrintOutput { nn }
    public method GetGUIName { } { return "Matrix Visualization 3D" }
    public method UpdateOutputFilenames { } 
    public method UpdateContainerWithOutput { } 
    public method CheckInputObjects { } 

    protected variable modelist { All SingleNode SingleAttribute }

}
# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_matvis3d::Initialize { } {

    PrintDebug "bis_matvis3d::Initialize" 

    #name,description,type,object,filename(if applicable),priority (optional)
    set inputs { 
	{ positive_matrix   "Positive Matrix" pxitclimage  ""  0}    
	{ negative_matrix   "Negative Matrix" pxitclimage  ""  1 }    
	{ nodeindexsurface  "Index Surface" pxitclsurface  ""  2 }    
	{ parsurface   "Parcellation Surface" pxitclsurface  ""  101 }    
    }


    set outputs { 
	{ pos_spheres  "Pos-Blob"  pxitclsurface  "" 3 }
	{ neg_spheres  "Neg-Blob"  pxitclsurface  "" 4 }
	{ sum_spheres  "Sum-Blob"  pxitclsurface  "" 5 }
	{ diff_spheres  "Diff-Blob"  pxitclsurface  "" 6 }
	{ positive_lines "Positive Lines"  pxitclsurface  "" 1 }
	{ negative_lines "Negative Lines"  pxitclsurface  "" 2 }
    }

    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ stem   "specify the filname stem for the output text file" "File Name Stem" string "" "" 0 }
	{ mode "Mode to filter connections 0=all, 1=singlenode,2=singleattribute" "Mode" listofvalues  All { All SingleNode SingleAttribute } 1 }
	{ single "Singlenode/singlelobe/singlenetwork -- starts at 1" "SingleValue" integer 1 { 1 10000 } 2 }
	{ attribvalue "If mode =2 use this to select the column (e.g. 1=lobe,2=network,3=broadmann) etc." "AttribValue" integer 1 { 1 10 } 3 }
	{ threshold   "Threshold on metric value" "Threshold" integer 1 { 0 100000 } 4 }
	{ surfacemode "Output of rendering either blobs or colored parcellation (if parsurface is specified)" "Surface Mode" listofvalues  Blobs { Blobs Parcellation } 5 }
	{ guiautoupdate  "Auto Update display of lines on execute" "Auto-Update Display"  boolean 1 { 0 1 }  8 }
	{ guiautosave  "Auto save of results" "Auto Save"   boolean  0 { 0 1 }  9 }
	{ sphereradius "radius of sphere" "SphereRadius" real  2.0   { 0.5 5.0 }     -4 }
	{ spherepower "power of sphere" "SpherePower" real  0.5   { 0.2 5.0 }     -5 }
	{ linecolormode "Mode to Color Lines With 0=none,1=fixed,2=variable" "Line Color Mode" integer 1 { 0 2 } -6 }
	{ tmetric   "Threshold metric 0=pos,1=neg,2=sum,3=diff" "ThrMetric" integer 2 { 0 3 } -100 }
	{ positivehue "Hue  of positive stuff (red=0.02 blue=0.58, green=0.3)" "Positive Hue" real 0.02 { 0.0 1.0 } -101 }
	{ negativehue "Hue of negative stuff (red=0.02 blue=0.58, green=0.3)" "Negative Hue" real 0.58 { 0.0 1.0 } -102 }
	{ debugfiles "Save debug files files" "Debug"  int  0 { 0 2 }  -20 }
    }

    set defaultsuffix { "" }

    set scriptname bis_matvis3d
    set completionstatus ""
    #
    #document
    #
    set category "Utility"
    set description "This script computes 3D Visualizations of Connectivity Matrices"
    set description2 ""
    set backwardcompatibility ""
    set authors "xenophon.papademetris.yale.edu"

    $this AddDefaultOptions


}

itcl::body bis_matvis3d::UpdateOutputFilenames { } {

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

    set np  [ [ [ $this GetInputObject parsurface ] GetSurface ] GetNumberOfPoints ]
    set m  [ $OptionsArray(surfacemode) GetValue ]
    if { $np > 100 && $m == "Blobs" } {
	set np 0
    }

    set bstring "blob"
    if { $np > 100 } {
	set bstring "parc"
    }

    set nstring ""
    if { $mode == 1 } {
	set nstring "_node${single}"
    } elseif { $mode == 2 } {
	set nstring "_attr${single}"
    }

    $OutputsArray(pos_spheres)  SetFileName "${stem}_3d_${bstring}_pos${tstring}${nstring}.vtk" 1
    $OutputsArray(neg_spheres)  SetFileName "${stem}_3d_${bstring}_neg${tstring}${nstring}.vtk" 1
    $OutputsArray(sum_spheres)  SetFileName "${stem}_3d_${bstring}_sum${tstring}${nstring}.vtk" 1
    $OutputsArray(diff_spheres)  SetFileName "${stem}_3d_${bstring}_diff${tstring}${nstring}.vtk" 1
    $OutputsArray(positive_lines)  SetFileName "${stem}_3d_lines_pos${tstring}${nstring}.vtk" 1
    $OutputsArray(negative_lines)  SetFileName "${stem}_3d_lines_neg${tstring}${nstring}.vtk" 1

    return 1

}

itcl::body bis_matvis3d::UpdateContainerWithOutput { }  {

    if { $containerobject == 0 } {
	if { [ $OptionsArray(guiautoupdate) GetValue ] > 0 } { 
	    $OutputsArray(positive_lines) DisplayObject 0 $bis_viewer
	    $OutputsArray(negative_lines) DisplayObject 0 $bis_viewer
	}
    }
}

itcl::body bis_matvis3d::CheckInputObjects { }  {

    return 1
}

itcl::body bis_matvis3d::Execute {  } {

    if { [ $this CheckInputObjects ] == 0 } {
	return 0
    }

    set posmatrix [ [ $this GetInputObject positive_matrix  ]  GetImage ]
    set negmatrix [ [ $this GetInputObject negative_matrix  ]  GetImage ]
    set indexsur  [  [ $this GetInputObject nodeindexsurface ] GetSurface ]
    set parsurface [ [ $this GetInputObject parsurface ] GetSurface ]
    set stem  [ $OptionsArray(stem) GetValue ]
    set debugf [ $OptionsArray(debugfiles) GetValue ]
    
    if { $debugf > 0 &&  $stem == "" } {
	set fn1 [ $InputsArray(positive_matrix) GetFileName ]
	set fn2 [ $InputsArray(negative_matrix) GetFileName ]
	set stem [ file rootname $fn1 ]_[ file tail [ file rootname $fn2 ]]
    }

    set parcutil  [ vtkbisParcellationVisualizationUtility New ]

    # -------------------------------------------------------------------------------------------
    # Compute Measures matrix -- this really should be a function shared by matvis2d and matvis3d
    # -------------------------------------------------------------------------------------------
    set sing [ expr int([ $OptionsArray(single) GetValue ]) ]
    set md [ $OptionsArray(mode) GetValue ] 
    set mode [ ::bis_matvis2d::GetModeFromText $md ]
    set tm  [ $OptionsArray(tmetric) GetValue ]
    set thr [ $OptionsArray(threshold) GetValue ]
    set attr [ $OptionsArray(attribvalue) GetValue ] 
    set metrics_matrix [ ::bis_matvis2d::ComputeMeasuresMatrix  $posmatrix $negmatrix $indexsur $stem $mode $sing $tm $thr $attr $debugf "3dmeasures" ]

    
    # -------------------------------------------------------------------------------------------
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
	    set name "positive"
	    set comment "Positive"
	} else {
	    set matrix $negmatrix
	    set name "negative"
	    set comment "Negative"
	}
	set n [ $lkup($i) GetNumberOfTableValues ]
	set c [ $lkup($i) GetTableValue [ expr $n -1 ] ]
	set c1 [ expr [ lindex $c 0 ]*255.0]
	set c2 [ expr [ lindex $c 1 ]*255.0]
	set c3 [ expr [ lindex $c 2 ]*255.0]

	set lpairs [ $parcutil CreateLinePairs $matrix $metrics_matrix $i 0.5 ]
	set lincol [ $OptionsArray(linecolormode) GetValue ] 
	
	if { $debugf > 1 } {
	    set fname "${stem}_lpairs_$name.txt"
	    set fout [ open $fname "w" ]
	    for { set ia 0 } { $ia < [ $lpairs GetNumberOfTuples ] } { incr ia } {
		puts $fout "[ $lpairs GetComponent $ia 0 ] [ $lpairs GetComponent $ia 1 ]"
	    }
	    close $fout
	    puts "***** lpairs (numlines=[$lpairs GetNumberOfTuples ]) saved in $fname"
	    puts stdout "***** Linecolormode=$lincol ($c1,$c2,$c3)"
	}
	set linesurface [ $parcutil Draw3DLines $indexsur $lpairs $lincol $c1 $c2 $c3 $comment ]
	
	[ $OutputsArray(${name}_lines) GetObject ] DeepCopySurface $linesurface
    	$lpairs Delete
	$linesurface Delete
    }

    
    # -------------------------------------------------------------------------------------------
    # Draw either blobs or colored parcellations
    # -------------------------------------------------------------------------------------------
    set lst { "pos_spheres" "neg_spheres" "sum_spheres" "diff_spheres" }
    set spherepower [ $OptionsArray(spherepower) GetValue ]
    set spherescale [ $OptionsArray(sphereradius) GetValue ]


    set np [ $parsurface GetNumberOfPoints ]
    set m  [ $OptionsArray(surfacemode) GetValue ]
    if { $np > 100 && $m == "Blobs" } {
	set np 0
    }

    set filtered 0
    if { $mode == 1 } {
	set filtered 1
    }
    set scale_scal [ $parcutil CreateScalarValues $metrics_matrix 2 $filtered $spherepower ]

    for { set i 0 } { $i<=3 } { incr i } {

	if { $i !=2 } {
	    set scal  [ $parcutil CreateScalarValues $metrics_matrix $i $filtered $spherepower ]
	} else {
	    set scal $scale_scal
	}

	if { $np < 100 } {
	    set sur  [ $parcutil CreateBlobSurface $indexsur $scale_scal $scal $metrics_matrix $lkup($i) $spherescale $i $filtered ]
	} else {
	    set sur [ $parcutil ColorSurface $parsurface $lkup($i) $scal $metrics_matrix $i  $filtered ]
	}

	set filter [ vtkPolyDataNormals New ]
	$filter SetInput $sur
	$filter SetFeatureAngle 30.0
    	$filter SplittingOff
	$filter Update
    
	set name [ lindex $lst $i ]
	[ $OutputsArray(${name}) GetObject ] DeepCopySurface [ $filter GetOutput ]
	$filter Delete
    	$sur Delete
	if { $i !=2 } {
	    $scal Delete
	}
	$lkup($i) Delete
    }
    $scale_scal Delete

#    set cm [ $OptionsArray(colorimage) GetValue ]
#    set pimg [ [ $this GetInputObject parimage ] GetImage ]
#    set dim [ $pimg GetDimensions ]
#    if { $cm  > 0 && [ lindex $dim 0 ] > 16 } {
#	puts stdout "Coloring Image"
#    }

    # -------------------------------------------------------------------------------------------
    # Cleanup
    # -------------------------------------------------------------------------------------------
    $parcutil Delete

    if { [ $OptionsArray(guiautosave) GetValue ] > 0 } {
	$this SaveObjects 
	puts stdout $resultmessage
    }

    return 1
}
# ----------------------------------------------------------------------------------------
 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function
    

    set alg [bis_matvis3d [pxvtable::vnewobj]]
    $alg MainFunction 
}

