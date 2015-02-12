Autovala-rules(7)

# NAME

Autovala rules - Rules followed by autovala to guess what kind of file is each one in the folder tree.

# DESCRIPTION

The rules followed by Autovala are the following:

* All **.vala** and **.c** files in the **src/** folder belong to a binary called like the project name. Vala files will be scanned to determine the packages needed to compile them. The **.vala** and **.c** files in the subfolders are also added, unless there is another binary or library that already posesses that folder

* All folders that contains a **.h** file inside the **src/** folder will be added to the list of folders where to search for include files in that project.

* All **.vala** and **.c** files in a folder posessed by a binary or library belong to it. Vala files will be scanned to determine the packages needed to compile them. The **.vala** and **.c** files in the subfolders are also added, unless there is another binary or library that already posesses that folder

* All folders that contains a **.h** file inside a folder posessed by a binary or library will be added to the list of folders where to search for include files in that project.

* All **.vala** files in a folder called **unitests**, in the root of each binary or library path, will be considered unitary tests for that binary or library.

* The VALA sources will be scanned to find the version number in a specific format, allowing to keep it inside the sources and avoiding the need of editing the project file manually

* All **.vapi** files inside a **vapis** folder, located in a binary/library top folder will be added to that binary/library

* All **.png** or **.svg** files in the folder **data/icons/** (and subfolders) are considered icons, so Autovala will determine automatically the best-fitting standard icon size (in the case of **.png**; for **.svg** it will try to put them in an scalable group with **scalable** in the name; if it doesn't exists, it will try to put them in an scalable group; if neither exist, it will be installed in the biggest size group available in de desired cathegory) and install them in the corresponding cathegory: **Applications** by default, unless it is a **.svg** file with a filename ended in **-symbolic.svg**; in that case it will go to **Status**. The user can modify the final cathegory and icon theme manually for the icons (s)he wishes.

* All **.png**, **.jpg** or **.svg** files in the folder **data/pixmaps/** (and subfolders) are considered pixmaps, and will be installed in **share/pixmaps/**.

* All **.po** files in **po/** folder will be considered as po files, and will be installed in the right locale. Also, will find the **.vala** and **.ui** files and add them as sources for internationalization process.

* Each **.desktop** file in **data/** will be copied to **share/desktop/**, unless it contains the line **X-GNOME-Autostart-enabled=**, in which case it will be copied to **/etc/xdg/autostart**.

* Each **.service** and **.service.base** files in **data/** will be presumed to be a D-Bus service, and will be preprocessed to put the right binary folder ( **bin/** or **local/bin/** )

* Each **.plug** file in **data/** will be presumed to be an ElementaryOS PLUG file

* Each **.gschema.xml** file in **data/** will be presumed to be a GTK schema, so will be copied in the right place and force a recompile of the schemas (if needed)

* Each **.ui** file in **data/interface/** will be presumed to be a Glade file, so will be copied to **share/project_name/** and taken into account when generating the **.po** and **.mo** files for internationalization

* Each **.sh** file in **data/** will be presumed to be a binary script, so will be copied to **bin/**

* All files and folders in **data/local/** will be copied to **share/project_name/**. This is useful for application-specific data

* All files and folders in **doc/** will be copied to **share/doc/project_name/**. This is useful for documentation

* All files ended in **.X** (being X a number between 1 and 9) in the folder **data/man** will be considered man pages in groff format, and will be compressed with gzip and installed in **share/man/manX** (being X the same number).

* All files ended in **.X.md** (being X a number between 1 and 9) in the folder **data/man** will be considered man pages in **markdown_github** format, and will be converted to groff using pandoc, compressed with gzip and installed in **share/man/manX** (being X the same number).

* All files ended in **.X.rst** (being X a number between 1 and 9) in the folder **data/man** will be considered man pages in **reStructuredText** format, and will be converted to groff using pandoc, compressed with gzip and installed in **share/man/manX** (being X the same number).

* All files ended in **.X.htm** or **.X.html** (being X a number between 1 and 9) in the folder **data/man** will be considered man pages in **html** format, and will be converted to groff using pandoc, compressed with gzip and installed in **share/man/manX** (being X the same number).

* All files ended in **.X.tex** (being X a number between 1 and 9) in the folder **data/man** will be considered man pages in **LaTeX** format, and will be converted to groff using pandoc, compressed with gzip and installed in **share/man/manX** (being X the same number).

* All files ended in **.X.json** (being X a number between 1 and 9) in the folder **data/man** will be considered man pages in **JSon version of native AST** format, and will be converted to groff using pandoc, compressed with gzip and installed in **share/man/manX** (being X the same number).

* All files ended in **.X.rdoc** (being X a number between 1 and 9) in the folder **data/man** will be considered man pages in **Textile/RedCloth** format, and will be converted to groff using pandoc, compressed with gzip and installed in **share/man/manX** (being X the same number).

* All files ended in **.X.xml** (being X a number between 1 and 9) in the folder **data/man** will be considered man pages in **DocBook** format, and will be converted to groff using pandoc, compressed with gzip and installed in **share/man/manX** (being X the same number).

* All files ended in **.X.txt** (being X a number between 1 and 9) in the folder **data/man** will be considered man pages in **MediaWiki** format, and will be converted to groff using pandoc, compressed with gzip and installed in **share/man/manX** (being X the same number).

* All files ended in **.X**, **.X.md**, **.X.rst**, **.X.htm**, **.X.html**, **.X.tex**, **.X.json**, **.X.rdoc**, **.X.xml** or **.X.txt** (being X a number between 1 and 9) in the folder **data/man/YYYY** will be considered man pages in groff or markdown format respectively, and will be converted to groff using pandoc, compressed with gzip and installed in **share/man/YYYY/manX** (being X the same number). This means that **YYYY** will be considered a language (examples for YYYY: **es**, **en_US**, **es_AR.UTF-8**).

* All files in **data/bash_completion/** will be copied to where the command *pkg-config --variable=completionsdir bash-completion* specifies (usually **/usr/share/bash-completion/completions**), except when *CMAKE_INSTALL_PREFIX* starts with */home* (this allows to do installations in the HOME directory).

When Autovala searchs the packages, it uses only the versions available for the currently active version. Also, by default, it uses the most recent version. But if another version is selected manually, it will use that one instead.

**Example:** if you put "using Gtk;" in your code, by default Autovala will use the package gtk+-3.0 to compile it; but if you manually add the package gtk+-2.0 to that binary, Autovala will use Gtk2 instead of Gtk3.

# SEE ALSO

[autovala(1)](autovala.1) [autovala-fileformat(5)](autovala-fileformat.5) [autovala-keep-changes(7)](autovala-keep-changes.7) [autovala-tricks(7)](autovala-tricks.7)

# AUTHOR

Sergio Costas Rodriguez  
raster@rastersoft.com  
http://www.rastersoft.com  
http://github.com/rastersoft  
