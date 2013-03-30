# AUTOVALA 0.1.0 #

## WHAT IS IT? ##

Autovala is a program and a library designed to help in the creation of
projects with Vala and CMake.

The idea is quite simple: CMake is very powerful, but writting the CMakeLists
files are boring and repetitive. Why not let the computer create them, by
guessing what to do with each file? And if, at the end, there are mistakes,
the user can just fix them in an easy way, and generate the final CMakeLists
files?

This is what Autovala does. This process is done in three steps:

  * First, Autovala checks all the folders and files, and writes a project
    file with the type of each file
  * Also peeks the source files to determine which Vala packages they need,
    and generate automagically that list
  * After that (and after allowing the user to check, if (s)he wishes, the
    project file), it uses that project file to generate the needed CMakeLists
    files
    
The rules followed by Autovala are the following:

  * All .vala files in the src/ folder belong to a binary called like the
    project name, and will be scanned to determine the packages needed to
    compile them
    
  * All .vala files in any subfolder in src/ belong to a binary called like
    the subfolder. So, all the .vala files in, for example, src/binary_test
    will be compiled to an executable called binary_test.
    
  * All .vala files in any subfolder in src/ whose name starts with 'lib'
    belong to a library called like the subfolder. So, all the .vala files
    in, for example, src/libtest will be compiled as a shared library
    called 'test', unless those source files contain a single namespace,
    in which case the namespace will be used for the library name and to
    generate the .vapi and .gir files automatically.
    
  * The sources will be scanned to find the version number in a specific
    format, allowing to keep it inside the sources and avoiding the need
    of editing the project file manually

  * All .png or .svg in the folder data/icons (and subfolders) are considered
    icons, so it will determine automatically the best-fitting standard icon
    size (in the case of .png; for .svg it will put them always in 'scalable')
    and install them in the corresponding folder: "apps" by default, unless
    it's an .svg file with a filename ended in -symbolic.svg; in that case it
    will go to "status". The user can modify the final folder manually for the
    icons (s)he wishes.
    
  * All .png, .jpg or .svg files in the folder data/pixmaps (and subfolders)
    are considered pixmaps, and will be copied to share/pixmaps.
    
  * All .po files in po/ folder will be considered as po files, and will be
    installed in the right locale. Also, will find the .vala and .ui files
    and add them as sources for internationalization process.
    
  * Each .desktop file in data/ will be copied to share/desktop
  
  * Each .service file in data/ will be presumed to be a DBus service,
    and will be preprocessed to put the right binary folder (bin/ or local/bin)

  * Each .plug file in data/ will be presumed to be an ElementaryOS PLUG file
  
  * Each .gschema.xml file in data/ will be presumed to be a GTK schema, so
    will be copied in the right place and force a recompile of the schemas
    (if needed)
    
  * Each .ui file in data/interface/ will be presumed to be a Glade file,
    so will be copied to share/project_name/ and taken into account when
    generating the .po and .mo files for internationalization
    
  * Each .sh file in data/ will be presumed to be a binary script, so will
    be copied to bin/
    
  * All files and folders in data/local will be copied to share/prject_name/
    This is useful for application-specific data, or documentation


## USING AUTOVALA ##

Autovala is designed as several Vala classes, so it can be embedded easy in
other projects. My idea is to embedd it as a GEdit plugin; but until then,
you can use it from command line.

Before all, you need to install in your project folder the CMake modules for
Vala. You can download them from launchpad using bazaar:

        bzr checkout lp:~elementary-apps/+junk/cmake-modules
        
It will create a folder called *cmake-modules*. Inside will be a folder called
*cmake*. Copy the later to your project folder.

The first thing to do is initializate the project. This is done by calling
autovala in your desired project's folder with:

        autovala init PROJECT_NAME
        
This will create a PROJECT_NAME.avprj file, with the most basic info about
your project (the format for this file will be explained later). It will also
try to create the basic folders for a vala project, and will show a warning
if they already exist. It will never delete a file, except the CMakeLists,
files, of course.

After that, you can copy the desired files into the corresponding folders,
and create your vala source files. When you are OK for the first compilation,
just do Autovala to check the folders and automatically update the .avprj file
with:

        autovala refresh
        
Now the .avprj has all the guessed info about your project, so you can
create the CMakeLists files from that data using:

        autovala cmake

Since it's very common to call those two commands, one after the other,
you can just use:

        autovala update

which will, first, update your .avprj file, and if there are no errors,
will regenerate the CMakeLists files, all in one command.

These commands can be called from any of the folders or subfolders of the
project, because it will search for the first .avprj file located in the
current folder or upstream.


## PROJECT FILE FORMAT ##

The project file has a very simple format. Ussually you should not need to
manually edit it, but when the guesses of autovala are incorrect, you can do
it, and your changes will be remembered each time you refresh the file.

The file is based on commands in the format:

        command: data

One in each line. Every line that starts with # is ignored (is a comment),
but also will be removed when the file is recreated.

The first line in a project file is, always, ### AutoVala Project ###. This
string identifies it as an Autovala project file.

The next line has the command "autovala_version". This command specifies which
version of the syntax uses this file, to avoid an old version of Autovala
to open a newer, with commands that it wouldn't understand.

The next line has the command "project_name". This command sets the name
assigned to this project.

Then, the next line contains "vala_version", which specifies the minimum Vala
version needed to compile this project. By default, it is filled with the
version number of the vala version installed when the project was created.

After that, it comes several commands, some of them repeated several times,
to specify what to do with each file in your project. These commands are:

 * po: specifies the folder where to store the translations. By default it's "po".
    The program identifier for Gettext is the project name.

 * data: specifies a folder with local data that must be installed in
      share/project_name
      
 * vala_binary:  contains a path and a name, and specifies that, in the path, there
              are several source files that must be compiled to create that
              binary. Example:
              
        vala_binary: src/test_file
                      
   says that the src
   folder contains the source files to create the binary test_file
   After this command will come several subcommands that specifies
   details about this binary. Those are:
             
   * version: contains the version of this binary file. It is more useful when
             creating libraries. If it is not set manually in the project file,
             Autovala will check the source files for a global variable with
             the format:
             
                   const string project_version="X.Y.Z";
               
   and will use that number as version. If it is unable to find it
   in none of the source files, then it will use 1.0.0 by default.
             
   * namespace: contains the namespace used in all the source files. It is more
               useful when creating libraries.
               
   * compile_options: contains the options to pass to the Vala compiler. Example:
   
                     compile_options: -X -O2

   * vala_package: specify a package that must be added with --pkg=... to the
                  vala compiler. These are automatically found by Autovala
                  by reading the sources and processing the "Using" directives
                  
   * vala_check_package: is like vala_package, but these packages must, also,
                        be checked during cmake to ensure that they are
                        installed in the system. Autovala founds these
                        automatically by reading the sources, as with
                        vala_package, and checking if the corresponding .pc
                        file exists
                        
   * vala_source: this command specifies one source file that belongs to this
                 binary
                 
               The last three subcommand can be repeated as many times as
               needed to specify all the sources and packages needed.
                 
 * vala_library: the same than vala_binary, but creates a dynamic linking library.
              It uses the same subcommands.
              
 * binary: specifies that the file is a precompiled binary (or a shell script) that
        must be copied as-is to bin/
        
 * icon: followed by the category and the icon path/name. Autovala will determine
      the icon size and use it to copy it to the right place (only if it's a
      .png file; it it's a .svg will copy to "scalable"). Also, by default, the
      category will be "apps", unless it is a .svg with "-symbolic"; in that
      case will be put in the "status" category. Example:

              icon: apps finger.svg
      
 * pixmap: followed by a picture filename. Will be copied to share/pixmaps

 * glade: the file specified is a glade UI file, that will be installed in
       share/project_name/ These files, and the .vala source files, will
       be used with gettext to get the translatable strings.
       
 * dbus_service: the file specified is a D-Bus service. The file must be written
              as a classic D-Bus service file, but prefixing the binary
              filename with @DBUS_PREFIX@. Example from Cronopete:
              
              [D-BUS Service]
              Name=com.rastersoft.cronopete
              Exec=@DBUS_PREFIX@/bin/cronopete
              
   This allows to use cmake to install everything in a temporary
   folder, and ensure that the Exec entry points to the right place.
   This is important when using these CMakeLists files for creating
   a .deb or .rpm package.
              
 * desktop: the file specified is a .desktop file that must be copied to
         share/applications to ensure that it is shown in the applications menu
         
 * eos_plug: the file is an ElementaryOS plug for the configuration system

 * scheme: the file is a GSettings file that contains configuration settings.
        It is automagically compiled if needed.
        
 * autostart: the file is a .desktop one, but must be installed in
           /etc/xdg/autostart because the program specified there must be
           launched automatically when starting the desktop session. Don't
           forget to add X-GNOME-Autostart-enabled=true inside
           
 * include: allows to include the specified file in the CMakeLists of its path
         This allows to manually add CMake statements. Example:
         
                 include: src/mycmake.txt
         
         will append the contents of the file mycmake.txt, located in the src/
         folder, to the end of the CMakeLists.txt file also located in the
         src/ folder
         
 * ignore: the path that follows will be ignored when Autovala guesses each
        file. Examples:
        
        ignore: src/PROG/test.vala will ignore the file test.vala when automatically creating the PROG binary
                                   
        ignore: src/OTHER will ignore the folder OTHER when creating binaries


## KEEPING YOUR CHANGES ##

By default, nearly all the lines in the project file starts with an asterisk.
Those lines contains automatically created commands, and every time the user
launches the command "autovala refresh", they are deleted and recreated using
the current files in the disk.

Lines without the asterisk contains manually set commands, and they are not
deleted before recreating the project file.

Also, when an automatically created vala_library or vala_binary (this is,
prefixed with the asterisk) contains at least one subcommand added
manually, that command will be considered manually added too, so it will
be preserved even if you delete its folder. This is made this way to ensure
that the manual data is preserver always.

Example: let's supose we have this project file:

    ### AutoVala Project ###
    autovala_version: 1
    project_name: autovala
    vala_version: 0.16
    *po: po

    *vala_binary: src/autovala
    *version: 1.0.0
    *vala_package: posix
    *vala_check_package: gee-1.0
    *vala_check_package: glib-2.0
    *vala_check_package: gtk+-3.0
    *vala_source: cmake.vala
    *vala_source: generate.vala
    *vala_source: configuration.vala
    *vala_source: autovala.vala

We can see that all the commands have been added automatically, because they
are prepended by an asterisk.

Let's say that the version number is incorrect; we want the version number
0.1.0. So I edit the file and modify it to look like this:

    ### AutoVala Project ###
    autovala_version: 1
    project_name: autovala
    vala_version: 0.16
    *po: po
    
    *vala_binary: src/autovala
    *version: 0.1.0
    *vala_package: posix
    *vala_check_package: gee-1.0
    *vala_check_package: glib-2.0
    *vala_check_package: gtk+-3.0
    *vala_source: cmake.vala
    *vala_source: generate.vala
    *vala_source: configuration.vala
    *vala_source: autovala.vala

This change is *INCORRECT*, because I kept the asterisk in the line I changed.
That means that the next time that I run "autovala refresh" or "autovala update"
that change will dissapear.

To ensure that my change remains, it must be put in a line without the asterisk
This is:

    ### AutoVala Project ###
    autovala_version: 1
    project_name: autovala
    vala_version: 0.16
    *po: po

    *vala_binary: src/autovala
    version: 0.1.0
    *vala_package: posix
    *vala_check_package: gee-1.0
    *vala_check_package: glib-2.0
    *vala_check_package: gtk+-3.0
    *vala_source: cmake.vala
    *vala_source: generate.vala
    *vala_source: configuration.vala
    *vala_source: autovala.vala

Now the change will remain, no matter how many times I run "autovala refresh"
or "autovala update".


## TO DO ##

This is still version 0.1.0. It is fully usable, but there are still a lot of
things that I want to add to it, and I will need help.

 * Allow that a binary being compiled be able to use a library compiled in the
   same project
   
   This is a must if I want to distribute Autovala both as a library, and as
   a command line program that uses that library.
   
 * Generate automatically the .pc file for a library (for pkg-config)
 
   I need help with the format of the .pc files

 * Integrate it as a plugin for Gedit


## CONTACTING THE AUTHOR ##

Sergio Costas Rodriguez
(Raster Software Vigo)

raster@rastersoft.com

http://www.rastersoft.com

GIT: git://github.com/rastersoft/autovala.git
