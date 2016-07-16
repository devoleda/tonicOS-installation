 # ============================================================================
 # Name        : install.sh
 # Author     : Yuval.
 # Version     : 1.0
 # Copyright   : Copyright (C) 2015 The Tonic Team.
 # Description : Dialog based installations wizard for tonic OS

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
source utils.sh

# Global variables
_hdready=0
TITLE="Tonic OS Lemon Installation Beta"
ANSWER="tmp/.setup"
DESTDIR="/install"
ARCH=$(uname -m)
WORKDIR="$PWD"
HD=0
_current_block=0

_msg_welcome="Welcome to the Tonic OS installation wizard!"

# Main menu choices
_choice_date="Set date"
_choice_partitions="Create partitions"
_choice_base="Install base system"
_choice_xorg="Install Xorg"
_choice_configure="Configure system"
_choice_boot="Install GRUB"
_choice_exit="Exit installation"
_must_root="You must run this script as root! aborting"

# System config choices
_choice_setroot="Set root password"
_choice_setlang="Set language"
_choice_setkblayout="Set keyboard layout"
_choice_createuser="Create user"

# System config messages

#create partitions messages
_hd_select="please choose a HD for the system"
_hdoverwrite="is not Empty, do you want to overwrite it or install alongside?"
_hdempty="is Empty, do you want to continue?"
_swapsize="Enter the size of swap (default is recommended)"
_bootsize="Enter the size of boot (default is recommended)"
_homesize="Enter the size of home (usually about 3\4 of the hard drive)"
_rootsize="Enter the size of root (usually about 1\4 of the hard drive)"

# Exit messages
_text_exit="Thanks for installing TonicOS!"
_text_cancel="Are you sure?"

# Time select messages
_text_selectregion="Please select a region"
_text_selecttimezone="Please select a timezone"

#keyboard select messages
_text_selectkeyboard="Please select a keyboard layout in addition to the english layout (if nothing- select continue)"


set_clock() {
    CANCEL=""	
    HARDWARECLOCK=$(cat ${ANSWER})
    #display regions and set one
     for i in $(grep '^[A-Z]' /usr/share/zoneinfo/zone.tab | cut -f 3 | sed -e 's#/.*##g'| sort -u); do
     	REGIONS="$REGIONS $i -"
     done
     region=""
     zone=""
     while [ -z "$zone" ];do
    	region=""
     	while [ -z "$region" ];do
     		 :>${ANSWER} 
     		 	dialog --title "$TITLE" --menu "${_text_selectregion}" 0 0 0 $REGIONS 2>${ANSWER} || CANCEL="1"
			if [[ "${CANCEL}" = "1" ]]; then
				main_menu
			fi
     		 	region=$(cat ${ANSWER})
    	 done
    	 #display zone and set one
    	 ZONES=""
     	for i in $(grep '^[A-Z]' /usr/share/zoneinfo/zone.tab | grep $region/ | cut -f 3 | sed -e "s#$region/##g"| sort -u); do
      		ZONES="$ZONES $i -"
   	done
   	:>${ANSWER}
   	dialog --title "$TITLE" --menu "${_text_selecttimezone}" 0 0 0 $ZONES 2>${ANSWER} || CANCEL="1"
	if [[ "${CANCEL}" = "1" ]]; then
		main_menu
	fi

        zone=$(cat ${ANSWER})
     done
 	TIMEZONE="$region/$zone"

 	if  ln -s /usr/share/zoneinfo/$TIMEZONE /etc/localtime ; then
 		dialog --msgbox "time zone has been set to $TIMEZONE" 10 40
 		main_menu
 	else
 		dialog --msgbox "error" 10 40
 		main_menu
 	fi

}

partitions_create() {
	_hdready=1
	dialog --menu "${_hd_select}" 14 55 7 $(finddisks -) 2>${ANSWER} || return 1
    	HD=$(cat ${ANSWER})
   	hd_is_empty $HD
    	if [ $cont == 1 ]; then
    		dialog --title "$TITLE" --menu "$HD $_hdoverwrite" 18 40 2 \
    			"1" "overwrite" \
    			"2" "install alongside (if you got another system)" 2>${ANSWER}
    		if [$ANSWER = "1"]; then
    			get_partitions_size
    			create_partition $boot_partition boot primary
   			create_partition $swap_partition swap primary
   			create_partition $root_partition root primary
  			create_partition $home_partition home primary
   		else
   			get_partitions_size
    			create_partition $boot_partition boot logical
   			create_partition $swap_partition swap logical
   			create_partition $root_partition root logical
   			create_partition $home_partition home logical
   		fi
   	else
  		if dialog --title "$TITLE" --yesno "$HD $_hdempty" 10 40; then
   			
   			get_partitions_size
   			create_partition $boot_partition boot primary
   			create_partition $swap_partition swap primary
   			create_partition $root_partition root primary
   			create_partition $home_partition home primary
   		else
   			main_menu
   			
   		fi
   	 fi
    	cd $WORKDIR
    	#main_menu

	

}

install_base() {
	# TODO:
	# (install X) + wm/de && configure with our script
	# install neccesery tools + configure
	# create autorun file
	
	dialog --title "$TITLE" --msgbox "${_choice_base}" 10 40 
	pacstrap /mnt base base-devel
	
	dialog --title "$TITLE" --msgbox "${_choice_xorg}" 10 40
	pacman -Q xorg-server xorg-server-utils xorg-xinit mesa
	
	main_menu
}

configure_system() {
	dialog --menu "What do you want to do? " 18 40 4 \
       		"1" "${_choice_setroot}" \
        	"2" "${_choice_setkblayout}" \
        	"3" "${_choice_setlang}" \
			"4" "${_choice_createuser}" 2>${ANSWER}

	case $(cat ${ANSWER}) in
	"1")
		user="root"
		set_passwd
		echo "$user:$passwd1" | chroot ${DESTDIR} chpasswd
		configure_system
		;;
	"2")
		if [ [ -e src/keyboard.sh ] ];then
			src/keyboard.sh
			configure_system
		else
			dialog --msgbox "keyboard.sh doesnt exists" 10 40
			configure_system
		fi ;;
	"3")
		if [ [ -e /src/language.sh ] ];then
			/src/language.sh
			configure_system
		else
			dialog --msgbox "language.sh doesnt exists" 10 40
			configure_system
		fi ;;
	"4")
		dialog --title "$TITLE" --inputbox "enter username" 10 40 2>${ANSWER}
		user=$(cat ${ANSWER})
		set_passwd
		echo "$user:$passwd1" | chroot ${DESTDIR} chpasswd
		configure_system ;;
	*)

		main_menu ;;	
	esac	
}

install_grub() {
	#need a little fix
    pacman -S --noconfirm grub-bios | dialog --title "$TITLE" --gauge "Installing grub..." 10 75
    pacman -S -noconfirm os-prober | dialog --title "$TITLE" --gauge "Installing os-prober..." 10 75
    grub-mkconfig -o /boot/grub/grub.cfg
    grub-install --recheck $HD
    	
	main_menu
}

main_menu() { 
	dialog --backtitle "$TITLE" --menu "What would you like to do? " 18 55 8 \
			"1" "${_choice_date}" \
       		"2" "${_choice_partitions}" \
        	"3" "${_choice_base}" \
        	"4" "${_choice_configure}" \
			"5" "${_choice_boot}" \
			"6" "${_choice_exit}" 2>${ANSWER}
	case $(cat ${ANSWER}) in
	"1")
		set_clock ;;
	"2")
		partitions_create ;;
	"3")
		if [ "$_hdready" == "1" ];then
			install_base
		else
			dialog --msgbox "please run create partition first" 10 40
			main_menu
		fi ;;
	"4")
		configure_system ;;
	"5")
		install_grub ;;
	"6")
		dialog --infobox "${_text_exit}" 6 40
		exit 0 ;;
	*)
		if dialog --yesno "${_text_cancel}" 6 40 ;then
			exit 0
		else
			main_menu
		fi ;;
	esac


}
if [ "$(id -u)" = "0" ]; then
	dialog --title "$TITLE" --msgbox "$_msg_welcome" 10 40
	main_menu
else
	dialog --title "$TITLE" --msgbox "$_must_root" 10 40
fi
