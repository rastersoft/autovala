pkgname=autovala
pkgver=0.99.23
pkgrel=1
arch=('i686' 'x86_64')
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
CMakeLists files"
depends=( 'glib2' 'libgee' 'cairo' 'gtk3' 'pango' 'gdk-pixbuf2' 'readline' 'atk' 'libx11' 'pandoc-bin' )
makedepends=( 'vala' 'glibc' 'glib2' 'libgee' 'readline' 'cairo' 'gtk3' 'gdk-pixbuf2' 'pango' 'atk' 'libx11' 'cmake' 'gettext' 'pkg-config' 'gcc' 'make' 'intltool' 'pandoc-bin' 'bash-completion' )
source=()
noextract=()
md5sums=()
validpgpkeys=()

build() {
	rm -rf ${startdir}/install
	mkdir ${startdir}/install
	cd ${startdir}/install
	cmake .. -DCMAKE_INSTALL_PREFIX=/usr
	make
}

package() {
	cd ${startdir}/install
	make DESTDIR="$pkgdir/" install
}
