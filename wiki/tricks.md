# Tricks for Autovala

## Creating several binaries

By default, Autovala presumes that every source file inside SRC or its subdirectories belongs to a single binary. But maybe you want to generate several binaries because your program needs several executables.

Let's suppose that you have a project called *myproject*, with a folder hierarchy like this:

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


And let's suppose that you want to compile *file5.vala* and *file6.vala* as a different executable called *otherprogram*. By default, after running 'autovala refresh', it will create a single executable called *myproject*, using all the source files (*file1.vala* to *file6.vala*), and the *.avprj* file will look like this:

    ### AutoVala Project ###
    autovala_version: 2
    project_name: myproject
    vala_version: 0.16

    *vala_binary: src/myproject
    [several commands specific of this binary]
    
What we have to do is add a new *vala_binary* command to the file, specifying the path and the executable name we want (and WITHOUT an asterisk before; read [Keeping your changes](wiki/Keeping-Your-Changes) to understand why). So edit it and add this:

    ### AutoVala Project ###
    autovala_version: 2
    project_name: myproject
    vala_version: 0.16

    vala_binary: src/another_folder/otherprogram
    *vala_binary: src/myproject
    [several commands specific of this binary]

Save it and run 'autovala update'. If you edit again the project file, you will see that Autovala automatically added all the packages and other data to the new executable, and will keep doing every time you run it.


## Creating libraries

Creating a library is as easy as editing the project file and replacing the command *vala_binary* with *vala_library* and running again 'autovala update'.