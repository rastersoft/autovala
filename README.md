# AUTOVALA #

## WHAT IS IT? ##

Autovala is a program and a library designed to help in the creation of
projects with Vala and CMake.

The idea is quite simple: CMake is very powerful, but writting the CMakeLists
files is boring and repetitive. Why not let the computer create them, by
guessing what to do with each file? And if, at the end, there are mistakes,
let the user fix them in an easy way, and generate the final CMakeLists files.

This is what Autovala does. This process is done in three steps:

  * First, Autovala checks all the folders and files, and writes a project
    file with the type of each file
  * It also peeks the source files to determine which Vala packages they need,
    and generate automagically that list
  * After that (and after allowing the user to check, if (s)he wishes, the
    project file), it uses that project file to generate the needed CMakeLists
    files


## USING AUTOVALA ##


The DOC folder contains the Wiki dumped in HTML format. Just open the
**index.html** file with your browser, or go to the **Wiki section** in GitHub,
and enjoy.


## History of versions ##
* version 0.94.0 (2014-03-21)
    * Now keeps automatic binaries when contains a manually-added DBus interface definition
* version 0.93.0 (2014-03-18)
    * Now remembers if a dbus interface must be generated using gdbus or dbus-glib.
* version 0.92.0 (2014-03-15)
    * Allows to generate automatically DBus interfaces, using DBus introspection capabilities and *vala-dbus-binding-tool*.
    * Now adds GIO automatically if it finds *stdin.* or *stdout.* in the source code.
* version 0.91.0 (2014-01-18)
    * When a project creates one or more libraries, the "make install" command shows a message remembering to run 'sudo ldconfig'.
* version 0.90.0 (2014-01-16)
    * Now takes into account the dependencies for VAPI files when creating the CMake files.
    * Now allows to specify libraries to be added when compiling the C code but not the Vala code. Useful when mixing C and Vala source files.
* version 0.35.0 (2013-12-26)
    * Now includes automagically the VAPIs files in the "vapis" folder for each binary/library
    * Now doesn't add a vala package if a local VAPI provides the same namespaces
    * Allows to pass flags to the C compiler/linker
    * Allows to mix VALA and C source files in the same binary or library
* version 0.34.0 (2013-12-21)
    * Now adds GObject only if the source file contains classes
* version 0.33.0 (2013-12-14)
    * Fixed bug with libgee 0.6, which is named, due to historical reasons, as libgee-1.0
* version 0.32.0 (2013-12-06)
    * Always forces GLib and GObject packages to ensure that everything compiles
    * Added GLib.File as rule to detect when automagically add GIO
* version 0.31.0 (2013-12-04)
    * Allows to install the projects in the local folder
* version 0.30.0 (2013-12-04)
    * Now shows a warning message when it can't find a package from a Using statement
    * Now supports packages that contains more than one namespace when the user sets manually that package
    * Now adds a tabulator inside conditionals in the CMakeLists.files
    * Now puts the manual packages before the automatic ones in the configuration file
    * Added support for nested namespaces in VAPI files
* version 0.29.0 (2013-12-02)
    * Now uses regular expressions for processing the USING and PROJECT VERSION strings, which gives more flexibility to the user
    * Now can autodetect in some cases when to add the gio package
* version 0.28.0 (2013-12-01)
    * Supports the use of conditionals with COMPILE_OPTIONS statement
    * Allows to use several COMPILE_OPTIONS in the same binary/library
* version 0.27.0 (2013-12-01)
    * Full refactorization to simplify future maintenance and improvements
    * Removed the Gedit plugin (until having spare time to fix it)
* version 0.26.0 (2013-11-17)
    * Added support for more input formats when creating man pages
    * Now MarkDown format is github format
* version 0.25.0 (2013-11-16)
    * Added support for creating and installing man pages
    * Added manpages for Autovala
* version 0.24.0 (2013-10-20)
	* Added conditional compilation and conditional installation support
* version 0.23.0 (2013-10-14)
	* Added bash_completion support
* version 0.22.0 (2013-10-14)
	* Autovala and gedit plugin are now different projects, allowing to compile only the former
	* Now supports several namespaces in the same .vapi file
* version 0.21.0 (2013-09-14)
    * Allows to specify GIO, GIO-unix, GObject and GModule packages for compilation
* version 0.20.0 (2013-05-19)
    * When initializating a new project, it will copy the needed CMAKE scripts for Vala and create an empty source file
    * Now the CUSTOM command accepts both files and folders
    * Now only adds CUSTOM_VAPIS_LIST command when there are a custom VAPI list
    * Now forbides to set files in the main directory (all files/folders must be inside a folder in the main directory). This is a must to avoid failures.
* version 0.19.0 (2013-04-30)
    * Now the plugin deletes the content of the *install* folder, but not the folder itself
* version 0.18.0 (2013-04-30)
    * Allows to delete the INSTALL folder from Gedit
    * Allows to delete the INSTALL folder, update the .avprj file, run cmake and launch make in a single step from Gedit
* version 0.17.0 (2013-04-28)
    * Fixed bug in plugin when updating the whole project
* version 0.16.0 (2013-04-28)
    * Added plugin for Gedit
* version 0.15.0 (2013-04-26)
    * Allows to specify manually the destination directory for binaries and libraries (useful for plugins)
    * Allows to install files in a manually specified destination directory
    * Autodetects autorun *.desktop* files and install them in the right place
* version 0.14.0 (2013-04-21)
    * Now the autovala library can use its own translated messages instead the ones from the main app (useful when embedding autovala in other programs)
* version 0.13.0 (2013-04-11)
    * In libraries, includes the *librarynamespaceConstant* namespace to allow to get access to build data without clash (only when the library has a namespace)
    * Added *clear* command, to remove the automatic parts in the *.avprj* file
* version 0.12.0 (2013-04-09)
    * When checking VAPI files, now will give priority to the version number inside it (gir_version), and only when there is no such number will use the one in the filename
* version 0.11.0 (2013-04-07)
    * Includes the *Constant* namespace in the executables (but not in libraries to avoid clash)
    * Enabled gettext to allow to translate the messages in Autovala
    * Translation to spanish
    * Fixed messages
    * Fixed a bug in Constants that prevented defining the VERSION field
    * New format for the version string inside source code, that allows to set it in libraries without clash
* version 0.10.0 (2013-04-07)
    * Allows to link an executable with a library from the same project
    * Now Autovala itself is a shared library, and the command line binary uses it
    * Fixed several bugs in the .pc generation
    * Fixed the installation paths for include files
* version 0.9.0 (2013-04-06)
    * Fixed a bug in the .pc generation
* version 0.8.0 (2013-04-06)
    * Automatically generates the .pc file for libraries
    * Fixed a bug with CMake when creating more than one binary and/or library
* version 0.7.0 (2013-04-05)
    * Now honors the IGNORE command with VAPI files and source folders
* version 0.6.0 (2013-04-05)
    * Added support for CUSTOM VAPI files
    * Installs Valadoc file sin a better place
    * Added instructions in HTML format, extracted from GitHub's wiki
* version 0.5.0 (2013-04-01)
    * Adds all source files at SRC and their subdirectories
* version 0.4.0 (2013-03-31)
    * Fixed a bug when PKG_CONFIG_PATH is empty
* version 0.3.0 (2013-03-30)
    * Added support for source files that are not in the same folder than the binary they belong to
    * Added documentation about DOC command
    * Valadoc support
* version 0.2.0 (2013-03-30)
    * Now recognizes the DOC folder
    * Now also search libraries in PKG_CONFIG_PATH
* version 0.1.0 (2013-03-29)
    * First public version


## CONTACTING THE AUTHOR ##

Sergio Costas Rodriguez
(Raster Software Vigo)

raster@rastersoft.com

http://www.rastersoft.com

GIT: git://github.com/rastersoft/autovala.git
