Name: autovala_gedit
Version: 1.0.0
Release: 1
License: GPLv3
Summary: This is a plugin for GEdit 3 that integrates the project manager AutoVala, allowing to use GEdit as a fully-fledged IDE for creating projects in VALA language.

BuildRequires: gcc
BuildRequires: gcc-c++
BuildRequires: vala
BuildRequires: gedit-devel
BuildRequires: atk-devel
BuildRequires: cairo-devel
BuildRequires: gtk3-devel
BuildRequires: gdk-pixbuf2-devel
BuildRequires: libgee-devel
BuildRequires: glib2-devel
BuildRequires: gobject-introspection-devel
BuildRequires: gtksourceview3-devel
BuildRequires: libpeas-devel
BuildRequires: pango-devel
BuildRequires: libX11-devel
BuildRequires: cmake
BuildRequires: gettext
BuildRequires: pkgconfig
BuildRequires: make
BuildRequires: intltool
BuildRequires: autovala

Requires: gtksourceview3
Requires: libpeas
Requires: gtk3
Requires: pango
Requires: atk
Requires: cairo-gobject
Requires: cairo
Requires: gdk-pixbuf2
Requires: glib2
Requires: gobject-introspection
Requires: libgee
Requires: libX11
Requires: autovala

%description
This is a plugin for GEdit 3 that integrates the project manager
AutoVala, allowing to use GEdit as a fully-fledged IDE for creating
projects in VALA language.
.
The plugin adds a left panel which shows the binaries and libraries
being created by an AutoVala project and its source files, allowing
to choose them just by clicking on each. It also shows all the other
files in the project (doc, po, data...) and the AVPRJ file.
.
To open an AutoVala project, just open any of the files belonging to
it, and the plugin will autodetect the project and show all the data.
.
Remember that you need Autovala installed in your system.
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

