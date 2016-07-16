# ============================================================================
 # Name        : guinstall.sh
 # Author     : Yuval.
 # Version     : 1.0
 # Copyright   : Copyright (C) 2015 The Tonic Team.
 # Description : GUI installation for TonicOS
 # This program is free software; you can redistribute it and/or modify
 # it under the terms of the GNU General Public License as published by
 # the Free Software Foundation; either version 2 of the License, or
 # (at your option) any later version.
 # This program is distributed in the hope that it will be useful,
 # but WITHOUT ANY WARRANTY; without even the implied warranty of
 # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 # GNU General Public License for more details.
 # You should have received a copy of the GNU General Public License along
 # with this program; if not, write to the Free Software Foundation, Inc.,
 # 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 # ============================================================================

#!bin/bash -e
_title = "TonicOS installation v0.0.1"

main_menu() {
	zenity --title "$_title"  --list --column "hey"

}





if [ "$(id -u)" = "0" ]; then
	zenity --title "Welcome!"  --info --text="Welcome to the TonicOS installation! \n"
	main_menu
else
	zenity --title "Not root"  --error --text="You must run the script as root"
fi