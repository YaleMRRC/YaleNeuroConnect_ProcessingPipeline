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

package provide pxitclelectrodemultigrid 1.0

# 	$Id: pxitclelectrodemultigrid.tcl,v 1.2 2003/08/14 17:49:42 xenios Exp xenios $	




package require  pxitclobject  1.0


# -------------------------------------------------------------------
# Definition of pxitclelectrodemultigrid
#
#    a class that encapsulates an image (vtkImageData)
#            its orientation , filename and status
# -------------------------------------------------------------------

itcl::class pxitclelectrodemultigrid {

    inherit pxitclobject

    # --- begin variable def -----

    public variable status 
    protected variable multigrid 

    # --- end of variable def -----

    constructor { } {
	pxitclobject::constructor 
    } {
	CreateNewElectrodeMultiGrid
	UpdateStatus    
    }

    destructor  { $multigrid Delete     }


    # --- begin method def -----
    public method GetObject { } { return $multigrid }
    public method GetType { } { return [ $multigrid GetNumberOfGrids ] }
    public method GetDescription { } 
    public method UpdateStatus { } { set status [ $multigrid GetNumberOfGrids ]  }
    public method Copy   { obj args }
    public method CopyElectrodeMultiGrid   { obj }
    public method Clear { } 
    public method UnLoad { } { return [ Clear ] }

    public method Load   { args }
    public method Save   { args }

    # Methods additional to pxitclobject
    
    public method GetElectrodeMultiGrid { } { return $multigrid }

    public method GetLongDescription { } 
    public method GetShortDescription { } 
    public method GetElectrodeMultiGridSize { } 
    public method GetSize { } { return [ $this GetElectrodeMultiGridSize ] }


    # Extra Stuff for Display
    public method GetGridNamesList { } 
    public method GetDisplayedGridNamesList { }
    public method SetGridNamesToDisplay { lst }
    public method SetLabelGap { gap }
    public method SetJustShowElectrodes { justshow }


    public method CreateNewElectrodeMultiGrid { } 

    # Procedures to Just Set Filename
    public method Browse { description }


    # Procedures to Ship To Viewer and Transform
    public method Display { electrodecontrol }
    public method Transform { gen }



    # --- end method def -----
}

# ------------------- End of Header ---------------------------------
itcl::body pxitclelectrodemultigrid::CreateNewElectrodeMultiGrid { } {

    set multigrid [ vtkpxElectrodeMultiGridSource [ pxvtable::vnewobj ]]
}


itcl::body pxitclelectrodemultigrid::Copy   { obj args } {

    if { [ $obj isa pxitclelectrodemultigrid ] == 0 } {
#	puts stderr "not copying ..."
	return 0
    }

    

    set oldimg [ $obj GetElectrodeMultiGrid ] 
    CopyElectrodeMultiGrid $oldimg 
    set filename    [ $obj cget -filename ]
    UpdateStatus
}
# ----------------------------------------------------------
itcl::body pxitclelectrodemultigrid::CopyElectrodeMultiGrid { newimg  } {

    if { [ $newimg IsA "vtkpxElectrodeMultiGridSource" ] == 0 } {
	puts stdout "Bad Input"
	return
    }

    $multigrid Delete
    set multigrid [ vtkpxElectrodeMultiGridSource [ pxvtable::vnewobj ]]
    $multigrid Copy $newimg
    UpdateStatus
}

# ----------------------------------------------------------
itcl::body pxitclelectrodemultigrid::Clear { } {
    catch { $multigrid Delete }
    CreateNewElectrodeMultiGrid
    set orientation 0
    set filename    ""
    UpdateStatus
}
# ----------------------------------------------------------
itcl::body pxitclelectrodemultigrid::GetElectrodeMultiGridSize { } {

    return [ $multigrid GetNumberOfGrids ]
}

# ----------------------------------------------------------
itcl::body pxitclelectrodemultigrid::GetGridNamesList { }  {
    
    set ng [ $multigrid GetNumberOfGrids ]
    set lst ""

    for { set i 0 } { $i < $ng } { incr i } {
	set grid [ $multigrid GetElectrodeGrid $i ]
	set nm [ $grid GetGridName ]
	set p [ expr $i + 1 ]
	lappend lst "${nm}.${p}"
    }
 #   puts stderr "names list=$lst"
    return $lst
}
# ----------------------------------------------------------
itcl::body pxitclelectrodemultigrid::GetDisplayedGridNamesList { } {
    set ng [ $multigrid GetNumberOfGrids ]
    set lst ""
    for { set i 0 } { $i < $ng } { incr i } {
	set grid [ $multigrid GetElectrodeGrid $i ]
	set nm [ $grid GetGridName ]
	set v [ $grid GetVisible ]
	set p [ expr $i + 1 ]
	if { $v > 0 } {
	    lappend lst "${nm}.${p}"
	}
    }
#    puts stderr "display names list=$lst"
    return $lst
}

itcl::body pxitclelectrodemultigrid::SetGridNamesToDisplay { lst } {

#    puts stderr "lst=$lst"
 
    set ng [ $multigrid GetNumberOfGrids ]
    for { set i 0 } { $i < $ng } { incr i } {
	set vis($i) 0
    }

    for { set i 0 } { $i < [ llength $lst ] } { incr i } {
	set lname [ lindex $lst $i ]
	set v [ file extension $lname ]
	if { [ string length $v ] > 1 } {
	    set ind [ expr  [ string range $v 1 end ] -1 ]
	    if { $ind >= 0 && $ind < $ng } {
		set vis($ind) 1
	    }
	}
    }

    set sum 0

    for { set i 0 } { $i < $ng } { incr i } {
	set grid [ $multigrid GetElectrodeGrid $i ]
	$grid SetVisible $vis($i)
	if { $vis($i) > 0 } {
	    $grid Modified
	    incr sum
	}
    }

 #   puts stderr "Numbers of visible = $sum"
    if { $sum > 0 } {
	$multigrid Modified
    }

}

itcl::body pxitclelectrodemultigrid::SetJustShowElectrodes { justshow } {
    
    set ng [ $multigrid GetNumberOfGrids ]
    for { set i 0 } { $i < $ng } { incr i } {
	set grid [ $multigrid GetElectrodeGrid $i ]
	$grid SetJustShowElectrodes [ expr $justshow > 0 ]
	$grid Modified
    }

}



itcl::body pxitclelectrodemultigrid::SetLabelGap { gap } {
    if { $gap <0 } {
	return 
    }
    $multigrid ShowLabelsGap $gap
    $multigrid Modified
}

# ----------------------------------------------------------
itcl::body pxitclelectrodemultigrid::GetLongDescription { } {
    
    set x1 [ $multigrid GetNumberOfGrids ] 
    
    set line [ format "Number Of Grids %d " $x1 ]

    set line  "name=$this\n\t$line\n\tFilename= $filename"
    return $line
}
# ----------------------------------------------------------
itcl::body pxitclelectrodemultigrid::GetDescription { } {
    
    set x1 [ $multigrid GetNumberOfGrids ] 
    set line [ format "Number Of Grids %d" $x1 ]
    set line  "$line\nFilename=$filename\n"
    return $line
}
# ----------------------------------------------------------
itcl::body pxitclelectrodemultigrid::GetShortDescription { } {
    
    set x1 [ $multigrid GetNumberOfGrids ] 
    set line [ format "Number Of Grids %d" $x1  ]
    set line  "[ file tail $filename]  $line"
    return $line
}
# ----------------------------------------------------------
itcl::body pxitclelectrodemultigrid::Browse { description } {

    set f2path [ file dirname $filename ]
    set f2tail [ file tail    $filename ]
	
    set fname  [tk_getOpenFile -title "Get Filename for $description" -filetypes { {"Electrode Grid Files" {.mgrid}}} -initialfile $f2tail -initialdir $f2path ]   
    if { [ string length $fname ] > 0 } {
	set filename $fname
	return 1
    }
    return 0
}
# ----------------------------------------------------------
itcl::body pxitclelectrodemultigrid::Load { args } {

    set len [ llength $args ]
    if { [ string length $filename ] == 0 && $len == 0 } { return  }


    if { $len < 1 } {
	set fname $filename
    } else  { 
	set fname [ lindex $args 0 ] 
    }

    if { $len > 1 } { 
	set desc [ lindex $args 1 ]
    } else {
	set desc "Electrode Grids"
    }


    if { [ string length $fname ] == 0 } {


	set f2path [ file dirname $filename ]
	set f2tail [ file tail    $filename ]
	set fname  [tk_getOpenFile -title "Load $desc" -filetypes { {"ElectrodeMultiGrid Files" {.mgrid}}} -initialfile $f2tail -initialdir $f2path ]   
    }
    

    if { [ string length $fname ] <1 } {
	return 0
    }

    set ok [ $multigrid Load $fname ]
    if { $ok > 0 } {
	$this configure -filename $fname
    }
}
# ----------------------------------------------------------
itcl::body pxitclelectrodemultigrid::Save { args } {

    set len [ llength $args ]
    if { $len < 1 } {
	set fname $filename
    } else  { 
	set fname [ lindex $args 0 ] 
    }

    set desc "Electrode Grid"
    if { $len > 1 } { 
	set desc [ lindex $args 1 ]
    }


    if { [ string length $fname ] == 0 } {
	set f2path [ file dirname $filename ]
	set f2tail [ file tail    $filename ]
	set fname  [tk_getSaveFile -title "Saving $desc" -filetypes { {"ElectrodeMultiGrid Files" {.mgrid}}} -initialfile $f2tail -initialdir $f2path ]   
    }
    
    if { [ string length $fname ] > 0 } {
	$multigrid Save $fname
	set filename $fname
    }
}
# ----------------------------------------------------------
itcl::body pxitclelectrodemultigrid::Display { electrodecontrol } {

    if { [ $electrodecontrol isa pxitclElectrodeMultiControl ] == 0 } {
	::pxtclutil::Warning "Bad electrodecontrol ($electrodecontrol) Specified. Cannot display landmarks\n"
	return 0
    }
    [ $electrodecontrol GetMultiGrid ] Copy $multigrid
    $electrodecontrol SetLastFilename $filename
    $electrodecontrol DisableElectrodePropertySheet
    $electrodecontrol UpdateInterface
    $electrodecontrol SelectElectrodeGrid 0

    return 1

}

itcl::body pxitclelectrodemultigrid::Transform { gen } {
    
    set ok [ $multigrid ApplyTransformation $gen 1 ]
    return $ok
}

# ----------------------------------------------------------
# electrodemultigridGUI
# ----------------------------------------------------------
itcl::class pxitclelectrodemultigridGUI {

    inherit pxitclobjectGUI

    public variable browsebutton

    constructor { } {
	pxitclobjectGUI::constructor
    } { 
	set thisparam($this,status) ""
	set thisparam($this,shortfilename) "none"
	set thisparam($this,descriptionbox) 0
	Reset
    }

    destructor { }

    public method SetObject { tr } { return [ SetGrid $tr ] }
    public    method GetGrid { } { return $itclobject  }

    protected method CreateNewObject { } 
    public    method Initialize { basewidg } 
    public    method SetGrid { isur }
    public    method BrowseGrid { } 


}
# ----------------------------------------------------------
itcl::body pxitclelectrodemultigridGUI::CreateNewObject { } {
    set itclobject  [ [  pxitclelectrodemultigrid \#auto ] GetThisPointer ]
}

itcl::body pxitclelectrodemultigridGUI::BrowseGrid { } {
    $itclobject Browse $description
    Update
}

itcl::body pxitclelectrodemultigridGUI::SetGrid { trn } {
    
    if { [ $trn isa pxitclelectrodemultigrid ] == 0 } {
	return 0
    }
	
    if { $owns_object == 1} {
	catch { itcl::delete object $itclobject }
    }

    set itclobject $trn
    set owns_object 0
    Update
}

itcl::body pxitclelectrodemultigridGUI::BrowseGrid { } {
    $itclobject Browse $description
    Update
}

itcl::body pxitclelectrodemultigridGUI::Initialize { basewidg } {

    if { $initialized == 1 } { return $basewidget }
    pxitclobjectGUI::Initialize $basewidg

    set browsebutton [ eval "button $buttonbar.b -text Browse -command { $this BrowseGrid }" ]
    pack  $buttonbar.b   -side left -fill x -expand f
    update idletasks

    Update
    return $basewidget
}

