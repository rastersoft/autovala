# Using Autovala

Autovala is designed as several Vala classes, so it can be embedded easily in other projects. My idea is to embed it as a Gedit plugin; but until then, you can use it from command line.

Before all, you need to install in your project folder the CMake modules for Vala. The repository contains a version modified to work with Valadoc, but you can always download the last oficial version from launchpad using bazaar:

        bzr checkout lp:~elementary-apps/+junk/cmake-modules

This will create a folder called *cmake-modules*. Inside it will be a folder
called *cmake*. Copy the later to your project folder.

The first thing to do is to initializate the project. This is done by calling
autovala in your desired project's folder with:

        autovala init PROJECT_NAME

This will create a *PROJECT_NAME.avprj* file, with the most basic info about
your project (the format for this file will be explained later). It will also
try to create the basic folders for a vala project, and will show a warning
if they already exist. It will never delete a file, except the *CMakeLists*
files, of course. The folder hierarchy is:

        .
        +src
        +install
        +doc
        +po
        +data
           +icons
           +pixmaps
           +interface
           +local

By default, Autovala will compile all the .vala source files located inside SRC and its subfolders into a single binary called like the project's name. How to generate libraries or several binaries is explained in the [tricks section](tricks).

INSTALL is the folder where to build everything. More about it later.

As can be supposed, DOC has to contain the documentation, and PO will contain the files with translatable strings. These strings are extracted from the .vala files and the .ui ones (from glade).

DATA is where you must put things like D-Bus activation files, .desktop files, scripts, and so on. ICONS folder and subfolders should contain the icons (in png or svg format), and Autovala will automagically take into account its size to put them in the right place.

INTERFACE should contain the .ui files from Glade.

Finally, LOCAL is a place where to put everything you want to get copied "as-is" into usr/share/PROJECT_NAME/.

When you are OK for the first compilation, just use Autovala to check the folders and automatically update the .avprj file with:

        autovala refresh

When using this command, Autovala will guess all the info about your project and put it in the .avprj file, so you can check and modify it if you want (more on that later). If everything is OK, just create the CMakeLists files from that data using:

        autovala cmake

Now you can go to the INSTALL folder and type 'cmake ..' to generate the makefiles for compile your project.
You can also use *cmake .. -DBUILD_VALADOC=ON* to add Valadoc support; but if you are using Ubuntu 12.10, maybe you should try to compile Valadoc from scratch, because it seems to be a bug in the version shipped from Canonical (more on this in the [tricks section](tricks)).

Since it's very common to call those two commands, one after the other, you can just use:

        autovala update

which will, first, update your .avprj file, and if there are no errors, will regenerate the CMakeLists files, all in one command.

These commands can be called from any of the folders or subfolders of the
project, because it will search for the first .avprj file located in the
current folder or upstream.
