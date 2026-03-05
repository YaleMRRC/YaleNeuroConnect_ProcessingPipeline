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

package provide feedbackplus 1.0
package require Iwidgets

# Derives from iwidgets::feedback

# ------------------------------------------------------------------
#                          FEEDBACKPLUS
# ------------------------------------------------------------------
option add *Feedbackplus.borderWidth	2		widgetDefault
option add *Feedbackplus.labelPos		n		widgetDefault
option add *Feedbackplus.barHeight		20		widgetDefault
option add *Feedbackplus.troughColor	White		widgetDefault
option add *Feedbackplus.barColor		Blue	        widgetDefault

#
# Usual options.
#
itk::usual Feedbackplus {
    keep -background -cursor -foreground
}

# ------------------------------------------------------------------
#                          FEEDBACKPLUS
# ------------------------------------------------------------------
itcl::class iwidgets::Feedbackplus {
    inherit iwidgets::Feedback

    constructor {args} {}
    destructor {}

    public {
	method setval { val }
    }

    private {
	method _display
	variable _barwidth 0
	variable _stepval 0
    }

}

#
# Provide a lowercased access method for the Dialogshell class.
# 
proc ::iwidgets::feedbackplus {pathName args} {
    uplevel ::iwidgets::Feedbackplus $pathName $args
}

# ------------------------------------------------------------------
#                        CONSTRUCTOR
# ------------------------------------------------------------------
itcl::body iwidgets::Feedbackplus::constructor {args} {

    pack $itk_component(bar) -side left -padx 2 -pady 0
    pack $itk_component(percentage) -side right -padx 2 -pady 0
    pack $itk_component(trough) -side left -fill both -expand true  -pady 0
    bind $itk_component(hull) <Configure> [itcl::code $this _display]
    eval itk_initialize $args
}

# -----------------------------------------------------------------------------
# PROTECTED METHOD: _display 
#
# Displays the bar in the trough with the width set using the current number
# of steps.
# -----------------------------------------------------------------------------
itcl::body iwidgets::Feedbackplus::_display {} {
    update idletasks
    set troughwidth [winfo width $itk_component(trough)]
    set _barwidth [expr {
      (1.0*$troughwidth-(2.0*[$itk_component(trough) cget -borderwidth])) /
      $itk_option(-steps)}]
    set fraction [expr {int((1.0*$_stepval)/$itk_option(-steps)*100.0)}]

    $itk_component(percentage) config -text "$fraction%"
    $itk_component(bar) config -width [expr {$_barwidth*$_stepval}]

    update
}

# ------------------------------------------------------------------

# ------------------------------------------------------------------
#                          DESTRUCTOR
# ------------------------------------------------------------------
itcl::body iwidgets::Feedbackplus::destructor {} {
}


itcl::body iwidgets::Feedbackplus::setval { val } {

    set _stepval $val
    if { $_stepval < 0 } {
	set _stepval 0
    } elseif {$_stepval >= $itk_option(-steps)} {
	set _stepval $itk_option(-steps)
    }
    _display 
}

