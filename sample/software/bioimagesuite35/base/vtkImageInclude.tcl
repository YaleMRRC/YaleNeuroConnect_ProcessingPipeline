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

package provide vtkImageInclude 1.0

# 	$Id: vtkImageInclude.tcl,v 1.1 2002/02/20 18:07:50 Xenios Exp $	



# This file derives from vthe VTK Source Tree


set VTK_VOID            0
set VTK_BIT             1 
set VTK_CHAR            2
set VTK_UNSIGNED_CHAR   3
set VTK_SHORT           4
set VTK_UNSIGNED_SHORT  5
set VTK_INT             6
set VTK_UNSIGNED_INT    7
set VTK_LONG            8
set VTK_UNSIGNED_LONG   9
set VTK_FLOAT          10
set VTK_DOUBLE         11 

set VTK_IMAGE_X_AXIS             0
set VTK_IMAGE_Y_AXIS             1
set VTK_IMAGE_Z_AXIS             2

set VTK_CLAW_NEAREST_NETWORK      0
set VTK_CLAW_NEAREST_MINIMUM      1
set VTK_CLAW_NEAREST_GLOBAL       2
set VTK_CLAW_PIONEER_LOCAL        3
set VTK_CLAW_PIONEER_GLOBAL       4
set VTK_CLAW_WELL_NOISE           6
set VTK_CLAW_WELL_DIRECTED_NOISE  7
set VTK_CLAW_MINIMUM_WELL         8
set VTK_CLAW_INSERT               9
set VTK_CLAW_NARROW_WEL           10


