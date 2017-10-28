Autovala-keep-changes(7)

# NAME

autovala keeping your changes - How to manually modify the configuration file without loosing your changes

# DESCRIPTION

By default, nearly all the lines in the project file start with an asterisk. Those lines contain automatically created commands, and every time the user launches the command **autovala refresh** or **autovala update**, they are deleted and recreated using the current files in the disk and the [rules](autovala-rules.7).

Lines without the asterisk contain commands specified manually by the user, and they are not deleted before recreating the project file.

Also, when an automatically created **vala_library** or **vala_binary** command (this is, prefixed with the asterisk) contains at least one subcommand added manually, that command will be considered manually added too, so it will be preserved even if you delete its folder. This is made this way to ensure that the manual data is preserved in all cases.

Example: let's suppose we have this project file:

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

We can see that all the commands have been added automatically, because they are prepended by an asterisk.

Let's say that the version number is incorrect; we want the version number 0.1.0. So we edit the file and modify it (incorrectly) to look like this:

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

This change is **INCORRECT**, because it keeps the asterisk in the changed line. That means that the next time that **autovala refresh** or **autovala update** is run, that change will disappear and will be replaced by the old guess.

To ensure that the change remains, it must be put in a line **without** the asterisk. This is:

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

Now the change will remain, no matter how many times **autovala refresh** or **autovala update** are run.

# SEE ALSO

[autovala(1)](autovala.1) [autovala-rules(7)](autovala-rules.7) [autovala-fileformat(5)](autovala-fileformat.5) [autovala-tricks(7)](autovala-tricks.7)

# AUTHOR

Sergio Costas Rodriguez  
raster@rastersoft.com  
http://www.rastersoft.com  
http://github.com/rastersoft  
