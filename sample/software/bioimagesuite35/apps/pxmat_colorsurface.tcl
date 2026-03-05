#!/bin/sh
# the next line restarts using wish \
    exec vtk "$0" "$@"


#BIOIMAGESUITE_LICENSE  ---------------------------------------------------------------------------------
#BIOIMAGESUITE_LICENSE  This file is part of the BioImage Suite Software Package.
#BIOIMAGESUITE_LICENSE  
#BIOIMAGESUITE_LICENSE  X. Papademetris, M. Jackowski, N. Rajeevan, R.T. Constable, and L.H
#BIOIMAGESUITE_LICENSE  Staib. BioImage Suite: An integrated medical image analysis suite, Section
#BIOIMAGESUITE_LICENSE  of Bioimaging Sciences, Dept. of Diagnostic Radiology, Yale School of
#BIOIMAGESUITE_LICENSE  Medicine, http://www.bioimagesuite.org.
#BIOIMAGESUITE_LICENSE  
#BIOIMAGESUITE_LICENSE  All rights reserved. This file may not be edited/copied/redistributed
#BIOIMAGESUITE_LICENSE  without the explicit permission of the authors.
#BIOIMAGESUITE_LICENSE  
#BIOIMAGESUITE_LICENSE  -----------------------------------------------------------------------------------


if { $argc < 2 } {
    puts stdout "\n\n"
    puts stdout "$argv0 input_surface output_surface \[ colormap=0 \] \[ valuesfilematrix=0 \] \[ valuescolumn=0 \] \[ rangemin=-1 \] \[ rangemax=-2 \]"

    puts stdout "\t First argument is the input surface"
    puts stdout "\t Second argument is the output surface"
    puts stdout "****** The rest of the arguments are optional (but you need at least one non-zero for anything to happen)\n"
    puts stdout "\t\t The 3rd argument is the colormap used for the surface"
    puts stdout "\t\t The 4th argument is a matr file with rows=number of labels, columns=1 with the values for the surface"
    puts stdout "\n"
    puts stdout "\t Example\n\t pxmat_colorsurface.tcl parcelation.vtk fixed.vtk colormap.cmap values.matr"
    exit
}

set f [ file join [ file dirname [ info script ]] pxappscommon.tcl ]
if { [ file exists $f  ] } {
    puts stdout "$f exists"
    lappend auto_path [ file dirname [ info script ]];
} else {
    puts stdout "$f does not exist -- sourcing from bioimagesuite32"
    lappend auto_path /data1/software/bioimagesuite35
}
package require pxappscommon


set input    [ lindex $argv 0 ]
set output   [ lindex $argv 1 ]
set lname    [ lindex $argv 2 ] 
set mname ""
catch { set mname    [ lindex $argv 3 ] }

set valcol ""
catch { set valcol    [ lindex $argv 4 ] }
if { $valcol == "" } {
    set valcol 0
}

set rangemin ""
catch { set rangemin    [ lindex $argv 5 ] }
if { $rangemin == "" } {
    set rangemin 0
}

set rangemax ""
catch { set rangemax    [ lindex $argv 6 ] }
if { $rangemax == "" } {
    set rangemax 0
}

proc ColorSurface { input matr colormap valcol rangemin rangemax } {

    set output [ vtkPolyData New ]
    $output DeepCopy $input

    set dat [ [ $input GetPointData ] GetScalars ]


    if { $rangemin > $rangemax } {
	set r [ $odat GetRange ]
	set rangemin [ lindex $r 0 ]
	set rangemax [ lindex $r 1 ]
    } else {
	set r [ list $rangemin $rangemax ]
    }
    $colormap SetTableRange [ lindex $r 0 ] [ lindex $r 1 ]
    puts stdout "Colormap range set to [ lindex $r 0 ]:[ lindex $r 1 ]"
    

    if { $matr !=0 } {
	set numcolors [ $colormap GetNumberOfTableValues ]
puts "$rangemax $rangemin "
	set drange [ expr $rangemax-$rangemin ]
	set odat [ vtkUnsignedCharArray New ]
	$odat SetNumberOfComponents 4
	$odat SetNumberOfTuples [ $dat GetNumberOfTuples ]
	$odat FillComponent 0 0.0
	$odat FillComponent 1 0.0
	$odat FillComponent 2 0.0
	set np [ $dat GetNumberOfTuples ]
	set nrows [ lindex [ $matr GetSize ] 0 ]
	set ncol [ lindex [ $matr GetSize ] 0 ]
	if { $valcol < 0 || $valcol >= $ncol }  {
	    set valcol 0 
	}
	set valcol [ expr int($valcol) ]
	puts stdout "Using column $valcol of matrix"

	for { set i 0 } { $i < $np } { incr i } {
	    set v [ expr int([ $dat GetComponent $i 0 ]) ]

	    if { $v >=0 && $v <= $nrows } {
		set cl [ $matr GetElement $v $valcol ]
puts $drange
		set index [ expr int(0.5+$numcolors*($cl-$rangemin)/$drange) ]
		if { $index < 0 } {
		    set index 0
		} elseif { $index >= $numcolors } {
		    set index [ expr $numcolors -1 ]
		}
		set tv [ $colormap GetTableValue $index ]

		if { $i == 100 || $i == 1000 || $i==22222 } {
		    puts stdout "cl=$cl , index=$index, tv=$tv "
		}

		$odat SetComponent $i 0 [ expr 255*[ lindex $tv 0 ] ]
		$odat SetComponent $i 1 [ expr 255*[ lindex $tv 1 ] ]
		$odat SetComponent $i 2 [ expr 255*[ lindex $tv 2 ] ]
		$odat SetComponent $i 3 255
	    }
	}
	[ $output GetPointData ] SetScalars $odat
    } else {
	set odat [ vtkFloatArray New ]
	$odat SetNumberOfComponents 1
	$odat SetNumberOfTuples [ $dat GetNumberOfTuples ]
	$odat CopyComponent 0 $dat 0
	[ $output GetPointData ] SetScalars $odat
	[ [ $output GetPointData ] GetScalars ] SetLookupTable $colormap
    }

    return $output
}

proc CorrectOpacity { cmap } {
    set n [ $cmap GetNumberOfTableValues ]
    for { set i 0 } { $i< $n } { incr i } {
	set v [ $cmap GetTableValue $i ]
	$cmap SetTableValue $i [ lindex $v 0 ] [ lindex $v 1 ] [ lindex $v 2 ] 1.0
    }
}

set reader [ vtkPolyDataReader New ]
$reader SetFileName $input
$reader Update

set np [ [ $reader  GetOutput ] GetNumberOfPoints ]
if { $np < 10 } {
    puts stderr "Failed to read surface from $input"
    exit
}

set rmax 0
set rmin 0
catch {
    set dt [ [ [ $reader GetOutput ] GetPointData ] GetScalars ]
    set r [ $dt GetRange ]
    set rmin [ lindex $r 0 ]
    set rmax [ lindex $r 1 ]
}

if { $rmax == $rmin } {
    puts stderr "Bad surface, no scalars specified"
    exit
}


if { $lname != "" && $lname !=0 } {
    set lkup [ vtkLookupTable New ]
    set util [ vtkpxColorMapUtil New ]
    set lok  [ $util LoadColormap $lkup $lname ] 
    puts stdout "Read new colormap from $lname $lok"
} else {
    set sutil [ vtkpxSurfaceUtil New ]
    set lok [ $sutil DefaultObjectMapLookupTable $lkup $rmax  0 ]
    puts stdout "Created new colormap from $lname $lok ($rmax colors)"
}

set matr 0
if { $mname !="" } {
    set matr [ vtkpxMatrix New ]
    set ok [ $matr Load $mname ]
    if { $ok > 0 } {
	puts stdout "Loaded matrix from $mname"
    } else {
	$matr Delete
	set matr 0
    }
}

if { $matr == 0 } {
    puts stdout "Just fixing lookup table"
}


CorrectOpacity $lkup
set out [ ColorSurface [ $reader GetOutput ] $matr $lkup $valcol $rangemin $rangemax ] 

set w [ vtkPolyDataWriter New ]
$w SetFileTypeToBinary
$w SetInput $out
$w SetFileName $output
$w Write
puts stdout "Saved output in $output [ file size $output ]"

exit
