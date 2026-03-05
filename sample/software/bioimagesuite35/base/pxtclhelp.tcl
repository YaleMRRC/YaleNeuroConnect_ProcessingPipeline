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

package provide pxtclhelp 1.0




catch { package require labelframe 1.0 }
package require pxvtable 1.0
package require pxtclutil 1.0


# ---------------------------------------------------------------------
# pxtclhelp namespace -- create dialog boxes with scrolled text
# ---------------------------------------------------------------------

namespace eval ::pxtclhelp {

    proc HelpDialog { widgetname } {
	
	frame $widgetname.logoframe  -width 450 
	frame $widgetname.topframe    -width 450 -height 400

	set textbox $widgetname.topframe.textbox 
	set ybar    $widgetname.topframe.ybar 
	set xbar    $widgetname.xbar 

	eval "scrollbar $ybar  -command { $textbox yview } -orient vertical"
	eval "scrollbar $xbar  -command { $textbox xview } -orient horizontal"
	eval "text $textbox  -width 60 -height 10  -wrap word -relief ridge -yscrollcommand { $ybar set} -xscrollcommand {$xbar set}"

	pack $widgetname.logoframe   -side top    -expand false -fill x -padx 0 -pady 0

	pack $xbar -side bottom -expand f -fill x 
	pack $widgetname.topframe -side top -expand true -fill both -padx 0 -pady 5
	pack $ybar -side right -expand false -fill y
	pack $textbox -side left -expand true -fill both


	$textbox configure -state disabled

	wm deiconify $widgetname
	eval "wm protocol $widgetname WM_DELETE_WINDOW { grab release $widgetname ; wm withdraw $widgetname } "
    }

    proc HelpDialogAddText { widgetname texttoadd } {

	set textbox $widgetname.topframe.textbox

	$textbox configure -state normal
	$textbox insert end $texttoadd
	$textbox configure -state disabled

    }

    proc HelpDialogClearText { widgetname } {

	set textbox $widgetname.topframe.textbox
	$textbox configure -state normal
	$textbox delete 1.0 end
	$textbox configure -state disabled
    }

    proc GetLogoFrame { widgetname } {
	return $widgetname.logoframe
    }

    proc GetTextBox { widgetname } {
	return $widgetname.topframe.textbox
    }


}




