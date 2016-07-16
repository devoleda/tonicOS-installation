# ============================================================================
#name        : keyboard.sh
# Author     : Yuval.
# Version     : 1.0
# Copyright   : Copyright (C) 2015 The Tonic Team.
# Description : keyboard settings for the TonicOS installation

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

#!bin/bash
source utils.sh
source install.sh

CANCEL=""
KEYMAPS=
for i in $(find ${BASEDIR}/keymaps -follow -name "*.gz" | sed 's|^.*/||g' | sort); do
	KEYMAPS="${KEYMAPS} ${i} -"
done

dialog --menu "${_text_selectkeyboard}" 22 60 16 ${KEYMAPS} 2>${ANSWER} || CANCEL="1"
if [[ "${CANCEL}" = "1" ]]; then
	main_menu
fi

selected_keymap=$(cat ${ANSWER})
dialog --msgbox "keymap selcted is ${selected_keymap} but script is still under construction, aborting" 10 40
main_menu




