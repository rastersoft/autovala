## History of versions ##
* version 0.99.48 (2016-12-16)
    * Added initial support for Genie
    * Now adds the .VAPI and .GS (Genie) files in all src/ folder to the list of files generated for SCM systems like GIT
* version 0.99.47 (2016-10-23)
    * Now the list of files to translate is kept ordered between executions, reducing the number of changes in repositories due to changes in the file order
    * Added support for external data (useful to store data for external programs that use autovala)
    * Added support for persistent comments in the AVPRJ file
* version 0.99.46 (2016-10-02)
    * Fixed bug when using an absolute path for vapidir: commands
    * Allows to add non-existing folders with vapidir
    * Fixed several english errors ("doesn't exists" changed to "doesn't exist")
* version 0.99.45 (2016-09-21)
    * Allows to use CMAKE_BUILD_TYPE with standard and custom-defined types
    * Now automagically generates the debugging symbols when the build type specified should have them
    * By default compiles with the **Release** build type, ensuring -O3 optimizations for the binaries
* version 0.99.44 (2016-09-20)
    * Allows to use conditionals in INCLUDE, SOURCE_DEPENDENCY and BINARY_DEPENDENCY commands
* version 0.99.43 (2016-09-18)
    * Allows to compile and fully rebuild the project from external editors, like Gedit
* version 0.99.42 (2016-09-18)
    * Now it pases the gresource files to the vala compiler, allowing to use Gtk Templates
* version 0.99.41 (2016-08-25)
    * Fixed a bug in the --vapidir folder generation
    * Fixed some compilation warnings
* version 0.99.40 (2016-08-21)
    * Allows to specify --vapidir folders
    * Now includes the files inside a GResource XML file in the project's file list
* version 0.99.39 (2016-08-02)
    * Allows to use GResource files in projects
    * Uses GResources to store icons and glade files
    * Now shows the output of autovala when it can't refresh the widgets in an editor
* version 0.99.38 (2016-01-28)
    * Now PKG_CONFIG_PATH takes precedence (and fully replaces) the base paths.
    * Fixed a bug when compiling under windows
* version 0.99.37 (2015-12-05)
    * Now the DBUS Service files ends with the right file name (it removes the ".base" if requires)
* version 0.99.36 (2015-12-02)
    * Supports conditional CUSTOM and VALA_DESTINATION commands
    * Now the Gedit plugin can be installed in the right folders both locally and globally
* version 0.99.35 (2015-11-24)
    * Now the buttons in the plugins for Gedit and Scratch works fine (fixed callbacks)
* version 0.99.34 (2015-11-22)
    * Allows to put several files in "source_dependency" and "binary_dependency" statements, allowing to search for one of the files listed fo fullfill the condition.
* version 0.99.33 (2015-11-09)
    * Uses the new format for AppData files
    * Recognizes **.metainfo.xml** files as AppData files too
* version 0.99.32 (2015-11-08)
    * Recognizes AppData files, installing them in the right place and using its data when creating packages
* version 0.99.31 (2015-10-29)
    * Allows to use "using PKG, PKG..." syntax (before only allowed one package per "using" statement)
* version 0.99.30 (2015-10-14)
    * Removes multithread compilation under Arch, because doesn't work
* version 0.99.29 (2015-08-24)
    * Updated PKGBUILD to the new Pandoc package
    * Updated DEBIAN control files to support both valac-0.26 and 0.28
    * Added Windows CMake support
* version 0.99.28 (2015-08-15)
    * Now ensures that the Debian control file has a valid name
* version 0.99.27 (2015-05-31)
    * Now refreshes fine the icon cache when there are several icon themes
* version 0.99.26 (2015-05-11)
    * Now, for arch, installs libraries in /usr/lib instead of /usr/lib64
    * Fixed dependencies in the DEB, RPM and Pacman files
* version 0.99.25 (2015-05-10)
    * Now allows to generate PKGBUILD files for Arch's Pacman that support to download the sources from a repository (like GitHub)
    * Added packaging files for the Gedit-Plugin
    * Now, if it is not possible to determine to which package belongs a file, the package generation process will not be stopped
    * Fixed some extra bugs in the PGBUILD generation process
* version 0.99.24 (2015-05-09)
    * Now uses separated .base files when creating deb, rpm or pacman packages
* version 0.99.23 (2015-05-07)
    * Added support for creating preliminar PACMAN's PKGBUILD files
    * Fixed bug when extracting translation strings in non-ascii, UTF-8 format
    * Removed (hope this one for all) the [type: gettext/glade] entry
* version 0.99.22 (2015-04-26)
    * Better use of the VERSION field in packages
* version 0.99.21 (2015-04-23)
    * Now sets the right permissions to DEB and RPM files
    * Added msgfmt as dependency for programs
    * Now fills the SECTION field in DEB packages
    * Add bash-completion.pc as dependency when there are bash-completion files
* version 0.99.20 (2015-04-12)
    * Now adds the field VERSION in the DEBIAN/CONTROL file
    * Allows to set files that must be present during build (needed for readline, since it doesn't have pkg-config file)
* version 0.99.19 (2015-04-06)
    * Now also passes the definitions set in CMAKE with -D to the C source files
    * Adds again the GLADE mimetype to the POTFILES.in .ui files, to ensure that intltool-update recognizes them
* version 0.99.18 (2015-02-23)
    * Now calls gtk-update-icon-cache with the right path
    * Updated spanish translation and translatable strings
* version 0.99.17 (2015-02-17)
    * Better support for exporting Autovala projects to Valama
* version 0.99.16 (2015-02-17)
    * Added preliminary support to export Autovala project files to Valama project files
* version 0.99.15 (2015-02-15)
    * Can use the canvas size of a SVG file to determine the size entry where to put it
* version 0.99.14 (2015-02-12)
    * Allows to specify a different theme for icons
    * Now parses the INDEX.THEME file from an icon theme to know where to put an icon
    * Allows to specify extra folders where to search for .h files when compiling the C source files
    * Fixed a bug when setting several C parameters
* version 0.99.13 (2015-02-02)
    * Now doesn't take into account DEFINE parameters named "true", "false", "0" or "1"
    * Fixed the final directory name for bitmap icons
* version 0.99.12 (2015-01-11)
    * Fixed a bug when using development versions of Vala compiler
    * Allows to use alternative CMAKE files
* version 0.99.11 (2014-12-12)
    * Can create automagically the metadata for .deb and .rpm packages
    * Now honors the c_library parameters also in libraries
    * Now only updates the project view in editor plugins when the project file has changed.
    * Added support for GTK 3.4 (needed to allow to compile under Elementary OS Luna)
* version 0.99.10 (2014-11-18)
    * Added support for unitary tests
* version 0.99.9 (2014-09-23)
    * Now .gitignore also contains a line to ignore backup files (this is, files with a name ended in ~)
    * Allows to set an specific vala version in the configuration file, or let autovala set automatically the most recent version available
* version 0.99.8 (2014-09-18)
    * Fully fixed to avoid put as a requirement the library being built when it defines a sub-namespace of its own namespace
    * Autogenerates a .gitignore, .bzrignore and .hgignore files
* version 0.99.7 (2014-09-03)
    * Generates .deps files for libraries, needed with .vapi files
    * Adds **Require** field in pkg-config files to list the dependencies of a library
    * Now doesn't put as a requirement the library being built when it defines a sub-namespace of its own namespace
* version 0.99.6 (2014-08-27)
    * Doesn't show the message that can't resolve "Using Math" when using that statement
* version 0.99.5 (2014-08-26)
    * Allows to specify C libraries that lacks pkg-config support (like the math library, needed when using GLib.Math)
* version 0.99.4 (2014-08-25)
    * Added the "project_files" option to the text shown with "help"
* version 0.99.3 (2014-07-30)
    * Now detects valac development versions with non-classic version numbers, like *Vala 0.25.1.1-ba8e*
* version 0.99.2 (2014-06-30)
    * Now installs manpages at .../man/manX, instead of .../man/man/manX
* version 0.99.1 (2014-06-30)
    * Allows to list all the files needed to compile the project. Useful to add them to GIT, Bazaar, Subversion...
    * Now error messages are shown in STDERR instead of STDOUT
    * Added translations for Scratch plugin
* version 0.99.0 (2014-06-08)
    * Added global search (searchs string in all the files in a project)
    * Added panel to show the output of the building process
    * Internal changes to allow to add more types of elements
    * Now double-click is used to the files from the project view, the file view or the global search
    * Fixed scrolling problem in the project view under scratch text editor
* version 0.98.0 (2014-05-26)
    * Added support for GEdit 3.12 and later in the plugin
    * Added a plugin for Scratch Text Editor
    * Allows to create new projects from the plugins
    * Added folders */usr/lib64* and */usr/local/lib64* in the list for searching pkgconfig packages (enhances compatibility with Fedora)
    * Now it uses GNUInstallDirs with CMake, improving compatibility with non-debian-based systems
    * Now installs the autostart file in ${XDG\_CONFIG\_HOME}/autostart when the code is being installed in the $HOME directory
    * Now adds all non-conditional CHECK elements
* version 0.97.0 (2014-05-12)
    * Added support for the new GEdit plugin for Autovala
    * Added two GTK3 widgets to allow to easily create plugins for text editors
    * Now the GLOBALS object has the vapiList as an static member, allowing to read it once. This speeds up the gedit plugin
    * Now autovala doesn't add hiden or backup source files
* version 0.96.0 (2014-05-04)
    * Now manages the bash-completion files automagically
    * When installing a project to the HOME folder, it won't install the bash-completion files to avoid an error (because they should go to /etc)
    * Added compatibility with source-based linux distributions (like gentoo), which doesn't add a link to a "default" vala compiler version
    * Allows to manually specify the vala compiler to use when building a project
* version 0.95.0 (2014-04-02)
    * Now always copy the CMAKE folder when doing a "cmake" or "update" command
    * Added extra checks when copying the CMAKE folder
    * Allows to automatically update the .po files with new strings (requires gettext 0.18.3)
    * Fixed bug when autodetecting manpages
    * Now checks if dbus-send and vala-dbus-binding-tool are installed if needed
    * Removed BASH dependency
    * Now supports several parameters in the compile_c_options statement
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
