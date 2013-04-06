# AUTOVALA

Autovala is a program and a library designed to help in the creation of projects with Vala and CMake.

The idea is quite simple: CMake is very powerful, but writting the CMakeLists files is boring and repetitive. Why not let the computer create them, by guessing what to do with each file? And if, at the end, there are mistakes, let the user fix them in an easy way, and generate the final CMakeLists files.

This is what Autovala does. This process is done in three steps:

* First, Autovala checks all the folders and files, and creates a project with the type of each file
* It also peeks the source files to determine which Vala packages they need, and generate automagically that list
* After that (and after allowing the user to check, if (s)he wishes, the project file), it uses that project file to generate the needed CMakeLists files

Autovala uses simple rules, like: "png files go to usr/share/pixmaps", and so on. It even takes into account things like the size and type of picture. For a detailed (and, maybe, boring) explanation of the rules followed by Autovala, check [rules page](Rules).

[Using autovala](Using-Autovala)  
[Project file format (needed for manual editing)](Project-File-Format)  
[Keeping your changes](Keeping-your-changes): needed when you manually edit the .avprj file  
[Autovala tricks](tricks)  
[Things TO DO](To-Do)  
[History of versions](versions)  
