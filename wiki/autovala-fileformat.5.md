Autovala-fileformat(5)

# NAME

autovala fileformat - The syntax for autovala configuration file

# DESCRIPTION

The project file has a very simple format. Usually you don't need to manually edit it, but when the guesses of autovala are incorrect, you can do it, and your changes will be remembered each time you refresh the file.

The current version for the project file format is **10**.

The file is based on commands in the format:

        command: data

one in each line. Every line that starts with # is ignored (is a comment), but also will be removed when the file is recreated.

Except where otherwise is specified, the paths must be relative to the project path.

The first line in a project file is, always, ### AutoVala Project ###. This string identifies it as an Autovala project file.

The next line has the command **autovala_version**. This command specifies which version of the syntax uses this file, to avoid an old version of Autovala to open a newer, with commands that it wouldn't understand.

The next line has the command **project_name**. This command sets the name assigned to this project.

Then, the next line contains **vala_version**, which specifies the minimum Vala version needed to compile this project. By default, it is filled with the version number of the vala version installed when the project was created.

After that, it comes several commands, some of them repeated several times, to specify what to do with each file in your project. These commands are:

 * **po**: specifies the folder where to store the translations. By default it is **po**. The program identifier for Gettext is the project name.

 * **define**: specifies a condition parameter set in a **#define** statement in the source code, for conditional compilation. These parameters can be set during Makefile creatin with **-Dparameter=ON**, and will be passed to **valac** during compilation.

 * **data**: specifies a folder with local data that must be installed in **share/project_name**. By default it is **data/local**.

 * **doc**: specifies a folder with the documentation that must be installed in **share/doc/project_name**. By default it is **doc**.

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

   * **compile_c_options**: contains the options to pass to the C compiler and linker. Example:

                compile_c_options: -O2

   * **vala_package**: specify a package that must be added with **--pkg=...** to the vala compiler. These are automatically found by Autovala by reading the sources and processing the **Using** directives

   * **vala_check_package**: is like **vala_package**, but these packages must, also, be checked during cmake to ensure that they are installed in the system. Autovala finds these automatically by reading the sources, as with vala_package, and checking if the corresponding **.pc** file exists

   * **c_check_package**: is like **vala_check_package**, but will be added only when compiling and linking the C code, not to the Vala compiler. It is useful when mixing Vala and C sources and the C code needs a library that the Vala source doesn't need.

   * **vala_local_package**: is like **vala_package**, but these packages aren't installed in the system. Instead, they belong to this project, and will be compiled automatically before this binary/library.

   * **vala_source**: this command specifies one VALA source file that belongs to this binary. The path must be relative to the binary/library path.

   * **c_source**: this command specifies one C source file that belongs to this binary. The path must be relative to the binary/library path.

   * **vala_vapi**: this command specifies one custom **.vapi** file, needed to compile your project. Each file must be prepended by the relative path from the project folder. The path must be relative to the binary/library path.

   * **dbus_interface**: this command specifies a DBus interface to be automatically extracted using introspection, and to generate a source file with it. It must be followed by the connection name (e.g. org.freedesktop.ConsoleKit), the object path (e.g. /org/freedesktop/ConsoleKit/Manager), and whether it must connect to the **system** or **session** bus. Finally, it can have an extra parameter specifying if the generated interface must be for **gdbus** (the default option) or for the obsolete **dbus-glib** library.  

    The last ten subcommands (compile_options, compile_c_options, vala_package, vala_check_package, c_check_package, vala_local_package, vala_source, c_source, vala_vapi and dbus_interface) can be repeated as many times as needed to specify all the sources and packages needed.

 * **vala_library**: the same than vala_binary, but creates a dynamic linking library. It uses the same subcommands.

 * **binary**: specifies that the file is a precompiled binary (or a shell script) that must be copied as-is to vbin/**

 * **icon**: followed by the category and the icon path/name. Autovala will determine the icon size and use it to copy it to the right place (only if it is a **.png** file; it it is a **.svg** will copy to "scalable"). Also, by default, the cathegory will be **apps**, unless it is a **.svg** with **-symbolic**; in that case will be put in the **status** category. Example:

            icon: apps finger.svg

 * **pixmap**: followed by a picture filename. Will be copied to **share/pixmaps**

 * **glade**: the file specified is a glade UI file, that will be installed in **share/project_name/** These files, and the **.vala** source files, will be used with gettext to get the translatable strings.

 * **dbus_service**: the file specified is a D-Bus service. The file must be written as a classic D-Bus service file, but prefixing the binary filename with **@DBUS_PREFIX@**. Example from Cronopete:

            [D-BUS Service]
            Name=com.rastersoft.cronopete
            Exec=@DBUS_PREFIX@/bin/cronopete

   This allows to use cmake to install everything in a temporary folder, and ensure that the **Exec** entry points to the right place. This is paramount when using these CMakeLists files for creating a **.deb** or **.rpm** package.

 * **desktop**: the file specified is a **.desktop** file that must be copied to **share/applications** to ensure that it is shown in the applications menu.

 * **eos_plug**: the file is an ElementaryOS plug for the configuration system

 * **scheme**: the file is a **GSettings** file that contains configuration settings. It is automagically compiled if needed.

 * **autostart**: the file is a **.desktop** one, but must be installed in **/etc/xdg/autostart** because the program specified there must be launched automatically when starting the desktop session. Don't forget to add **X-GNOME-Autostart-enabled=true** inside.

 * **include**: allows to include the specified file in the CMakeLists of its path. This allows to manually add CMake statements. Example:

            include: src/mycmake.txt

   will append the contents of the file **mycmake.txt**, located in the **src/** folder, to the end of the **CMakeLists.txt** file also located in the **src/** folder

 * **ignore**: the path that follows will be ignored when Autovala guesses each file. Examples:

            ignore: src/PROG/test.vala will ignore the file test.vala when automatically creating the PROG binary

            ignore: src/OTHER will ignore the folder OTHER when creating binaries

 * **custom**: followed by a path/filename and another path. Installs the specified file in the path. If the path is given in relative format (this is, if it doesn't start with an slash) the file will be installed relative to the PREFIX (**/usr** or **/usr/local**); but if it is given in absolute format (this is, the path starts with a slash) the file will be installed in that precise folder. Examples:
 
            custom: data/config_system.txt share/ will install the file **config_system.txt** in **/usr/share** or **/usr/local/share**

            custom: data/config_system.txt /etc/myfolder will install the file **config_system.txt** in **/etc/myfolder**

 * **manpage**: followed by a path/filename, and optionally a language and a page section. Specifies that the file is a man page in the specified language (**default** to install it in the default folder), and for the specified section. If the section is not specified, it will be assumed to be section 1. If the language is not specified, it will be assumed **default**. If the file ends in **.md**, Autovala will presume that it is a **markdown** file, and will convert it to groff before. Other supported formats and its extensions are HTML (**.html**), ReStructured Text (**.rst**), LaTeX (**.tex**), JSON version of native AST format (**.json**), TexTile/RedCloth (**.rdoc**), DocBook format (**.xml**) and MediaWiki (**.txt**). Examples:
 
            manpage: data/man/autovala.1   will install the file **data/man/autovala** in **/usr/local/share/man/man1**
            manpage: data/man/autovala-rules.7.md es 7   will install the file **data/man/autovala-rules** in **/usr/local/share/man/es/man7**
            manpage: data/man/autovala-modifying.5.md default 5   will install the file **data/man/autovala-modifying** in **/usr/local/share/man/man5**

It is also possible to add conditions to nearly all of these commands (more specifically, all can be conditional with the exception of **vala_version**, **vala_binary**, **vala_library**, **version**, **namespace**, **include**, **project_name**, **vala_destination**, **define** and **autovala_version**). To do so, you can use the commands **if CONDITION**, **else** and **end**. The format for the **CONDITION** string is the CMake format (statements that can be true or false, parenteses, and AND, OR and NOT operators).

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

# SEE ALSO

[autovala(1)](autovala.1) [autovala-rules(7)](autovala-rules.7) [autovala-keep-changes(7)](autovala-keep-changes.7) [autovala-tricks(7)](autovala-tricks.7)

# AUTHOR

Sergio Costas Rodriguez  
raster@rastersoft.com  
http://www.rastersoft.com  
http://github.com/rastersoft  
