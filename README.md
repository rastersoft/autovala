# AUTOVALA 0.5.0 #

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


The DOC folder contains the Wiki dumped in HTML format. Just open the **index.html** file
with your browser, and enjoy.


## TO DO ##

This is still version 0.5.0. It is fully usable, but there are still a lot of
things that I want to add to it, and I will need help.

 * Allow that a binary being compiled be able to use a library compiled in the
   same project. This is a must if I want to distribute Autovala both as a library, and as
   a command line program that uses that library.
   
 * Generate automatically the .pc file for a library (for pkg-config). I need help with the format of the .pc files

 * Integrate it as a plugin for Gedit


## CONTACTING THE AUTHOR ##

Sergio Costas Rodriguez
(Raster Software Vigo)

raster@rastersoft.com

http://www.rastersoft.com

GIT: git://github.com/rastersoft/autovala.git
