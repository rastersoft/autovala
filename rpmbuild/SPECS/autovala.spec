Name: autovala
Version: 1.6.0
Release: 1
License: Unknown/not set
Summary: Simplify the creation of Vala projects

BuildRequires: gcc
BuildRequires: gcc-c++
BuildRequires: vala
BuildRequires: glibc-headers
BuildRequires: glib2-devel
BuildRequires: libgee-devel
BuildRequires: readline-devel
BuildRequires: cairo-devel
BuildRequires: gtk3-devel
BuildRequires: gdk-pixbuf2-devel
BuildRequires: libxml2-devel
BuildRequires: pango-devel
BuildRequires: atk-devel
BuildRequires: libX11-devel
BuildRequires: vte291-devel
BuildRequires: cmake
BuildRequires: gettext
BuildRequires: pkgconf-pkg-config
BuildRequires: make
BuildRequires: intltool
BuildRequires: pandoc
BuildRequires: bash-completion

Requires: glib2
Requires: libgee
Requires: cairo
Requires: gtk3
Requires: pango
Requires: gdk-pixbuf2
Requires: cairo-gobject
Requires: libxml2
Requires: readline
Requires: atk
Requires: libX11
Requires: vte291
Requires: zlib
Requires: pcre2
Requires: gnutls
Requires: pandoc
Requires: curl

%description
Autovala is a program and a library designed to help in the creation
of projects with Vala and CMake.
.
The idea is quite simple: CMake is very powerful, but writting the
CMakeLists files is boring and repetitive. Why not let the computer
create them, by guessing what to do with each file? And if, at the
end, there are mistakes, let the user fix them in an easy way, and
generate the final CMakeLists files.
.
This is what Autovala does. This process is done in three steps:
.
* First, Autovala checks all the folders and files, and writes a
project file with the type of each file
* It also peeks the source files to determine which Vala packages
they need, and generate automagically that list
* After that (and after allowing the user to check, if (s)he wishes,
the project file), it uses that project file to generate the needed
CMakeLists files
.
Autovala greatly simplifies the process of working with Vala because:
.
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
.
.

%files
*

%build
mkdir -p ${RPM_BUILD_DIR}
cd ${RPM_BUILD_DIR}; cmake -DCMAKE_INSTALL_PREFIX=/usr -DGSETTINGS_COMPILE=OFF -DICON_UPDATE=OFF ../..
make -C ${RPM_BUILD_DIR}

%install
make install -C ${RPM_BUILD_DIR} DESTDIR=%{buildroot}

%post
ldconfig

%postun
ldconfig

%clean
rm -rf %{buildroot}

