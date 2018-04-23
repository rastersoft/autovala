pkgname=autovala
pkgver=1.7.0
pkgrel=1
pkgdesc="Autovala is a program and a library designed to help in the creation
of projects with Vala and CMake.

The idea is quite simple: CMake is very powerful, but writting the
CMakeLists files is boring and repetitive. Why not let the computer
create them, by guessing what to do with each file? And if, at the
end, there are mistakes, let the user fix them in an easy way, and
generate the final CMakeLists files.

This is what Autovala does. This process is done in three steps:

* First, Autovala checks all the folders and files, and writes a
project file with the type of each file
* It also peeks the source files to determine which Vala packages
they need, and generate automagically that list
* After that (and after allowing the user to check, if (s)he wishes,
the project file), it uses that project file to generate the needed
CMakeLists files

Autovala greatly simplifies the process of working with Vala because:

* Automatically determines the vala packages and libraries needed to
compile and run the project, by inspecting the source code
* Automatically generates the .vapi and pkg-config files for libraries
* Automatically determinates the final destination for an icon, by
checking its type (svg or png) and, in the later case, its size
* Automatically generates manpages from text files in several
possible input format (markdown, html, latex...)
* Greatly simplifies creating libraries in Vala, or a project with a
binary that uses a library defined in the same project
* Automatically generates the metadata files to create .DEB and .RPM packages.
* Easily integrates unitary tests for each binary in the project
* Can generate automatically DBUS bindings by using the DBUS
introspection capabilities
* Automatically generates the list of source files for GETTEXT
* Simplifies mixing C and Vala source files

"
arch=('i686' 'x86_64')
depends=( 'glib2' 'libgee' 'cairo' 'gtk3' 'pango' 'gdk-pixbuf2' 'libxml2' 'readline' 'atk' 'libx11' 'vte3' 'zlib' 'pcre2' 'gnutls' 'pandoc' 'curl' )
makedepends=( 'vala' 'glibc' 'glib2' 'libgee' 'readline' 'cairo' 'gtk3' 'gdk-pixbuf2' 'libxml2' 'pango' 'atk' 'libx11' 'vte3' 'cmake' 'gettext' 'pkg-config' 'gcc' 'make' 'intltool' 'pandoc' 'bash-completion' )
build() {
	rm -rf ${startdir}/install
	mkdir ${startdir}/install
	cd ${startdir}/install
	cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=/usr/lib
	make -j1
}

package() {
	cd ${startdir}/install
	make DESTDIR="$pkgdir/" install
}
