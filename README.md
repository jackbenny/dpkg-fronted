# dpkg-frontend #
This is a simple frontend for dpkg (and apt-get) on Debian-based systems.
I wrote it as a part of a class assignment. The script uses Zenity to display
the GTK-dialogs and then executes diffrent commands for different things.
Note that when installing packages, this runs `apt-get install <PKG> -y`. This
means that all dependencies will be installed without asking.

The script uses as few hardcoded path as possible and then finds the rest of the
binaries with `which` and puts them variables with the same name as the binaries
but with an uppercase initial letter.


