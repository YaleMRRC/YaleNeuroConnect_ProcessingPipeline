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

package provide bis_spectrf 1.0
package require bis_imagetoimagealgorithm 1.0
package require bis_imagemathoperations 1.0
package require bis_shiftscaleimage 1.0
package require bis_thresholdimage      1.0

itcl::class bis_spectrf {

    inherit bis_imagetoimagealgorithm

    constructor { } {	 $this Initialize  }
    
    public method WriteOutput   { fname outputList } 
    public method Initialize    { }
    public method Execute       { }
    public method GetGUIName    { } { return "Calculate RF" }
}

# -----------------------------------------------------------------------------------------
# Initialize
# ----------------------------------------------------------------------------------------

itcl::body bis_spectrf::Initialize { } {

    PrintDebug "bis_spectrf::Initialize" 
    
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    set options {
	{ savefile "Generate and save an output text file" "Save results to text file" boolean 0 { 0 1 } 20 }
	{ filename   "specify the filname for the output text file" "Text File Name" { filename writefile } "spectrf_result.txt" { text { .txt } } 30 }
	{ mode "Perform Hyperperfusion or Hypoperfusion statistics" "Mode"  { listofvalues radiobuttons } hyper { hyper hypo } 0 }
	{ sig  "P-value Signigicance level threshold" "Significance"        real 0.01 { 0.00000000000000001 1 }  0 }
	{ ext  "Minimum cluster size used for analysis" "Extent Threshold"  real 125  { 1  1000000 }             1 }

    }

    set scriptname bis_spectrf
    set completionstatus "Done"

    #
    #document
    #
    set category "DiffSPECT"
    set description "Computes Statistics for DIFF Spect Analysis"
    set description2 ""
    set backwardcompatibility ""

    set author "dustin.scheinost@yale.edu"

    $this InitializeImageToImageAlgorithm
}

# -----------------------------------------------------------------------------------------
# Execute
# ----------------------------------------------------------------------------------------

itcl::body bis_spectrf::WriteOutput { fname outputList } {

    set fileid [ open $fname w ]
    puts $fileid "\n#Vxs\tuncorrPvalue \tcorrPvalue \tmaxTscore \tX \tY \tZ"
    for { set index1 1 } { $index1 <= [ llength $outputList ] } { incr index1 } {
	set out ""
	for { set index2 0 } { $index2 < 7 } { incr index2 } {
	    set out  "$out[ lindex [ lindex $outputList [ expr $index1 - 1 ] ] $index2 ]\t" 
	}
	puts $fileid $out
	}
    close $fileid
}

itcl::body bis_spectrf::Execute {  } {
    
    PrintDebug "bis_spectrf::Execute"

    set tmap   [ $this GetInput ]
    set extThr [ $OptionsArray(ext)      GetValue ]
    set sigThr [ $OptionsArray(sig)      GetValue ] 
    set mode   [ $OptionsArray(mode)     GetValue ]
    set save   [ $OptionsArray(savefile) GetValue ]
    set fname  [ $OptionsArray(filename) GetValue ]

    #convert p to t
    set Pvalue [ vtkpxMath [ pxvtable::vnewobj ] ]
    set tscore [ $Pvalue PvalueToTvalue [ expr $sigThr * 2 ] 14 ]

    $Pvalue Delete
 
    #calculating euler density
    set tmp [ expr pow(1+$tscore*$tscore/13,-6) ]
    set eulerDensity(0) $sigThr
    set eulerDensity(1) [ expr 0.2650*$tmp ]
    set eulerDensity(2) [ expr 0.1727*$tscore*$tmp ] 
    set eulerDensity(3) [ expr 0.1169*$tmp*(12*$tscore*$tscore/13-1) ]
    set expectedVoxPerCluster [ expr $eulerDensity(0) / $eulerDensity(3) ]  

    #calculate resel count
    set util [ vtkdsSpectUtil [ pxvtable::vnewobj ] ]
    set expectedNumOfCluster [ $util reselCount [ $tmap GetObject ] $eulerDensity(0) $eulerDensity(1) $eulerDensity(2) $eulerDensity(3) ]
  
    set clusterThreshold [ vtknrImageCluster [ pxvtable::vnewobj ] ]
    $clusterThreshold SetInput [ $tmap GetObject ]
    $clusterThreshold SetIntensityThreshold $tscore
    SetFilterCallbacks $clusterThreshold "Clustering image"
    $clusterThreshold Update

    if  { $mode == "hypo" } {
	set math [ bis_shiftscaleimage [ pxvtable::vnewobj ] ]
	$math InitializeFromContainer $this
	$math SetInput $tmap
	$math SetOptionValue scale -1.0
	$math Execute
	set tmap2 [ $math GetOutput ]
    }  else { 
	set tmap2 $tmap 
    }

    #new way
    set clusterInfo [ $util ClusterImage [ $tmap2 GetObject ] [ $clusterThreshold GetClusterNumberImage ]\
			  [ $clusterThreshold GetOutput ] $expectedVoxPerCluster $expectedNumOfCluster $tscore $extThr ]

    set numComponents [ $clusterInfo GetNumberOfComponents ]
    set numTuples [ $clusterInfo GetNumberOfTuples ]
    set outputList [ list ]

    if { $numTuples < 1 } {
	puts "No significant clusters found"
	return 2
    }

    #Note: for some reason tuple and compoments labeling gets switch
    #numComponents is actually the number of tuples in the out image
    #and vice versa for the numTuples
    set img [ vtkImageData [ pxvtable::vnewobj ] ]
    $img SetDimensions $numComponents 1 1
    $img SetWholeExtent 0 [ expr $numComponents - 1 ] 0 0 0 0
    $img SetNumberOfScalarComponents $numTuples
    $img SetScalarTypeToFloat 
    $img AllocateScalars
    
    for { set tupleCount 0 } { $tupleCount<$numTuples } { incr tupleCount } {
	set tempList [ list ]
	for { set compCount 0 } { $compCount<$numComponents } { incr compCount } {	  
	    $img SetScalarComponentFromFloat $compCount 0 0 $tupleCount [ $clusterInfo GetComponent $tupleCount $compCount ]
	    lappend tempList [ $clusterInfo GetComponent $tupleCount $compCount ]
	    puts "for $tupleCount $compCount the value is [ $clusterInfo GetComponent $tupleCount $compCount ]"
	}
	lappend outputList $tempList
    }
    set outputList [ lsort -increasing -index 1 -real $outputList ]

    if { $save } { 
	$this WriteOutput $fname $outputList 
    }

    set outimage [ $OutputsArray(output_image) GetObject ]
    $outimage ShallowCopyImage $img    

    $util Delete
    $img Delete
    catch { itcl::delete object $math }
    return 1 ; # return 0 for error, 1 to save object, 2 to not save object
}

# -----------------------------------------------------------------------------------------
#  This checks if executable is called (in this case bis_spectrf.tcl) if it is execute
# ----------------------------------------------------------------------------------------

 
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    # this is essentially the main function

    set alg [bis_spectrf [pxvtable::vnewobj]]
    $alg MainFunction 
}





