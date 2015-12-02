# AUTOVALA PLUGIN FOR GEDIT #

This is a plugin for GEdit 3 that integrates the project manager AutoVala,
allowing to use GEdit as a fully-fledged IDE for creating projects in VALA
language.

The plugin adds a left panel which shows the binaries and libraries being
created by an AutoVala project and its source files, allowing to choose them
just by clicking on each. It also shows all the other files in the project
(doc, po, data...) and the AVPRJ file.

To open an AutoVala project, just open any of the files belonging to it, and
the plugin will autodetect the project and show all the data.

Remember that you need Autovala installed in your system.

# INSTALLING THE PLUGIN #

By default, the plugin is compiled for GEDIT 3.12 or later. If you are using
GEDIT 3.10 or previous, you must add the -DOLD_GTK=on parameter to cmake. After
installation, close all GEdit windows, open it again and go to
Preferences -> Plugins to enable the Autovala plugin.


## Local installation ##

CURRENTLY, LOCAL INSTALLATION IS NOT AVAILABLE

Local installation is the preferable way for installing this plugin. It makes
the plugin accesible only to the user that installed it, but has the advantage
of not needing root priviledges, and also avoids the problems with library
paths (which, in 64bit systems, are problematic). To install it in this way,
just type:

        mkdir install
        cd install
        cmake .. -DCMAKE_INSTALL_PREFIX=$HOME/.local [-DOLD_GEDIT=on]
        make
        make install

Remember that [-DOLD_GEDIT=on] is optional, and needed only to compile for
GEDIT 3.10 or older.


## System-wide installation ##

To install this plugin system-wide, allowing to be used by all users in the
system, just type:

        mkdir install
        cd install
        cmake .. [-DOLD_GEGIT=on]
        make
        sudo make install

This mode needs root priviledges, and in some systems can be installed in the
wrong folder, forcing the user to manually move the files to the right place.
Again, remember that [-DOLD_GEDIT=on] is optional and needed only to compile
for GEDIT 3.10 or older.
