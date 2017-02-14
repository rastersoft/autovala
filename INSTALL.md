# HOW TO INSTALL

To compile and install it, just open a terminal, go
to the directory where you downloaded the git repository
and type:

    mkdir install
    cd install
    cmake ..
    make
    sudo make install
    sudo ldconfig

If you are using GTK 3.4 or previous, you must specify it
to avoid the plugins to use newer widgets, not supported
in old GTK versions:

    mkdir install
    cd install
    cmake .. -DGTK_OLD=on
    make
    sudo make install
    sudo ldconfig

Also, if you are using ElementaryOS Luna, the pandoc version
available is also too old, so you must install the one from
ubuntu 14.04 at least. The packages needed are pandoc,
pandoc-data and libicu52, which can be downloaded from

    http://packages.ubuntu.com

The Gedit and Scratch plugins are compiled and installed
separately. Just follow the instructions available in each
folder.

The main dependencies list is:

    * atk
    * glib-2.0
    * gee
    * gtk-3
    * libxml2
    * vte-2.91
    * readline
    * pandoc
    * curl

Remember that you need CMake, Vala 0.20 or later, libgee
and gtk+. The repository includes a version of CMake for
Vala that includes some changes (not mine) to support
Valadoc. These changes still aren't available at the
oficial repository. If you want, you can get the oficial
files with:

    bzr checkout lp:~elementary-apps/+junk/cmake-modules

This will create a folder called *cmake-modules*. Inside
it will be a folder called *cmake*. Copy the later to the
Autovala project folder, overwriting the files inside.

Don't forget to keep the files FindValadoc.cmake and
Valadoc.cmake, needed to work with Valadoc.

If you want to try the Meson builder, just do this:

    mkdir meson
    cd meson
    meson ..
    ninja
    sudo ninja install
    sudo ldconfig

And, of course, report all the bugs you find and sugestions
to make the Meson scripts better.
