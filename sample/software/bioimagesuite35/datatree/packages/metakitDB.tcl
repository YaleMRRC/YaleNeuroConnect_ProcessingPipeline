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



#------------------------------------------------------------------------------------------
#Meta Kit implementation of the database
#------------------------------------------------------------------------------------------

::itcl::class chellyMetaDBManager {

    inherit chellyDBManager

    public variable dbKey
    
    public method SaveDatatree {} 
    public method LoadDatatree {}

    constructor {_filename _datatreename _tree} {
	set filename $_filename
	set DatatreeName $_datatreename
	set Tree $_tree
	set dbKey db;#This is set to a constant
    }

}

::itcl::body chellyMetaDBManager::SaveDatatree {} {

    #open (or create) a database file named $filename...the key is $db
    mk::file open $dbKey $filename
 
    #clear out the file
    set len [mk::file views]
    if {[llength $len]} {
	foreach i [mk::file views] {
	    mk::view delete $i
	}
    }
    
    #set the view, giving it two spaces, one for the patient name, the other for the whole tree of data
    set vw [mk::view layout $dbKey.data Name ImageTree]
    
    #add a single entry to the view
    mk::row append $vw Name $DatatreeName ImageTree $Tree

    #commit this entry to the file
    mk::file commit $dbKey

    mk::file close $dbKey

}

::itcl::body chellyMetaDBManager::LoadDatatree {} {
    
    #Open the file
    mk::file open $dbKey $filename
    
    #Create a cursor at the row named "data"
    catch {mk::cursor create cu $dbKey.data}
    mk::cursor position cu 0

    #Store the two items - name and tree object - in an array
    set output(Name) [mk::get $cu Name]
    set output(ImageTree) [mk::get $cu ImageTree]

    return $output

}
##########################################################################################




