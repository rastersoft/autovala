# Autovala-fileformat(5)

## NAME

autovala fileformat - The syntax for autovala configuration file

## DESCRIPTION

The project file has a very simple format. Usually you don't need to manually edit it, but when the guesses of autovala are incorrect, you can do it, and your changes will be remembered each time you refresh the file.

The current version for the project file format is **27**.

The file is based on commands in the format:

        command: data

one in each line. Each command can be optionally be prefixed with an asterisk (*). In that case, it is assumed that the command has been created automatically by AutoVala, after applying the guessing rules, and will be erased and regerenated every time the .avprj file is recreated. If the command lacks the asterisk, it is assumed that it has been manually added by the user, so it will be preserved between refreshes.

Every line that starts with # is ignored (is a comment), but they will be associated with the next command. This means that comments will be preserved, as long as they are associated with a manually added command; comments put before an automatically added command will be lost.

Except where otherwise is specified, the paths must be relative to the project path.

The first line in a project file is, always, ### AutoVala Project ###. This string identifies it as an Autovala project file.

The next line has the command **autovala_version**. This command specifies which version of the syntax uses this file, to avoid an old version of Autovala to open a newer, with commands that it wouldn't understand.

The next line has the command **project_name**. This command sets the name assigned to this project.

Next line can contain **project_version**. This allows to set a default version number for the project. Thus, every binary or library that doesn't specify a version number will take it from this. The version can be defined as *X.Y* or *X.Y.Z* (being X, Y and Z numbers with one or more digits).

Then, the next line contains **vala_version**, which specifies the minimum Vala version needed to compile this project. By default, it is filled with the version number of the vala version installed when the project was created.

After that, it comes several commands, some of them repeated several times, to specify what to do with each file in your project. These commands are:

 * **po**: specifies the folder where to store the translations. By default it is **po**. The program identifier for Gettext is the project name.

 * **define**: specifies a condition parameter set in a **#define** statement in the source code, for conditional compilation. These parameters can be set during Makefile creating with **-Dparameter=ON**, and will be passed to **valac** during compilation.

 * **data**: specifies a folder with local data that must be installed in **share/project_name**. By default it is **data/local**.

 * **doc**: specifies a folder with the documentation that must be installed in **share/doc/project_name**. By default it is **doc**.

 * **appdata**: specifies an AppData file, which contains metadata about the application (details at http://www.freedesktop.org/software/appstream/docs/chap-Metadata.html and http://www.freedesktop.org/software/appstream/docs/chap-Quickstart.html#sect-Quickstart-DesktopApps). When creating packages, Autovala will try to take data from this file if it exists, like a summary and a description.

 * **gresource**: specifies a GResource file and an identifier for it. Example:

            gresource: data_gresource_xml data/data.gresource.xml

    the identifier is used in the binaries/libraries to specify which resource file to include there, and the path specifies where is the XML file with the GResources data. AutoVala will check the files specified inside, to prevent adding them automatically in other parts (example: if you have an icon file in *data/icons*, by default it will be installed at */usr/share/icons...*; but if that file is inside a *gresource* file, it won't be installed, unless you add it manually to the .avprj file). Also, those files will be added as dependencies, so any change to any of them will force a recompilation of the corresponding object file and binaries.

 * **vapidir**: points to a folder where extra VAPI files can be found. This is a global path, used in all binaries and libraries used in the project (unlike the *vapi_file* statement, that is binary-specific). This command is useful when a program puts their .vapi files in a non-standard folder (which is the current case of Gnome-Builder), or when you have a library installed in your system but it doesn't include a .vapi file. When asking the file list with the *project_files* command-line parameter, it will include the .vapi files inside these folders only if the folder is relative to the project's folder; if it is an absolute path (which points, let's say, to /usr/share...) won't list those .vapi files.

 * **vala_binary**:  contains a path and a name, and specifies that, in the path, there are several source files that must be compiled to create that binary. Example:

            vala_binary: src/test_file

    says that the src folder contains the source files to create the binary test_file.

    After this command will come several subcommands that specifies details about this binary. Those are:

    * **version**: contains the version of this binary file. It is more useful when creating libraries. If it is not set manually in the project file, Autovala will check the source files for a global variable with the format:

                // project version=XX.YY.ZZ

        and will use that number as version. If it is unable to find it in none of the source files, then it will use 1.0.0 by default.

    * **namespace**: contains the namespace used in all the source files. It is more useful when creating libraries.

    * **vala_destination**: specifies a custom path where to install this library or binary. If the path is given in relative format (this is, if it doesn't start with an slash) the file will be installed relative to the PREFIX (**/usr** or **/usr/local**); but if it is given in absolute format (this is, the path starts with a slash) the file will be installed in that precise folder.

    * **compile_options**: contains the options to pass to the Vala compiler. Example:

                compile_options: -g

        It is possible to specify a *build type* using @TYPE. Example:

                compile_options: @Debug -D USING_DEBUG_TYPE

        will pass the definition "USING_DEBUG_TYPE" to the vala compiler when cmake is called with -DCMAKE_BUILD_TYPE=Debug.

        It is possible to use any of the four predefined *build types* (Debug, Release, RelWithDebInfo and MinSizeRel), and also it is possible to define new types.

        By default, Autovala will add '-g' to the compiler options for the *Debug* and *RelWithDebInfo* types, thus ensuring that the debugging will work with the CMake standard system.

        When cmake is called without specifying a *build type*, the *Release* one will be used by default.

    * **compile_c_options**: contains the options to pass to the C compiler and linker. Example:

                compile_c_options: -O2

        It is also possible to specify a *build type* using @TYPE. Example:

                compile_c_options: @Debug -DUSING_DEBUG_TYPE_AT_C -Os

        will pass the definition "USING_DEBUG_TYPE_AT_C" and the option **-Os** to the C compiler when cmake is called with -DCMAKE_BUILD_TYPE=Debug.

        It is possible to use any of the four predefined *build types* (*Debug*, *Release*, *RelWithDebInfo* and *MinSizeRel*), and also it is possible to define new types. This command works by adding the options to CMAKE_C_FLAGS_XXXXX (being XXXXX the *build type* specified after the @, converted to uppercase).

    * **vala_package**: specify a package that must be added with **--pkg=...** to the vala compiler. These are automatically found by Autovala by reading the sources and processing the **Using** directives

    * **vala_check_package**: is like **vala_package**, but these packages must, also, be checked during cmake to ensure that they are installed in the system. Autovala finds these automatically by reading the sources, as with vala_package, and checking if the corresponding **.pc** file exists

    * **c_check_package**: is like **vala_check_package**, but will be added only when compiling and linking the C code, not to the Vala compiler. It is useful when mixing Vala and C sources and the C code needs a library that the Vala source doesn't need.

    * **vala_local_package**: is like **vala_package**, but these packages aren't installed in the system. Instead, they belong to this project, and will be compiled automatically before this binary/library.

    * **vala_source**: this command specifies one VALA or GENIE source file that belongs to this binary. The path must be relative to the binary/library path.

    * **c_source**: this command specifies one C source file that belongs to this binary. The path must be relative to the binary/library path.

    * **h_folder**: this command specifies one folder containing .h files that must be included when compiling the C source files in this binary. The path must be relative to the binary/library path.

    * **vala_vapi**: this command specifies one custom **.vapi** file, needed to compile your project. Each file must be prepended by the relative path from the project folder. The path must be relative to the binary/library path.

    * **dbus_interface**: this command specifies a DBus interface to be automatically extracted using introspection, and to generate a source file with it. It must be followed by the connection name (e.g. org.freedesktop.ConsoleKit), the object path (e.g. /org/freedesktop/ConsoleKit/Manager), and whether it must connect to the **system** or **session** bus. Finally, it can have an extra parameter specifying if the generated interface must be for **gdbus** (the default option) or for the obsolete **dbus-glib** library.

    * **c_library**: this command specifies one or more C libraries which must be linked against this binary (separated by blank spaces), useful for libraries not supported with **pkg_config** like the math C library. The libraries must be specified without the 'l' preffix; this is, the math library is 'm'; the posix threads library is 'pthread', and so on.

    * **unitest**: this command specifies one VALA source file that contains an unitary test. Each one of these files will be compiled with all the source files of this executable/library as a stand-alone executable. The path must be relative to the binary/library path. For details, read the FAQ.

    * **use_gresource**: this command instructs AutoVala to include in this binary the resources specified by an identifier. Example:

            use_gresource: data_gresource_xml

        Here, data_gresource_xml is the identifier used in a *gresource* command.

        The last fourteen subcommands (compile_options, compile_c_options, vala_package, vala_check_package, c_check_package, vala_local_package, vala_source, c_source, vala_vapi, dbus_interface, c_library, unitest and use_resource) can be repeated as many times as needed to specify all the sources and packages needed.

    * **alias**: allows to create a symbolic link to this binary; thus, the binary could be called with any of both names.

 * **vala_library**: the same than vala_binary, but creates a dynamic linking library. It uses the same subcommands with the exception of **alias**.

 * **bash_completion**: specifies that the file is a bash_completion stript that must be copied to where **pkg-config --variable=completionsdir bash-completion** specifies (usually /usr/share/bash-completion/completions). To allow to do installations in the HOME directory, these files won't be installed if *CMAKE_INSTALL_PREFIX* starts with */home*.

 * **binary**: specifies that the file is a precompiled binary (or a shell script) that must be copied as-is to **/usr/bin/** or **/usr/local/bin**.

 * **full_icon**: followed by the theme, the category and the icon path/name. Autovala will determine the icon size and use it to copy it to the right place (only if it is a **.png** file; it it is a **.svg** will copy to "scalable"). Also, by default, the cathegory will be **apps**, unless it is a **.svg** with **-symbolic**; in that case will be put in the **status** category. Example:

            full_icon: Hicolor Applications finger.svg

 * **fixed_size_icon**: similar to full_icon, but for **svg** icons, they will be put always in a fixed size entry, based on the canvas size; will never be put in an scalable entry. This is useful when there are several SVG pictures for different sizes of the same icon.

 * **pixmap**: followed by a picture filename. Will be copied to **share/pixmaps**

 * **glade**: the file specified is a glade UI file, that will be installed in **share/project_name/** These files, and the **.vala** source files, will be used with gettext to get the translatable strings.

 * **dbus_service**: the file specified is a D-Bus service. The file must be written as a classic D-Bus service file, but prefixing the binary filename with **@DBUS_PREFIX@**. Example from Cronopete:

            [D-BUS Service]
            Name=com.rastersoft.cronopete
            Exec=@DBUS_PREFIX@/bin/cronopete

    This allows to use cmake to install everything in a temporary folder, and ensure that the **Exec** entry points to the right place. This is paramount when using these CMakeLists files for creating a **.deb** or **.rpm** package.

    These files will be installed at *share/dbus-1/services* folder.

 * **dbus_system_service**: it is like *dbus_service*, but for D-Bus *system* services. These files, after being processed, will be installed at *share/dbus-1/system-services* folder.

 * **dbus_config**: specifies that the specified file is a dbus configuration file and it must be installed at **share/dbus-1/system.d**.

 * **desktop**: the file specified is a **.desktop** file that must be copied to **share/applications** to ensure that it is shown in the applications menu.

 * **eos_plug**: the file is an ElementaryOS plug for the configuration system

 * **scheme**: the file is a **GSettings** file that contains configuration settings. It is automagically compiled if needed.

 * **autostart**: the file is a **.desktop** one, but must be installed in **/etc/xdg/autostart** because the program specified there must be launched automatically when starting the desktop session. Don't forget to add **X-GNOME-Autostart-enabled=true** inside.

 * **include**: allows to include the specified file in the CMakeLists of its path. This allows to manually add CMake statements. Example:

            include: src/mycmake.txt

    will append the contents of the file **mycmake.txt**, located in the **src/** folder, to the end of the **CMakeLists.txt** file also located in the **src/** folder

 * **ignore**: the path that follows will be ignored when Autovala guesses each file. Examples:

            ignore: src/PROG/test.vala

    will ignore the file test.vala when automatically creating the PROG binary

            ignore: src/OTHER

    will ignore the folder OTHER when creating binaries

 * **custom**: followed by a path/filename and another path. Installs the specified file in the path. If the path is given in relative format (this is, if it doesn't start with an slash) the file will be installed relative to the PREFIX (**/usr** or **/usr/local**); but if it is given in absolute format (this is, the path starts with a slash) the file will be installed in that precise folder. Examples:

            custom: data/config_system.txt share/

    will install the file **config_system.txt** in **/usr/share** or **/usr/local/share**

            custom: data/config_system.txt /etc/myfolder

    will install the file **config_system.txt** in **/etc/myfolder**

 * **translate**: followed by a file type (currently *vala*, *c* or *glade*) and a path/filename. Specifies that the file must be included in the POTFILES.in file, to be scanned for translatable strings.

 * **manpage**: followed by a path/filename, and optionally a language and a page section. Specifies that the file is a man page in the specified language (**default** to install it in the default folder), and for the specified section. If the section is not specified, it will be assumed to be section 1. If the language is not specified, it will be assumed **default**. If the file ends in **.md**, Autovala will presume that it is a **markdown** file, and will convert it to groff before. Other supported formats and its extensions are HTML (**.html**), ReStructured Text (**.rst**), LaTeX (**.tex**), JSON version of native AST format (**.json**), TexTile/RedCloth (**.rdoc**), DocBook format (**.xml**) and MediaWiki (**.txt**). Examples:

            manpage: data/man/autovala.1

    will install the file **data/man/autovala** in **/usr/local/share/man/man1**

            manpage: data/man/autovala-rules.7.md es 7

    will install the file **data/man/autovala-rules** in **/usr/local/share/man/es/man7**

            manpage: data/man/autovala-modifying.5.md default 5

    will install the file **data/man/autovala-modifying** in **/usr/local/share/man/man5**

 * **source_dependency**: followed by one or more path/filenames (separated by spaces), it defines a system file needed for compiling the source, so, when creating a system package, the package that contains that file will be added to the build dependencies list. It will also be checked when creating the CMAKE files. If there are several paths, only one must exists to fullfill the condition. This is useful, for example, when checking for *pkgconfig* files, because in debian-based 64-bit systems they are stored at */usr/lib/pkgconfig*, but in fedora-based 64-bit systems they are at */usr/lib64/pkgconfig*.

 * **binary_dependency**: followed by one or more path/filenames (separated by spaces), it defines a system file needed for running the project, so, when creating a system package, the package that contains that file will be added to the dependencies list. It will also be checked when creating the CMAKE files. This is useful, for example, when checking for library files, because in debian-based 64-bit systems they are stored at */usr/lib*, but in fedora-based 64-bit systems they are at */usr/lib64*.

* **external**: followed by an onwer ID and a free-form text, allows to store custom data inside the project file, useful for external apps that integrates with autovala. Example:

            external: GEDIT custom_margin: 8
            external: GNOME_BUILDER ask_exit

* **mimetype**: followed by a filename, will manage it as an XML mime type file, installing it at *share/mime/packages*.

* **polkit**: followed by a filename, will consider it is a polkit policy file, and will install it at *share/polkit-1/actions*.

It is possible to ask autovalaLib to return all the external data for an specific owner, and to overwrite it, again for an specific owner, leaving unmodified the external data of other owners.

It is also possible to add conditions to nearly all of these commands (more specifically, all can be conditional with the exception of **vala_version**, **vala_binary**, **vala_library**, **version**, **namespace**, **project_name**, **define** and **autovala_version**). To do so, you can use the commands **if CONDITION**, **else** and **end**. The format for the **CONDITION** string is the CMake format (statements that can be true or false, parenteses, and AND, OR and NOT operators).

An example taken from Cronopete:

		vala_binary: src/cronopete
		*vala_package: posix
		*vala_check_package: gee-1.0
		*vala_check_package: cairo
		*vala_check_package: gsl
		if (NOT NO_APPINDICATOR) AND (NOT USE_GTK2)
		vala_check_package: appindicator3-0.1
		end
		if (NOT NO_APPINDICATOR) AND (USE_GTK2)
		vala_check_package: appindicator-0.1
		end
		if USE_GTK2
		vala_check_package: gtk+-2.0
		vala_check_package: gdk-2.0
		else
		vala_check_package: gtk+-3.0
		vala_check_package: gdk-3.0
		vala_check_package: glib-2.0
		end
		*vala_source: switch_widget.vala

By default, all the statements will be **OFF**, and the user must turn them on by adding **-Dstatement=ON** when calling CMake. So, in this example, to compile with GTK2, use:

    cmake .. -DUSE_GTK2=ON

All the statements inside an **if else end** block are marked as manual to ensure that AutoVala doesn't modify them.

## SEE ALSO

[autovala(1)](autovala.1) [autovala-rules(7)](autovala-rules.7) [autovala-keep-changes(7)](autovala-keep-changes.7) [autovala-tricks(7)](autovala-tricks.7)

## AUTHOR

Sergio Costas Rodriguez  
raster@rastersoft.com  
http://www.rastersoft.com  
http://github.com/rastersoft  
