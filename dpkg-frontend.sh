#!/bin/bash

################################################################################
#                                                                              #
#  Copyright (C) 2014 Jack-Benny Persson <jack-benny@cyberinfo.se>             #
#                                                                              #
#   This program is free software; you can redistribute it and/or modify       #
#   it under the terms of the GNU General Public License as published by       #
#   the Free Software Foundation; either version 2 of the License, or          #
#   (at your option) any later version.                                        #
#                                                                              #
#   This program is distributed in the hope that it will be useful,            #
#   but WITHOUT ANY WARRANTY; without even the implied warranty of             #
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              #
#   GNU General Public License for more details.                               #
#                                                                              #
#   You should have received a copy of the GNU General Public License          #
#   along with this program; if not, write to the Free Software                #
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA  #
#                                                                              #
################################################################################

# dpkg-frontend
Version="0.1"
Author="Jack-Benny Persson (jack-benny@cyberinfo.se)"

# Binaries
Which="/usr/bin/which"
Aptget="/usr/bin/apt-get"

# Binaries entered in the list will be avalible to the script as variables with
# the first letter uppercase
Binaries=(dpkg sed awk egrep printf cat grep mktemp rm tail zenity)

# Variables


### Functions ###

# Print version information
print_version()
{
        $Printf "\n$0 - $Version\n"
}

# Print help information
print_help()
{
        print_version
        $Printf "$Author\n"
        $Printf "dpkg-frontend\n"
/bin/cat <<-EOT

Options:
-h
Print detailed help screen
-V
Print version information
-v
Verbose output
EOT
}

# Dialog for package searching
search_pkg()
{
	Search=`$Zenity --title "dpkg-frontend" --entry \
	--text="Search for package"`
	if [ $? -eq 1 ]; then
		return 1
	fi

	$Dpkg --list | $Awk '{ print $2 }' | $Egrep -x $Search &> /dev/null
	if [ $? -eq 0 ]; then
		return 0
	else
		return 5
	fi
}

uninstall_pkg()
{
	$Zenity --title "dpkg-frontend" \
	--question \
	--text="Package <b>$Search</b> is installed.\nUninstall <b>${Search}</b>?"
	if [ $? -eq 0 ]; then # CHANGE NEXT LINE
		$Dpkg -r $Search | $Zenity --title "dpkg-frontend" \
		--progress --pulsate --text "Uninstalling <b>${Search}</b>..." 
	fi
}

install_pkg()
{
	$Aptget install $Search -y | \
	$Zenity --title "dpkg-fronend" --progress --pulsate \
	--text "Installing package <b>$Search</b>"
	if [ $? -eq 0 ]; then
		$Zenity --title "dpkg-frontend" --info \
		--text="Succesfully installed <b>$Search</b>"
		exit 0
	else
		$Zenity --title "dpkg-frontend" --error \
		--text="Something went wrong with the installation of <b>$Search</b>"
		exit 1
	fi
}

show_selections()
{
	Selections=`$Dpkg --get-selections $Search | awk '{ print $2 }'`
	$Zenity --title "dpkg-frontend" \
	--info --text "Selections for <b>$Search</b> is: <b>${Selections}</b>"
}

set_selections()
{
	SetSelections=`$Zenity --title "dpkg-frontend" --entry \
	--text "Type selections for package <b>$Search</b>"`
	echo "$Search $SetSelections" | $Dpkg --set-selections 
	if [ $? -eq 0 ]; then
		$Zentiy --title "dpkg-frontend" --info \
		--text "<b>${SetSelections}</b> is set for <b>${Search}</b>"
	else
		$Zenity --title "dpkg-frontend" --error \
		--text "Couldn't set selections for <b>$Search</b>"
	fi
}

show_info()
{
	Info=`$Dpkg --status $Search`
	$Zenity --no-markup --title "dpkg-frontend" --info \
	--text "$Info"
}

choice_dialog()
{
	Choice=`$Zenity --list --column=Action --column=Description \
	--radiolist uninstall "Uninstall" set "Set selections" \
	show "Show selections" \
	info "Show information"`
	if [ "$Choice" == "Uninstall" ]; then
		return 11
	elif [ "$Choice" == "Show selections" ]; then
		return 12
	elif [ "$Choice" == "Show information" ]; then
		return 13
	elif [ "$Choice" == "Set selections" ]; then
		return 14
	fi
}

# Create variables with absolute path to binaries and check
# if we can execute it (binaries will be avaliable in 
# variables with first character uppercase, such as Grep)
Count=0
for i in ${Binaries[@]}; do
$Which $i &> /dev/null
	if [ $? -eq 0 ]; then
		declare $(echo ${Binaries[$Count]^}=`${Which} $i`)
		((Count++))
	else
		echo "It seems you don't have ${Binaries[$Count]} installed"
		exit 1
	fi
done

# Check if we are root
if [ $EUID -ne 0 ]; then
	$Zenity --title "dpkg-frontend" --error \
	--text "You need to run <b>dpkg-frontend</b> as root"
	exit 1
fi

# Parse command line options and arguments
while getopts Vvho: Opt; do
       	case "$Opt" in
       	h) print_help
   	   exit 0
       	   ;;
       	V) print_version
   	   exit 0
       	   ;;
       	v) echo "Verbose output"
       	   exit 0
       	   ;;
       	*) short_help
       	   exit 1
       	   ;;
       	esac
done

### Main ###
search_pkg
case $? in
	1) exit 0
	   ;;
	5) $Zenity --title "dpkg-frontend" --question \
	   --text="Package <b>$Search</b> is not installed. Install it?"
	   if [ $? -eq 0 ]; then
		install_pkg
	   else
		exit 1
	   fi
	   ;;
esac

choice_dialog
case $? in
	11) uninstall_pkg
	    ;;
	12) show_selections
	    ;;
	13) show_info
	    ;;
	14) set_selections
	    ;;
esac

exit 0
