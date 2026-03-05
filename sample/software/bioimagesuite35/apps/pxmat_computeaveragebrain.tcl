#!/bin/sh
# the next line restarts using wish \
    exec vtk "$0" "$@"

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




# ------------------------------------------------------------------------------------------

proc MakeDirectory { } {
    global outputdirectory

    if { [ file exists $outputdirectory ] == 0 } {
	file mkdir $outputdirectory
    }

}

# ------------------------------------------------------------------------------------------

proc ComputeAverageTransformations { xformlist refimg namestem debugmode } {

    set numxforms [ llength $xformlist ]
    puts stdout "$numxforms transformations"
    
    set ana [ vtkpxAnalyzeImageSource [ pxvtable::vnewobj ]]
    $ana Load $refimg

    scan [ [ $ana GetOutput ] GetDimensions ] "%d %d %d" dim(0) dim(1) dim(2)
    scan [ [ $ana GetOutput ] GetSpacing ] "%f %f %f" spa(0) spa(1) spa(2)
    scan [ [ $ana GetOutput ] GetOrigin ] "%f %f %f" ori(0) ori(1) ori(2)

    puts stdout "Loaded Image $refimg (dim = $dim(0)x$dim(1)x$dim(2), sp=$spa(0)x$spa(1)x$spa(2), origin=$ori(0),$ori(1),$ori(2))"


    set average     [ vtkpxAverageImages [ pxvtable::vnewobj ]]
    set averagejac  [ vtkpxAverageImages [ pxvtable::vnewobj ]]


    $average SetMedian 0;     $average SetSumOnly 0
    $averagejac SetMedian 0;  $averagejac SetSumOnly 0


    set reg [ vtkpxRegistration  [ pxvtable::vnewobj ]]
    set factor 2.0

    for { set i 0 } { $i < $numxforms } { incr i } {
	
	set m [ lindex $xformlist $i ]
	set combo [ vtkpxComboTransform  [ pxvtable::vnewobj ]]
	$combo Load $m
	[ $combo GetLinearTransform  ] Identity
	puts stdout "\n ********* Loaded [ expr $i+1 ] $m [ file size $m ]"

	set jac_1($i) [ vtkImageData [ pxvtable::vnewobj ] ]
	    
	if { $debugmode > 0 } {
	    puts stdout "Computing Grid and Jacobian for [ file tail $m ] \t [ file size $m ]"
	    $reg ComputeJacobianImage [ $ana GetOutput ] $jac_1($i) $combo 0.01 100.0
	} else {
	    puts stdout "Computing Grid Only for [ file tail $m ] \t [ file size $m ]"
	}

	set tgrid [ vtkTransformToGrid  [ pxvtable::vnewobj ]]
	$tgrid SetGridExtent 0 [ expr round($dim(0)/$factor) - 1 ] 0 [ expr round($dim(1)/$factor) -1 ] 0 [ expr round($dim(2)/$factor) -1 ]
	$tgrid SetGridOrigin  $ori(0) $ori(1) $ori(2)
	$tgrid SetGridSpacing [ expr $factor*$spa(0)] [ expr $factor*$spa(1)] [ expr $factor*$spa(2) ]
	$tgrid SetInput $combo
	$tgrid Update
	
	set img($i) [ vtkImageData [ pxvtable::vnewobj ] ]
	$img($i) ShallowCopy [ $tgrid GetOutput ]
	
	
	$average AddInput $img($i)
	if { $debugmode > 0 } {
	    $averagejac AddInput $jac_1($i)
	}
	
	$tgrid Delete
	$combo Delete
    }
	
    $average Update
    if { $debugmode > 0 } {
	$averagejac Update
    }

    set cast [ vtkImageCast [ pxvtable::vnewobj ]]
    $cast SetInput [ $average GetOutput ]
    $cast SetOutputScalarTypeToDouble
    $cast Update

    if { $debugmode > 0 } {
	set anaw [ vtkpxAnalyzeImageWriter [ pxvtable::vnewobj ]]
	$anaw SetInput [ $averagejac GetOutput ]
	$anaw SetOrientation [ $ana GetOrientation ]
	$anaw Save "${namestem}_averagejacobian1"
	puts stderr "Average Jacobian Map Saved in ${namestem}_averagejacobian1.hdr"
	$anaw Delete
    }

    set tr [ vtkpxGridTransform [ pxvtable::vnewobj ]]
    $tr SetDisplacementGrid [ $average GetOutput ]
    $tr SetInterpolationModeToLinear

    if { $debugmode > 0 } {
	$tr Save "${namestem}_average.grd" 9
	puts stderr "Average Transformation Saved in ${namestem}_average.grd.gz"
    }

    puts stderr "Computing Inverse Transformation ... this will take a while\n"
    set trg [ vtkGridTransform [ pxvtable::vnewobj ] ]
    $trg SetDisplacementGrid [ $cast GetOutput ]
    $trg SetInterpolationModeToLinear
    $trg Inverse
    $cast Delete

    set tgrid [ vtkTransformToGrid  [ pxvtable::vnewobj ]]
    $tgrid SetGridExtent 0 [ expr round($dim(0)/$factor) - 1 ] 0 [ expr round($dim(1)/$factor) -1 ] 0 [ expr round($dim(2)/$factor) -1 ]
    $tgrid SetGridOrigin  $ori(0) $ori(1) $ori(2)
    $tgrid SetGridSpacing [ expr $factor*$spa(0)] [ expr $factor*$spa(1)] [ expr $factor*$spa(2) ]
    $tgrid SetInput $trg
    $tgrid Update
    
    set tr2 [ vtkpxGridTransform [ pxvtable::vnewobj ]]
    $tr2 SetDisplacementGrid [ $tgrid GetOutput ]
    $tr2 SetInterpolationModeToLinear
    $tr2 Save "${namestem}_averageinverse.grd" 9

    puts stderr "Average Inverse Transformation Saved in ${namestem}_averageinverse.grd.gz"
    $tgrid Delete


    if { $debugmode > 0 } {
	set gen [ vtkGeneralTransform [ pxvtable::vnewobj ]]    
	$gen PostMultiply
	$gen Concatenate $tr
	$gen Concatenate $tr2
	
	set tgrid [ vtkTransformToGrid [ pxvtable::vnewobj ]]
	$tgrid SetGridExtent 0 [ expr round($dim(0)/$factor) - 1 ] 0 [ expr round($dim(1)/$factor) -1 ] 0 [ expr round($dim(2)/$factor) -1 ]
	$tgrid SetGridOrigin  $ori(0) $ori(1) $ori(2)
	$tgrid SetGridSpacing [ expr $factor*$spa(0)] [ expr $factor*$spa(1)] [ expr $factor*$spa(2) ]
	$tgrid SetInput $gen
	$tgrid DebugOn
	$tgrid Update
	
	set tr3 [ vtkpxGridTransform [ pxvtable::vnewobj ] ]
	$tr3 SetDisplacementGrid [ $tgrid GetOutput ]
	$tr3 SetInterpolationModeToLinear
	$tr3 Save "${namestem}_concat_averageinverse.grd" 9

	puts stderr "Concat Average Inverse+Average Transformation Saved in ${namestem}_concat_averageinverse.grd.gz"
	
	$gen Delete
	$tr3 Delete
	$tgrid Delete
    }
	
    for { set i 0 } { $i < $numxforms } { incr i } {
	$img($i) Delete
	$jac_1($i) Delete
    }

    $ana Delete
    $average Delete
    $averagejac Delete
    $reg Delete
    $tr Delete
    $trg Delete
    $tr2 Delete
}

# ------------------------------------------------------------------------------------------

proc TestAverageTransformation { xformlist refimg namestem } {

    set numxforms [ llength $xformlist ]
    puts stdout "$numxforms transformations"
    
    set ana [ vtkpxAnalyzeImageSource [ pxvtable::vnewobj ]]
    $ana Load $refimg

    scan [ [ $ana GetOutput ] GetDimensions ] "%d %d %d" dim(0) dim(1) dim(2)
    scan [ [ $ana GetOutput ] GetSpacing ] "%f %f %f" spa(0) spa(1) spa(2)
    scan [ [ $ana GetOutput ] GetOrigin ] "%f %f %f" ori(0) ori(1) ori(2)

    puts stdout "Loaded Image $refimg (dim = $dim(0)x$dim(1)x$dim(2), sp=$spa(0)x$spa(1)x$spa(2), origin=$ori(0),$ori(1),$ori(2))"

    set tr2 [ vtkpxGridTransform [ pxvtable::vnewobj ]]
    set ok [ $tr2 Load "${namestem}_averageinverse.grd" ]
    puts stderr "Average Inverse Transform Loaded from ${namestem}_averageinverse.grd (status = $ok) "
    if { $ok == 0 } {
	$ana Delete
	$tr2 Delete
	puts stderr "Bad Transformation filename exiting\n"
	exit
    }

    set averagejac2 [ vtkpxAverageImages [ pxvtable::vnewobj ]]
    $averagejac2 SetMedian 0; $averagejac2 SetSumOnly 0

    for { set i 0 } { $i < $numxforms } { incr i } {
	
	set m [ lindex $xformlist $i ]
	set combo [ vtkpxComboTransform [ pxvtable::vnewobj ]]
	puts stdout "Computing Combo Jacobian for [ file tail $m ] \t [ file size $m ]"
	$combo Load $m
	
	set jac_2($i) [ vtkImageData [ pxvtable::vnewobj ]] 

	set gen [ vtkGeneralTransform [ pxvtable::vnewobj ]]
	$gen PostMultiply
	$gen Concatenate $combo
	$gen Concatenate $tr2
	$reg ComputeJacobianImage [ $ana GetOutput ] $jac_2($i) gen 0.01 100.0
	$gen Delete

	$averagejac2 AddInput $jac_2($i)
	$combo Delete
    }

    $averagejac2 Update

    set anaw2 [ vtkpxAnalyzeImageWriter [ pxvtable::vnewobj ]]
    $anaw2 SetInput [ $averagejac2 GetOutput ]
    $anaw2 SetOrientation [ $ana GetOrientation ]
    $anaw2 Save "averagejacobian2"
    $anaw2 Delete


    for { set i 0 } { $i < $numxforms } { incr i } { 
	$jac_2($i) Delete
    }
    $averagejac2 Delete
    $tr2 Delete
    $ana Delete
}
# --------------------------------------------------------------------------------------------------------
proc TestImages {  } {

    global refimg
    global transformlist
    
    puts stdout "Testing for existence of images/transformations"

    
    for { set i 0 } { $i < [ llength $transformlist ] } { incr i } {
	
	set a [ lindex $transformlist $i ]
	set index [ format "%3d" [ expr $i +1 ] ]
	set ok1 [ file exists $a ] ;   set sz1 -1 ; catch { set sz1 [ file size $a ] }
	
	if { $ok1 > 0 } {
	    puts stdout "\t$index  $a ($sz1)  ok"
	} else {
	    puts stdout "\n*********** Missing Transform $a ($sz1)"
	    exit
	}

	set refimgname [ lindex $refimg 0 ]
	set a $refimgname
	set b "[ file root $refimgname ].img"
	set ok1 [ file exists $a ] ;   set sz1 -1 ; catch { set sz1 [ file size $a ] }
	set ok2 [ file exists $b ] ;   set sz2 -1 ; catch { set sz2 [ file size $b ] }
	
	if { $ok1 > 0 && $ok2 > 0 } {
	    puts stdout "\tSingle Ref image  $a,[file tail $b ] ($sz1,$sz2)  ok"
	} else {
	    puts stdout "\n*********** Missing Image $a,$b ($sz1,$sz2)"
	    exit
	}
    }
}




# ------------------------------------------------------------------------------------------

proc ComputeAverageBrain { refimg namestem forcemni } {

    set linear 0
    set ana2   0

    set ana [ vtkpxAnalyzeImageSource [ pxvtable::vnewobj ]]
    $ana Load $refimg

    scan [ [ $ana GetOutput ] GetDimensions ] "%d %d %d" dim(0) dim(1) dim(2)
    scan [ [ $ana GetOutput ] GetSpacing ] "%f %f %f" spa(0) spa(1) spa(2)
    scan [ [ $ana GetOutput ] GetOrigin ] "%f %f %f" ori(0) ori(1) ori(2)

    puts stdout "Loaded Image $refimg (dim = $dim(0)x$dim(1)x$dim(2), sp=$spa(0)x$spa(1)x$spa(2), origin=$ori(0),$ori(1),$ori(2))"

    set tr2 [ vtkpxGridTransform [ pxvtable::vnewobj ]]
    set ok [ $tr2 Load "${namestem}_averageinverse.grd" ]
    puts stderr "Average Inverse Transform Loaded from ${namestem}_averageinverse.grd (status = $ok) "
    if { $ok == 0 } {
	$ana Delete
	$tr2 Delete
	puts stderr "Bad Transformation filename exiting\n"
	exit
    }


    if { $forcemni } {
	# Register the refimg to mni and get a transformation .....
	# set 
	set dirname [ file dirname [ info script ] ]
	set mnifilename [ file join $dirname [ file join ".." [ file join images "mni_305.hdr" ] ] ]
	puts stderr "mnifilename = $mnifilename "
	puts stderr "target = $refimg "
	
	puts stderr "exec  pxmat_register.tcl $mnifilename $refimg ${namestem}_tomni.matr 1 1.25 > ${namestem}_tomni.log 2>&1"
	exec  pxmat_register.tcl $mnifilename $refimg ${namestem}_tomni.matr 1 1.25 > ${namestem}_tomni.log 2>&1
	set ut [ vtkpxTransformationUtil [ pxvtable::vnewobj ] ]

	set linear [ $ut LoadAbstractTransform  ${namestem}_tomni.matr ]
	$ut Delete

	set ana2 [ vtkpxAnalyzeImageSource [ pxvtable::vnewobj ]]
	$ana2 Load $mnifilename

	scan [ [ $ana2 GetOutput ] GetDimensions ] "%d %d %d" dim(0) dim(1) dim(2)
	scan [ [ $ana2 GetOutput ] GetSpacing ] "%f %f %f" spa(0) spa(1) spa(2)
	scan [ [ $ana2 GetOutput ] GetOrigin ] "%f %f %f" ori(0) ori(1) ori(2)

	puts stdout "Loaded Image $mnifilename (dim = $dim(0)x$dim(1)x$dim(2), sp=$spa(0)x$spa(1)x$spa(2), origin=$ori(0),$ori(1),$ori(2))"
    }

    set gen [ vtkGeneralTransform [ pxvtable::vnewobj ]]
    $gen PostMultiply
    if { $linear !=0 } {
	puts stderr "Concatenating linear to map to mni space"
	$gen Concatenate $linear
    }
    $gen Concatenate $tr2

    set resl [ vtkbisImageReslice [ pxvtable::vnewobj ]]
    $resl SetInput [ $ana GetOutput ]
    if { $ana2 != 0 } {
	$resl SetInformationInput [ $ana2 GetOutput ]
    } else {
	$resl SetInformationInput [ $ana GetOutput ]
    }
    $resl SetInterpolationMode 1
    $resl SetBackgroundLevel 0.0
    $resl OptimizationOff
    $resl SetResliceTransform $gen
    $resl Update
    
    set anaw [ vtkpxAnalyzeImageWriter [ pxvtable::vnewobj ]]
    $anaw SetInput [ $resl GetOutput ]
    if { $ana2 !=0 } {
	$anaw SetImageHeader [ $ana2 GetImageHeader ]
    } else {
	$anaw SetImageHeader [ $ana1 GetImageHeader ]
    }

    set outname "${namestem}_averagebrain"
    $anaw Save $outname
    
    puts stdout "Average Saved in $outname, dimensions [ [ $resl GetOutput ] GetDimensions ]"
 

    $resl Delete
    $ana  Delete
    $anaw Delete
    $gen  Delete
    $tr2  Delete

    if { $linear !=0 } {
	$linear Delete
	$ana2 Delete
    }
    
}

# ------------------------------------------------------------------------------------------
#  Main Program is Here
# ------------------------------------------------------------------------------------------
set argc [llength $argv]
if { $argc < 2 } {
    puts stderr "Usage  pxmat_computeaveragebrain.tcl setup_file output_directory \[ go\]"
    puts stderr " if the word go is missing the program simply tests for the presence of all the images"
    puts stderr "\n type pxmat_computeaveragebrain.tcl > sample.setup "
    puts stderr " \t to generate a sample setup file\n"

    puts stdout "\#Example Setup File\n\# all lines beginning with \# are ignored \n\#"
    puts stdout "\#\n\#\n\# List all subjects here\n\#"
    puts stdout "set transformlist \{"
    puts stdout "   /usr/home/schultz/brain_reg/brains/1001/sag.cihte.grd"
    puts stdout "   /usr/home/schultz/brain_reg/brains/1002/sag.cihte.lw.grd"
    puts stdout "\}\n\#"
    puts stdout "\#\n\#\n\# Put reference brain here\n\#"
    puts stdout "set refimg  /home/papad/normalized/1115_normalized.hdr\n\#"
    puts stdout "\#\n\#\n\# Put the name stem\n\#"
    puts stdout "set namestem normals"
    puts stdout "\#\n\#\n\# Set this to 1 to do some checking via computing jacobians"
    puts stdout "set debugmode 0"
    puts stdout "\#\n\#\n\# Set this to 1 to skip recomputing the average inverse transform"
    puts stdout "set haveaverageinversetransform 0"
    puts stdout "\#\n\#\n\# Set this to 0 to skip computing  an average brain image"
    puts stdout "set computenewaveragebrain 1"
    puts stdout "\#\n\#\n\# Set this to 1 to force the new average brain image to be in MNI space (recommended)\n\#"
    puts stdout "set maptomni 1"
    exit
}

# --------------------------------------------------------------------------

lappend auto_path [ file dirname [ info script ]]; package require pxappscommon

set outputdirectory [ lindex $argv 1 ]
set inputfile [ file tail [ file root [ lindex $argv 0 ]]]

set transformlist ""
set refimg  ""
set namestem "normals"
set debugmode 0
set haveaverageinversetransform 1
set computenewaveragebrain 1
set maptomni 1

source [ lindex $argv 0 ]

# --------------------------------------------------------------------------

TestImages 

if { [ llength $argv ] < 3 } {
    exit
}

set namestem [ file join $outputdirectory $namestem ]

MakeDirectory

if { $haveaverageinversetransform < 1 }  {
    ComputeAverageTransformations $transformlist $refimg $namestem $debugmode
    
    if { $debugmode == 1 } {
	TestAverageTransformation     $transformlist $refimg $namestem 
    }
} else {
    puts stderr "\n\n Not Recomputing Average Transformation\n"
}

if { $computenewaveragebrain > 0 } {
    ComputeAverageBrain $refimg $namestem $maptomni
}

exit

