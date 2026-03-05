#!/bin/sh
# the next line restarts using wish \
    exec vtk "$0" -- "$@"


lappend auto_path [ file dirname [ info script ]]
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] base]
lappend auto_path [file join [file join [ file dirname [ info script ]] ".." ] apps]

package provide bis_coordinatestoatlas 1.0
package require bis_imagetoimagealgorithm 1.0


itcl::class bis_coordinatestoatlas {

    inherit bis_imagetoimagealgorithm

     constructor { } {	 $this Initialize  }

    public method Initialize { }
    public method Execute { }
    public method GetGUIName    { } { return "TO ATLAS" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_coordinatestoatlas::Initialize { } {

    PrintDebug "bis_coordinatestoatlas::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ coords "Coordinate file in voxels" "Coords"  { filename readfile }  "" { "Coords" { .txt}} 1 }
    }


    set defaultsuffix { "_atlas" }

    $this InitializeImageToImageAlgorithm
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_coordinatestoatlas::Execute {  } {

    PrintDebug "bis_coordinatestoatlas::Execute"

    set fname  [ $OptionsArray(coords) GetValue ]

    if { $fname == "" } {
	set errormessage "Must set setup file to non empty value"
	return 0
    }

    set atlaslist [ list ]

    set image_in    [ $this GetInput ]
    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage DeepCopyImage [ $image_in GetObject ]
    $outimage CopyImageHeader [ $image_in GetImageHeader ]

    set inp [ [ [ $image_in GetObject ] GetPointData ] GetScalars ]
    set out [ [ [ $outimage GetObject ] GetPointData ] GetScalars ]

    $out FillComponent 0 0.0
    
    set nt [ $inp GetNumberOfTuples ]

    set fid [ open $fname r ]
    set count 0
    while { [ gets $fid line ] >= 0 } {

	set vox1  [ lindex $line 0 ]
	set vox2  [ lindex $line 1 ]
	set vox3  [ lindex $line 2 ]

	puts "++ starting point $vox1 $vox2 $vox3"

	#puts [ [ $image_in GetObject ] GetScalarComponentAsDouble 100 100 100 0 ] 
	#set atlas 4
	set atlas [ [ $image_in GetObject ] GetScalarComponentAsDouble $vox1 $vox2 $vox3 0 ] 
	#puts $atlas
	
	if { [ lsearch $atlaslist $atlas ] < 0 } {
	
	    if { $atlas > 0 } {
		for { set j 0 } { $j < $nt } { incr j } {
		    if { [ $inp GetComponent $j 0 ] == $atlas } {
		    $out SetComponent $j 0 [ expr $count + 1 ]
		    }
		}
		incr count
	    } else { 
		puts "!! point $vox1 $vox2 $vox3 is not in the atlas; try a different point" 
	    }
	} else { 
	    puts "!! point $vox1 $vox2 $vox3 is already in atlas; moving on to next point" 
	}
    }

    close $fid

    set comment [ format " [ $this GetCommandLine full ]" ]
    [ $outimage GetImageHeader ] AddComment "$comment $Log" 0

    return 1
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_coordinatestoatlas.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_coordinatestoatlas [pxvtable::vnewobj]]
    $alg MainFunction 
}




