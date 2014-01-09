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
search()
{
	Search=`$Zenity --title "dpkg-frontend" --entry \
		--text="Search for package"`

	$Dpkg --list | $Awk '{ print $2 }' | $Egrep -x $Search &> /dev/null
	if [ $? -eq 0 ]; then
		Pkginfo=`$Dpkg --status $Search`
		$Zenity --no-markup --title "dpkg-frontend" \
		--info --text="$Pkginfo"
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
search
echo $Search

exit 0
