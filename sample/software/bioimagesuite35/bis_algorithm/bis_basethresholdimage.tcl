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


package require bis_imagetoimagealgorithm 1.0
package provide bis_basethresholdimage 1.0

# -----------------------------------------------------------------------------------------
# threshold image
#

itcl::class bis_basethresholdimage {

    inherit bis_imagetoimagealgorithm

     constructor { } {     }

    public method InitializeBaseThresholdImage { }
    public method UpdateInputsFromContainer { }

    # returns invalue outvalue replaceinvalue replaceoutvalue dobinary
    protected method ParseArgs { }
}

# -----------------------------------------------------------------------------------------
# InitializeBaseThresholdImage
# ----------------------------------------------------------------------------------------

itcl::body bis_basethresholdimage::InitializeBaseThresholdImage { } {

    PrintDebug "bis_basethresholdimage::InitializeBaseThresholdImage" 
    #commandswitch,description,shortdescription,optiontype,defaultvalue,valuerange,priority
    lappend options [ list  minth "Lower Threshold value" "Low Threshold"   real   0.0 { -100000000.0 100000000.0 }  1 ]
    lappend options [ list  maxth "Upper Threshold value" "High Threshold"  real 100.0 { -100000000.0 100000000.0 }  2 ]
    lappend options [ list  inverse "Inverse Threshold"  "Inverse" { listofvalues radiobuttons } Off  { On Off }  -10  ]
    lappend options [ list binary "Binary Output" "Binary Output"   { listofvalues radiobuttons } Off  { Off On x100 }  6 ]

    set defaultsuffix { "_thr" }
    


    #document
    #
    if { $description == "" } {
	set description "thresholds an image to generate a binary output using a specific threshold."
    }
    if { $description2 == "" } { 
	set description2 "The output is a binary image with value = 100 where the original image had values above the threshold and zero elsewhere."
    }
    set backwardcompatibility "Reimplemented from pxmat_basethresholdimage.tcl"
    

    $this InitializeImageToImageAlgorithm
}

# -----------------------------------------------------------------------------------------
# Update GUI
# -----------------------------------------------------------------------------------------
itcl::body bis_basethresholdimage::UpdateInputsFromContainer { } {

#    puts stderr "In Update Inputs from Container"

    bis_imagetoimagealgorithm::UpdateInputsFromContainer 



    # This happens when image has changed 
    set currentimage  [ $InputsArray(input_image) GetObject ]

#    puts stderr "upd inputs :: Current Image = [ $currentimage GetDescription ]"

    set r [ [ $currentimage GetImage ] GetScalarRange ]
    set rmin [ lindex $r 0 ]
    set rmax [ lindex $r 1 ]
    set rmin [ expr $rmin-1.0 ]
    set rmax [ expr $rmax+1.0 ]

    $OptionsArray(minth) SetValueRange [ list $rmin $rmax ]
    $OptionsArray(maxth) SetValueRange [ list $rmin $rmax ]
    if { [ $OptionsArray(minth) GetValue ] == [ $OptionsArray(minth) GetDefaultValue ] } {
	$OptionsArray(minth) SetValue $rmin
    }

    if { [ $OptionsArray(maxth) GetValue ] == [ $OptionsArray(maxth) GetDefaultValue ] } {
	$OptionsArray(maxth) SetValue $rmax
    }


}


# --------------------------------------------------------------------------------------------

itcl::body bis_basethresholdimage::ParseArgs {  } {
    
#    puts stderr "In Parse Args"
    
    set bm          [ $OptionsArray(binary) GetValue ]
    set scalef 1

    set binarymask 1
    if { $bm == "Off" } {
	set binarymask 0
    } elseif { $bm == "x100" } {
	set scalef 100
    }


    set replaceout 1
    set replacein  0

    if { $binarymask ==1 } {
	set replacein 1
    } 

    set invalue $scalef
    set outvalue 0

    
    if { [ $OptionsArray(inverse) GetValue ] == "On"  } {

	set outvalue $invalue
	set invalue  0
	set tmp $replacein
	set replacein $replaceout
	set replaceout $replacein
	if { $binarymask == 0 } {
	    set replaceout 0
	}
    }
    
    return [ list $invalue $outvalue $replacein $replaceout $binarymask ]
}

 






