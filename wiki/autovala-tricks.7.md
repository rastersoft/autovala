Autovala-tricks(1)

# NAME

Autovala tricks - Several tricks for Autovala

## Setting the version number

To simplify the maintenance of the code, Autovala allows to set the version number in an easy way inside the source code of your binary or library. That way you will always be sure to use the right number both for the **About** and **--version** commands, and for the library major and minor values.

To do so, just put in one (no matter which) of the **.vala** source files the following statement:

        // project version=XX.YY.ZZ

As expected, this will define a global string with the version number inside. The interesting thing is that Autovala will peek inside all the source files for this kind of string, and will use it whenever it needs a version number. For binaries maybe is not really very useful, but for libraries it is, because there you can set the major and minor version numbers.

The format for the version number can be both **XX.YY** or **XX.YY.ZZ**, but **X**, **Y** and **Z** must be numbers. So you can use **0.5.34** or **12.5** as version numbers, but not **1.4rc1**, **7**...

If no version number is defined in the source code, nor manually set in the project file, Autovala will use **1.0.0** whenever it needs it.

There was an old method, which was putting the statement:

        const string project_version="XX.YY.ZZ";

This method is now deprecated, because you can still access the version number through the **Constants** namespace, and with the new method you can set the version number in libraries too, without symbol clash.

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

## Using GIO, GIO-unix, GObject or GModule packages

There are some exceptions for **using** and package autodetection. Since the packages **GIO**, **GIO-unix**, **GObject** and **GModule** are included inside the **GLib** namespace, Autovala requires them to be manually marked by adding **//using [package name]**. Since it is a comment, it won't be processed by Valac, but will be understood by Autovala and add the required **-pkg** command.

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

# SEE ALSO

[autovala(1)](autovala.1) [autovala-fileformat(5)](autovala-fileformat.5) [autovala-keep-changes(7)](autovala-keep-changes.7) [autovala-rules(7)](autovala-rules.7)

# AUTHOR

Sergio Costas Rodriguez  
raster@rastersoft.com  
http://www.rastersoft.com  
http://github.com/rastersoft  
