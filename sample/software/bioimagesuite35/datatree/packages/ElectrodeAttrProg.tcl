#!/bin/sh
# the next line restarts using wish \
    exec wish "$0" "$@"

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

#Now we have access to tk from within this script


package provide ElectrodeAttrProg 1.0

#Add to the auto path the bioimagesuite dirs base and main
lappend auto_path [file dirname [info script]]
package require pxitclchellypackages

# Require key packages
package require Itcl
package require Iwidgets
package require VisTree2

# Xenios' C++ Extensions
package require vtkpxcontrib     1.0

# Simple Naming package  [ pxvtable::vnewobj ]
package require pxvtable         1.0

::itcl::class ElectrodeAttr {

    public variable IsSolo 0
    public variable basewidget 0
    public variable mf 0
    public variable chckbttns 0
    public variable ElectrodeEntryBox 0
    public variable ImageEntryBox 0
    public variable ElectAttrBGColor 
    public variable mainGUIObject 0
         
    private variable pxitclElectrodeObj -1
    private variable ImgObjForOverlay -1
    private variable AttributeList -1
    private variable AttributeSelectionArray -1
    
    public variable OutputImage -1

    constructor { args } {

    }

    public method Initialize { widget electrodecontrol mainGUI }
    public method ShowTop { }
    public method SetElectrodeObject { obj imgobj {AttrNameList -1} {display -1}}
    public method ShowAttributesOnImage { }
    public method GetOutputImage { } { return $OutputImage }
    public method SendOutputToTree { }

}

::itcl::body ElectrodeAttr::Initialize { widget electrodecontrol mainGUI } {
    
    set mainGUIObject $mainGUI
    set ElectAttrBGColor "DarkGreen"
    set basewidget [ toplevel $widget -bg $ElectAttrBGColor -padx 10 -pady 10 ]

    wm title $basewidget "Electrode Attribute Selection Tool"
    wm geometry $basewidget 425x350+100+50
    
    #The main frame of the dialog
    set mf [labelframe $basewidget.mainframe -text "Available Attributes" -bg $ElectAttrBGColor -foreground white -padx 20]
    pack $mf -fill both
    

    #Electrode Filename box---------------------------------------------------------
    set elef [labelframe $basewidget.elecentryframe -text "Electrode File" -bg $ElectAttrBGColor -foreground white -padx 20]
    pack $elef -fill x
    set ElectrodeEntryBox [iwidgets::entryfield $elef.elecentrybox]
    pack $ElectrodeEntryBox -side bottom -fill x 
    #--------------------------------------------------------------------------------

    #Image Filename box--------------------------------------------------------------
    set imgf [labelframe $basewidget.imageentryframe -text "Space Image File" -bg $ElectAttrBGColor -foreground white -padx 20]
    pack $imgf -fill x
    set ImageEntryBox [iwidgets::entryfield $imgf.imgentrybox]
    pack $ImageEntryBox -side bottom -fill x
    #--------------------------------------------------------------------------------

    #Button to create overlay--------------------------------------------------------
    set CreateButton [eval "button $basewidget.[pxvtable::vnewobj] -text \"Create Electrode Overlay Image!\" -command {$this ShowAttributesOnImage; $this SendOutputToTree }"]
    pack $CreateButton -side bottom
    #--------------------------------------------------------------------------------
    
    eval "wm protocol $basewidget WM_DELETE_WINDOW { wm withdraw $basewidget }"
    wm withdraw $basewidget

    
}

::itcl::body ElectrodeAttr::ShowTop { } {

    if { $basewidget == 0 } { 
	return 
    }
    
    
    if { [ winfo ismapped $basewidget ] == 1 } {
	raise $basewidget
	return $basewidget
    }
    
    wm deiconify $basewidget
    
    return $basewidget
    

}

::itcl::body ElectrodeAttr::SetElectrodeObject { obj imgobj {AttrNameList -1} {display -1}} {

    

    set  pxitclElectrodeObj $obj
    set  ImgObjForOverlay     $imgobj
    set  AttributeList      $AttrNameList

    #Clear the Attribute Selection Array
    catch { unset AttributeSelectionArray } 

    #Remove all previous buttons (and error label, if present)
    foreach bttn $chckbttns { 
	catch { destroy $bttn }
    }
    catch { destroy $mf.noattributeslabel }

    set chckbttns ""
 
    if {$AttrNameList != -1} {
	foreach name $AttributeList {
	    set AttributeSelectionArray($name) 1
	    lappend chckbttns [checkbutton $mf.$name -text $name -variable [itcl::scope AttributeSelectionArray($name)] -bg $ElectAttrBGColor -activebackground "dark sea green" -foreground white -activeforeground white]
	    pack $mf.$name 
	}
    } else {
	label $mf.noattributeslabel -text "No attributes have been loaded for this electrode set" -foreground red -bg $ElectAttrBGColor
	pack $mf.noattributeslabel -padx 20 -pady 20
    }

    $ElectrodeEntryBox clear
    if {$display != -1} {
	$ElectrodeEntryBox insert 0 $display
    }
    $ImageEntryBox clear
    catch {$ImageEntryBox insert 0 [$ImgObjForOverlay cget -filename]}


}; #End SetElectrodeObject


::itcl::body ElectrodeAttr::ShowAttributesOnImage { } {

    set AttrExportList ""
    for {set k 0} {$k < [llength $AttributeList] } {incr k} {
	if {$AttributeSelectionArray([lindex $AttributeList $k]) == 1} {
	    lappend AttrExportList $k
	}
    }

    puts $AttrExportList
    set electrodemultigrid [$pxitclElectrodeObj GetObject]

    set ng [ $electrodemultigrid GetNumberOfGrids ] 
    for { set i 0 } { $i < $ng } { incr i } {
	set grid [ $electrodemultigrid GetElectrodeGrid $i ]
	$grid SetVisible 1
    }
    $grid Update

    set numcomp [ llength $AttrExportList ]
    set arr [ vtkShortArray [ pxvtable::vnewobj ]]
    $arr SetNumberOfTuples $numcomp
    $arr FillComponent 0 0
    for { set i 0 } { $i < $numcomp } { incr i } {
	set md [ lindex $AttrExportList $i ]
	set md [ expr $md + 20 ]
	$arr SetComponent $i 0 $md
	puts stderr "Attribute $i [ $arr GetComponent $i 0 ]"
    }
    
  
    set img [ $electrodemultigrid CreateSinglePixelImage $arr [ $ImgObjForOverlay GetImage ] ]
    
    set imgout [ [pxitclimage \#auto] GetThisPointer ]
    $imgout ShallowCopyImage $img
    $imgout CopyImageHeader [ $ImgObjForOverlay GetImageHeader ]
    $img Delete
    $arr Delete

    set OutputImage $imgout
}

::itcl::body ElectrodeAttr::SendOutputToTree { } {

    $mainGUIObject PutElectrodeAttrControlOutputInTree

}

# ---------------------------------------------------------------------------
# if ElectrodeAttrProg is called from the command line, start it in its own window
if { [ file rootname $argv0 ] == [ file rootname [ info script ] ] } {
    
    set thisAttrControl [ElectrodeAttr \#auto]
    wm withdraw .
    
    $thisAttrControl configure -IsSolo 1
    $thisAttrControl Initialize .[pxvtable::vnewobj]
    $thisAttrControl ShowTop
    
}



