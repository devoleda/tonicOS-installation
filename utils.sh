 # ============================================================================
 # Name        : utils.sh
 # Authors      : Yuval, Roee
 # Version     : 1.0
 # Copyright   : Copyright (C) 2015 The Tonic Team.
 # Description : Dialog based installations tools for Tonic OS

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

#!/bin/bash

set_passwd() {
	dialog --title "$TITLE" --insecure --passwordbox "Enter your desired password" 10 40 2>${ANSWER} || return 1
	passwd1= $cat ${ANSWER}
	dialog --title "$TITLE" --insecure --passwordbox "Repeat the password you entered" 10 40 2>${ANSWER} || return 1
	passwd2= $cat ${ANSWER}
	if [ "$passwd1" == "$passwd2" ]; then
		passwd1= $passwd1
	else
		dialog --title "$TITLE" --infobox "The passwords you entered do not match"
		set_passwd
	fi	
}
finddisks(){
    cd /sys/block
    
    for dev in $(ls | egrep '^hd'); do
        if [ "$(cat $dev/device/media)" = "disk" ]; then
            echo "/dev/$dev"
            [ "$1" ] && echo $1
        fi
    done
    
    for dev in $(ls | egrep '^sd'); do
        if ! [ "$(cat $dev/device/type)" = "5" ]; then
            echo "/dev/$dev"
            [ "$1" ] && echo $1
        fi
    done
    
    for dev in $(ls | egrep '^mmcblk'); do
        if [ -e /sys/block/$dev ]; then
            echo "/dev/$dev"
            [ "$1" ] && echo $1
        fi
    done
   
    if [ -d /dev/cciss ] ; then
        cd /dev/cciss
        for dev in $(ls | egrep -v 'p'); do
            echo "/dev/cciss/$dev"
            [ "$1" ] && echo $1
        done
    fi
    
    if [ -d /dev/ida ] ; then
        cd /dev/ida
        for dev in $(ls | egrep -v 'p'); do
            echo "/dev/ida/$dev"
            [ "$1" ] && echo $1
        done
    fi

    cd "$WORKDIR"
}
#parameter- HD
hd_is_empty(){
	#soon a logical partitions option will be added
	cont=0
	cd /sys/block
	if [ "$(ls -A $1)" ]; then
    	cont=1
	else
    	cont=0
	fi
	cd "$WORKDIR"

}
get_partitions_size() {	
    dialog --title "$TITLE" --inputbox "$_bootsize" 10 40 102.4 2>${ANSWER} 
    boot_partition=$(cat ${ANSWER})
    dialog --title "$TITLE" --inputbox "$_swapsize" 10 40 4096 2>${ANSWER}
    swap_partition=$(cat ${ANSWER})
    dialog --title "$TITLE" --inputbox "$_rootsize" 10 40 2>${ANSWER}
    root_partition=$(cat ${ANSWER})
    dialog --title "$TITLE" --inputbox "$_homesize" 10 40 2>${ANSWER}
    home_partition=$(cat ${ANSWER})


}
#$1 is size
#$2 is type
#$3 is logical\ primary
create_partition(){
    #TODO:
    # test && fix errors
    # format VV
    # mount VV
    # add logical option VVV
    if [$3 = "logical"]; then
        start_partition= 5
    elif [$3 = "primary"]; then    
        start_partition= 1
    fi    
    case $2 in
        "boot" )
            ## Made it bootable with set, didn't test it yet.
            parted $HD $start_partition makepartfs part-type primary $_current_block $1 set "boot" "on"
            _current_block= $_current_block + $1
            start_partition = start_partition + 1
            ;;
        "swap" )
           parted $HD $start_partition makepartfs part-type linux-swap primary $_current_block $1
            _current_block= $_current_block + $1
            start_partition = start_partition + 1
            ;;
        "root" )
             parted $HD $start_partition makepartfs part-type primary $_current_block $1
            _current_block= $_current_block + $1
            start_partition = start_partition + 1
            ;;
        "home" )
            parted $HD $start_partition makepartfs part-type primary $_current_block $1
            _current_block= $_current_block + $1
            start_partition = start_partition + 1
            ;;
        * )
            ;;    
    esac
}

find_partitions(){

    for devpath in $(finddisks); do
        disk=$(echo $devpath | sed 's|.*/||')
        cd /sys/block/$disk
        for part in $disk*; do
          
            if ! [ "$(cat /proc/mdstat 2>/dev/null | grep $part)" -o "$(fstype 2>/dev/null </dev/$part | grep "lvm2")" -o "$(sfdisk -c /dev/$disk $(echo $part | sed -e "s#$disk##g") 2>/dev/null | grep "5")" ]; then
                if [ -d $part ]; then
                    echo "/dev/$part"
                    [ "$1" ] && echo $1
                fi
            fi
        done
    done
    for devpath in $(ls /dev/mapper 2>/dev/null | grep -v control); do
        echo "/dev/mapper/$devpath"
        [ "$1" ] && echo $1
    done
    
  
    if [ -d /dev/cciss ] ; then
        cd /dev/cciss
        for dev in $(ls | egrep 'p'); do
            echo "/dev/cciss/$dev"
            [ "$1" ] && echo $1
        done
    fi
    
    if [ -d /dev/ida ] ; then
        cd /dev/ida
        for dev in $(ls | egrep 'p'); do
            echo "/dev/ida/$dev"
            [ "$1" ] && echo $1
        done
    fi
    cd "$WORKDIR"
}

##TODO: Test & fix errors
format_partitions(){
    ## Format boot partition
    mkfs.ext4 $(find_partitions | head -1)

    ## Format swap partition
    mkswap $(find_partitions | sed -n 2p)

    ## Format root partition
    mkfs.ext4 $(find_partitions | sed -n 3p)

    ## Format home partition
    mkfs.ext4 $(find_partitions | tail -1)
}

##TODO: Test & fix errors
mount_partitions(){
    ## Mount root partition
    mount $(find_partitions | sed -n 3p) /mnt

    ## Mount swap pratition
    swapon $(find_partitions | sed -n 2p)

    ## Mount boot partition
    mkdir /mnt/boot && mount $(find_partitions | head -1) /mnt/boot

    ## Mount home partition
    mkdir /mnt/home && mount $(find_partitions | tail -1) /mnt/home
}
