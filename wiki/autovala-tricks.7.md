Autovala-tricks(1)

# NAME

Autovala tricks - Several tricks for Autovala

## Using Valama

Autovala can export a project to a Valama project, allowing to use this great editor.

It is a good idea to refresh the data in the Autovala project using *autovala refresh* before exporting it with *autovala valama*.

When the Autovala project contains several binaries, it will generate one Valama project for each one. Also, if one binary depends of another one, both will be added in the same Valama project. This allows to better edit both. An example is Autovala itself: it is a main library, *autovalaLib*, used by the main executable, *autovala*, and another library, *autovalaPlugin*.

Remember that, currently, this support is extremely limited. This means that you must update your Autovala project with *autovala update* manually from command line, and sometimes you will have to use again *autovala valama* and open again the Valama project to reflect some changes in the editor. I hope to add, in a near future, more support.

## Using SVG icons for several sizes of the same icon

Sometimes it is a good idea to have diferent pictures for the same icon, using one or another for diferent sizes. When the icons are in **png** format, there are no problems, but with **svg** icons, if the final theme has scalable entries, all of them will go there. To avoid this, just open the **.avprj** file and replace the command **full_icon** with **fixed_size_icon**. This command will always use the canvas size of the **svg** file to determine the fixed size entry where to put it, and will never place an **svg** icon in an scalable entry. For **png** files it works exactly the same that **full_icon**.


## Using alternative CMAKE files

When updating the CMAKE files for Vala, Autovala will check if the **AUTOVALA_CMAKE_SCRIPT** environment variable is defined with a path. If that is the case, it will copy from that path the CMAKE scripts for the project, instead of using the default ones.


## Creating packages for linux distributions

AutoVala can create the metadata files for creating .deb and .rpm source packages. It should be easy to add support for other package systems.

To generate .deb files, just run **autovala deb**. It will create a folder called **debian** and inside will be the **control**, **changelog** and **rules** files, and, if needed, **preinst**, **prerm**, **postinst** and **postrm**. The **control** file will have only the bare minimum, but autovala will include inside the dependencies needed both for building the package, and for running the project. These dependencies are generated automatically from the information extracted from the project. The **changelog** will add a boilerplate line only if there is no line for the current version, so it is strongly recommended to edit and complete this file after doing the automatic generation.

The **rules** file is designed to be compatible with **launchpad**. Also it is possible to manually generate a binary package by running, from the project's root folder, these commands:

    ./debian/rules clean
    ./debian/rules build
    ./debian/rules binary-arch

To generate .rpm files, just run **autovala rpm**. It will create the folders **rpmbuild/SPECS/**, and inside will be the **.spec** file with the metadata. Then, edit that file to set some of the fields that can't be automatically filled (like the LICENSE one), go to **rpmbuild** folder and run:

    rpmbuild --define "_topdir `pwd`" -ba SPECS/PROJECT_NAME.spec

This will create the RPM package in **rpmbuild/RPMS**. At this moment, the source RPM package at **rpmbuild/SRPMS** is empty, so don't use it.

If the project needs an extra package that can't be determined automatically by autovala, it is possible to mark it in a distro-agnostic way, by using the commands **source_dependency** and **binary_dependency** in the **.avprj** file. The first one points to a file in the system that is needed for building the project; when generating the package metadata, autovala will add as a Build-Dependency the package that contains that file. The second one points to a file in the system that is needed for using the project; when generating the package metadata, autovala will add as a Dependency the package that contains that file.

There are several fields extracted from the source itself. The **Description** is extracted from the **README** or **README.md** file. If the file is a pure text one, all it will be used; if it is a markdown one, only the first section will be used.

The package name will be set to the project name.

Finally, the author's name and email will be asked the first time a package is created, but it will be stored at **$HOME/.config/autovala** to be used when creating new packages.

When the metadata files are edited, the changes will be kept except the dependencies build-dependencies fields, that will be overwritten each time the package metadata is recreated. The other files (if they exist) are created only if they didn't exists; if they are already in the folder, they won't be modified, so it is possible to edit them without loosing the changes.


## Adding more package types

As commented, Autovala can generate the metadata por .deb and .rpm source packages. To add more package types, only a new class, derived from **packages** class, must be created. After initializing it and calling **init_all** method, the class should generate the files needed by the packaging system. To help into it, there are several properties that contains useful data, like a list of files needed to build the project (.vapi and .pc files), and for running it (like libraries). The class must use the package utilities to discover which packages contains those files, and use them for generating the dependencies.


## Writing unitary tests

To write unitary tests, just create a folder called **unitests** in the root folder of your executable/library folder. Each **.vala** source file inside it will be considered an unitary test, and will be compiled against **ALL** source files of its executable/library.

When an unitary test is being compiled, it is done with the option **UNITEST**, so you can use **#if UNITEST** and **#if !UNITEST** to add or remove code in the project's source that should or shouldn't go with unitary tests (an example is the **main** function).

If an unitary test needs to use data files, it can use the **Constants** namespace to gain access to the original source path. When compiling the tests, there will be a new variable, called **TESTSRCDIR** that contains the full path to the project folder, allowing the unitary test to easily get access to all the files in the project. This variable **doesn't exist** when compiling an executable or library, only unitary tests.

To check the tests, just run **make test** in the **install** folder.

An example with two binaries:

        +src/
           +unitests/
           |  +test1.vala
           |  +test2.vala
           +file1.vala
           +file2.vala
           +binary2/
              +file3.vala
              +file4.vala
              +unitests/
                 +test3.vala
                 +test4.vala
                 +test5.vala

Here, the first binary, created with **file1.vala** and **file2.vala**, has two unitary tests: **test1.vala** and **test2.vala**. The binary for the first unitary test will be created by compiling **file1.vala**, **file2.vala** and **test1.vala** in a single executable; the binary for the second unitary test will be created by compiling **file1.vala**, **file2.vala** and **test2.vala**. The second binary is created with **file3.vala** and **file4.vala**, and has three unitary tests: **test3.vala**, **test4.vala** and **test5.vala**.


## Using the math library

GLib includes the namespace GLib.Math, that contains all the C Math library functions. To use it from C it is mandatory to pass *-lm* to the compiler.

In Autovala, instead, you only need to add at the start of your code an **using** statement with the namespace to ensure that the library will be linked. To do so, just use:

    //using GLib.Math

(you can put it inside a comment, and Autovala will also understand it).


## Creating an Autovala plugin for a GTK3 text editor

Version 0.97 includes a library with two widgets, ProjectViewer and FileViewer, that greatly simplifies the task of creating a plugin for manage Autovala projects. An example of its use can be seen in the Gedit plugin for Autovala, available in a folder with the Autovala source code.


## Updating projects with new versions of Autovala

Every time autovala gets updated, doing "autovala update" or "autovala cmake" will update the *CMaleLists.txt* for that project, so it will take advantage of all the new features added in the new Autovala version.


## Rules followed by autovala to decide which valac version to use

Some source-based distros (like gentoo) doesn't set a soft link *valac* pointing to a default vala compiler version. This behaviour is intentional, to allow to choose with which version compile the packages.

Until version 0.95.0, autovala projects could not be compiled under these distros, unless the user creates manually the link. In version 0.96.0 this has been fixed. The rules to decide which compiler version to use are the following:

  * During project update, if there is a *valac* symlink, will use that version number to update the *.avprj* file; if not, will use the biggest version available in the system.
  * During compilation: if the specific version set in the *.avprj* is available, will use it; if not, but there is a *valac* symlink, and its version is equal or greater than the set in the *.avprj* file, will use it. In other case, will return an error.

These rules are used for default compilation. It is possible to manually force an specific valac binary for compilation with:

        cmake .. -DUSE_VALA_BINARY=/path/to/a/valac/binary


## Autogenerating DBus bindings

Starting from version 0.92.0, autovala can use **vala-dbus-binding-tool** to generate automatically bindings for a DBus service. This process is done whenever **autovala cmake** or **autovala update** is done.

To add a DBus binding to an executable, just edit your *.avprj* file and, in the executable section (this is, after a *vala_binary* or *vala_library* statement), add a line like this:

        dbus_interface: connection_name  object_path  session/system  [gdbus/dbus-glib]

This will tell autovala to generate bindings for the object *object_path* in the connection *connection_name*, which sits in the *session/system* bus. By default, the syntax will be for *gdbus*, unless you add an extra parameter at the end, *dbus-glib*, which will force to generate syntax for the old dbus-glib bindings.

An example: the following line

        dbus_interface: org.freedesktop.ConsoleKit /org/freedesktop/ConsoleKit/Manager system

will generate bindings for the */org/freedesktop/ConsoleKit/Manager* object.


## Using the **Constants** namespace and variables

Autovala will create a **Constants** namespace with several strings in it that specifies things like the project version or the final directory. These strings allow to simplify several things, like initializing the **gettext** functions, getting access to the version number set in the code, or getting access to **glade** files, as explained in the following entries.


## Setting the version number

To simplify the maintenance of the code, Autovala allows to set the version number in an easy way inside the source code of your binary or library. That way you will always be sure to use the right number both for the **About** and **--version** commands, and for the library major and minor values.

To do so, just put in one (no matter which) of the **.vala** source files the following statement:

        // project version=XX.YY.ZZ

As expected, this will define a global string with the version number inside. The interesting thing is that Autovala will peek inside all the source files for this kind of string, and will use it whenever it needs a version number. For binaries maybe is not really very useful, but for libraries it is, because there you can set the major and minor version numbers.

The format for the version number can be both **XX.YY** or **XX.YY.ZZ**, but **X**, **Y** and **Z** must be numbers. So you can use **0.5.34** or **12.5** as version numbers, but not **1.4rc1**, **7**...

If no version number is defined in the source code, nor manually set in the project file, Autovala will use **1.0.0** whenever it needs it.

There was an old method, which was putting the statement:

        const string project_version="XX.YY.ZZ";

This method is now deprecated, because you can still access the version number through the **Constants** namespace. As an example, to print the version number, just use:

        GLib.stdout.printf("Version: %s\n",Constants.VERSION);

This new method allows to set the version number in libraries too, without symbol clash, because in libraries, the library namespace will be used to define the constants namespace. So, as an example, if we are creating a library **MyExampleLibrary**, which has all its code inside the namespace **exampleLibrary**, to print the library version from inside the library just use:

        GLib.stdout.printf("Library version: %s\n",exampleLibraryConstants.VERSION);


## Using GETTEXT

To initialize **gettext** it is mandatory to specify both the package name and the folder with the **.mo** files. This is as simple as using the **Constants** namespace with this code:

        Intl.bindtextdomain(Constants.GETTEXT_PACKAGE, Path.build_filename(Constants.DATADIR,"locale"));
        Intl.setlocale (LocaleCategory.ALL, "");
        Intl.textdomain(Constants.GETTEXT_PACKAGE);
        Intl.bind_textdomain_codeset(Constants.GETTEXT_PACKAGE, "utf-8" );

For libraries, you must call only:

        Intl.bindtextdomain(LibraryConstants.GETTEXT_PACKAGE, path.build_filename(LibraryConstants.DATADIR,"locale"));

being **LibraryConstants** the library Constants namespace. The package name is the same than the project's name.


## Using GLADE files

**Glade** files are stored at **/usr/share/PROJECT_NAME/** or **/usr/local/share/PROJECT_NAME/**. To get access to them, just use the Constants namespace. As an example, to load the **example.ui** glade file, just do:

        var data = new Builder();
        data.add_from_file(GLib.Path.build_filename(Constants.PKGDATADIR,"example.ui"));


## Creating several binaries

By default, Autovala presumes that every source file inside **src** or its subdirectories belongs to a single binary. But maybe you want to generate several binaries because your program needs several executables.

Let's suppose that you have a project called **myproject**, with a folder hierarchy inside **src** like this:

        src
         +file1.vala
         +file2.vala
         +a_folder
         |   +file3.vala
         |   +file4.vala
         |
         +another_folder
             +file5.vala
             +file6.vala


And let's suppose that you want to compile **file5.vala** and **file6.vala** as a different executable called **otherprogram**. By default, after running **autovala refresh**, it will create a single executable called **myproject**, using all the source files ( **file1.vala** to **file6.vala** ), and the **.avprj** file will look like this:

        ### AutoVala Project ###
        autovala_version: 4
        project_name: myproject
        vala_version: 0.16

        *vala_binary: src/myproject
        [several commands specific of this binary]

What we have to do is add a new **vala_binary** command to the file, specifying the path and the executable name we want (and WITHOUT an asterisk before; read [Keeping your changes](autovala-keep-changes.7) to understand why). So edit it and add this:

        ### AutoVala Project ###
        autovala_version: 4
        project_name: myproject
        vala_version: 0.16

        vala_binary: src/another_folder/otherprogram
        *vala_binary: src/myproject
        [several commands specific of this binary]

Save it and run **autovala update**. If you edit again the project file, you will see that Autovala automatically added all the packages and other data to the new executable, and will keep doing every time you run it.


## Creating libraries

Creating a library is as easy as editing the project file and replacing the command **vala_binary** with **vala_library** and running again **autovala update**.

When creating a library, Autovala will peek the source files and check the namespace used inside. If all files uses the same namespace, it will use it, by default, as the name for the library, and also to generate the **.vapi**, **.gir** and **.pc** files. Of course, is possible to set this name manually by editing the project file and modifying the command **namespace**.

The major and minor numbers for the library are taken from the version number set by the user (read the entry **Setting the version number**). They will be used for the library itself, the **.vapi** and the **.pc** files. The **.gir** introspection file uses the version number **major.0** instead of **major.minor** to ensure compatibility.

Libraries also can have the constants namespace, but modified to avoid clash between the variables in the library and the same in the binary. The final namespace for constants namespace in libraries is **libraryNameSpaceConstants**. Of course, this will work ONLY IF YOUR LIBRARY HAS DEFINED A NAMESPACE. If not, this variables will NOT be added.

An example: if your library uses the namespace **aBeautifulNameSpace**, then the namespace for the constants will be **aBeautifulNameSpaceConstants**.


## Linking an executable against a library from the same project

Let's say that the project contains one or more libraries and an executable, and the executable must use that library we are creating in the same project.

Let's supose that the executable is **myExecutable**, and the library is **myLibrary** (using the namespace **myLibrarynamespace**). The **.avprj** file will look like this:

        ### AutoVala Project ###
        autovala_version: 4
        project_name: myproject
        vala_version: 0.16

        vala_library: src/mylibrary_src/myLibrary
        [several commands specific of this library]
        
        *vala_binary: src/myExecutable
        [several commands specific of this binary]

To allow **myexecutable** to use **mylibrary**, just add to **myexecutable** a **vala_local_package** statement with the namespace of the library it needs. In this example, the **.avprj** will become:

        ### AutoVala Project ###
        autovala_version: 4
        project_name: myproject
        vala_version: 0.16

        vala_library: src/mylibrary_src/myLibrary
        [several commands specific of this library]
        
        *vala_binary: src/myExecutable
        vala_local_package: myLibrarynamespace
        [several commands specific of this binary]

Run **autovala update**, **cmake ..**, and everything should compile fine.

Of course, if your executable needs several local libraries, you have to add one **vala_local_package** statement per library.


## Compiling Valadoc in Ubuntu

At the time of writing this, the version of Valadoc shipped with Ubuntu 12.10 has a bug and sometimes fails. The solution is to manually compile it from the sources.

To get the sources, just use

        git clone http://git.gnome.org/browse/valadoc

Then, don't forget to uninstall the **valadoc** and **libvaladoc1** packages, install the packages **autoconf**, **libgee-0.8-dev** and **libgraphviz-dev**, and then just run

        ./autogen.sh
        make
        sudo make install
        sudo ldconfig


## Using D-Bus service files

A D-Bus service file is a file that specifies which binary provides a specific D-Bus service. To ensure that Autovala find them, you must put these files in the **data/** folder, and ensure that their extension is **.service**.

The problem with these files is that the binary path must be expressed in absolute format; this is: if the binary to run is **mybinary**, you have to put **/usr/bin/mybinary**, or **/usr/local/bin/mybinary**, or the full path where **mybinary** is. This can be a problem, because with CMake, by default, uses **/usr/local/bin**, unless you specify it to use **/usr/bin** when creating a **.deb** or **.rpm** package.

To avoid this problem, you only need to use the macro **\@DBUS_PREFIX\@** in the path. This CMake macro will be expanded automatically to the base path ( **/usr** or **/usr/local** ), so you only will need to add **bin/** and the binary name.

An example (extracted from Cronopete):

            [D-BUS Service]
            Name=com.rastersoft.cronopete
            Exec=@DBUS_PREFIX@/bin/cronopete

In this file, the **com.rastersoft.cronopete** service is provided by the binary **cronopete**. The specific folder ( **local** or not **local** ) will be determined automatically by Autovala.


## Installing a project in a different final folder

You can set the **CMAKE_INSTALL_PREFIX** variable to define where to install the project. So, if you run

            cmake .. -DCMAKE_INSTALL_PREFIX=/usr

the project will be installed in **/usr** instead of **/usr/local**. Also, if you run

            cmake .. -DCMAKE_INSTALL_PREFIX=$HOME/tmp

the project will be installed in your personal directory.


## Creating packages for a Linux distro

To create packages, you must set the install prefix to **/usr** like in the previous entry, and also specify to install everything in a temporal folder. This is made with the **DESTDIR** statement when running **make install**. For example, to create a package in the folder **$HOME/tmpfolder**, you should do:

            cmake .. -DCMAKE_INSTALL_PREFIX=/usr
            make
            make install DESTDIR=$HOME/tmpfolder


## Using GIO, GIO-unix, GObject, GModule or Math packages

There are some exceptions for **using** and package autodetection. Since the packages **GIO**, **GIO-unix**, **GObject**, **GModule** and **Math** are included inside the **GLib** namespace, Autovala requires them to be manually marked by adding **//using [package name]**. Since it is a comment, it won't be processed by Valac, but will be understood by Autovala and add the required **-pkg** command (or **-lm** in the case of Math).


## Using conditional compilation to allow to use GTK2 and GTK3

An special case is when supporting both GTK2 and GTK3 with the same source code is desirable. It is possible to do it by using conditional compilation.

First, decide a statement to choose between both libraries. Let's say USE_GTK2.

In your source code use **#if USE_GTK2**, **#else** and **#endif** for keeping sepearated the code parts where GTK2 and GTK3 differs.

In your **.avprj** file use conditional compilation for choosing the libraries with these lines:

		if USE_GTK2
		vala_check_package: gtk+-2.0
		vala_check_package: gdk-2.0
		else
		vala_check_package: gtk+-3.0
		vala_check_package: gdk-3.0
		vala_check_package: glib-2.0
		end

Finally, if you have different **glade** files for each library version, use also conditional compilation in your **.avprj** file:

		if USE_GTK2
		glade: data/interface2/file1.ui
		glade: data/interface2/file2.ui
		glade: data/interface2/file3.ui
		else
		glade: data/interface/file1.ui
		glade: data/interface/file2.ui
		glade: data/interface/file3.ui
		end


## Mixing VALA and C source files

It is possible to mix in the same binary or library VALA and C source files, but is mandatory to manually create a **.vapi** file to access from VALA to the C functions.

To access from C to the Vala functions, just include the corresponding header files. During compilation, cmake will add **-I[whatever]/install/src/[whatever]**, so the **.h** files created by **valac** will be available to the **.c** files.

To add libraries needed only for the C sources, just use **c_check_package** instead of **vala_check_package**.


# SEE ALSO

[autovala(1)](autovala.1) [autovala-fileformat(5)](autovala-fileformat.5) [autovala-keep-changes(7)](autovala-keep-changes.7) [autovala-rules(7)](autovala-rules.7)


# AUTHOR

Sergio Costas Rodriguez  
raster@rastersoft.com  
http://www.rastersoft.com  
http://github.com/rastersoft  
