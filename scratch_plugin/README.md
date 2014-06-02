# AUTOVALA PLUGIN FOR SCRATCH #

This is a plugin for Scratch Text Editor 2.x that integrates the project manager
AutoVala, allowing to use Scratch as a fully-fledged IDE for creating projects
in VALA language.

The plugin adds a left panel which shows the binaries and libraries being
created by an AutoVala project and its source files, allowing to choose them
just by clicking on each. It also shows all the other files in the project
(doc, po, data...) and the AVPRJ file.

To open an AutoVala project, just open any of the files belonging to it, and
the plugin will autodetect the project and show all the data.

Remember that you need Autovala installed in your system.

# INSTALLING THE PLUGIN #

The plugin needs Scratch 2.0 or later. After installing, close all Scratch
windows, open it again, and go to Preferences -> Extensions to enable the
Autovala extension.

## System-wide installation ##

To install this plugin system-wide, allowing to be used by all users in the
system, just type:

        mkdir install
        cd install
        cmake .. -DCMAKE_INSTALL_PREFIX=/usr
        make
        sudo make install

This mode needs root priviledges. The "-DCMAKE_INSTALL_PREFIX=/usr" is needed
only if you installed Scratch from a .DEB or .RPM package system. If you
compiled it from source and installed it in /usr/local, you must change it to
"-DCMAKE_INSTALL_PREFIX=/usr/local" (or the folder where you installed it). This
is because, currently, Scratch only searchs for plugins in the same directory
group where it was installed.
