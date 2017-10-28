/*
 Copyright 2013-2016 (C) Raster Software Vigo (Sergio Costas)

 This file is part of AutoVala

 AutoVala is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 3 of the License, or
 (at your option) any later version.

 AutoVala is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>. */

using GLib;
using Posix;

namespace AutoVala {

	class MesonCommon : GLib.Object {

		private bool install_script_created;
		private bool install_schemas_created;
		private bool manpage_script_created;
		private bool install_library_script_created;
		private bool check_path_script_created;
		private bool added_dbus_prefix;

		private string scriptPathS;

		public void init() {
			this.install_script_created = false;
			this.install_library_script_created = false;
			this.added_dbus_prefix = false;
			this.check_path_script_created = false;
			this.manpage_script_created = false;
			this.install_schemas_created = false;
			this.scriptPathS = Path.build_filename(ElementBase.globalData.projectFolder,"meson_scripts");
			var tmpPath = File.new_for_path(this.scriptPathS);
			if (tmpPath.query_exists()) {
				ManageProject.delete_recursive(this.scriptPathS);
			}
		}

		private void create_folder() {

			var scriptPath = File.new_for_path(this.scriptPathS);
			try {
				scriptPath.make_directory_with_parents();
			} catch(GLib.Error e) {
			}
		}

		private void set_permissions(string script) {
			Posix.chmod(Path.build_filename(this.scriptPathS,script),0x1ED);
		}

		/**
		 * Creates the install_data.sh script, that allows to install data files in specific folders, with wildcards
		 * The first argument is the destination folder
		 * The second argument is the source file expresion (can have wildcards)
		 */
		public void create_install_script() throws GLib.Error {

			if (this.install_script_created) {
				return;
			}

			this.create_folder();
			var scriptPath = File.new_for_path(Path.build_filename(this.scriptPathS,"install_data.sh"));
			if (scriptPath.query_exists()) {
				scriptPath.delete();
			}

			var dataStream2 = new DataOutputStream(scriptPath.create(FileCreateFlags.NONE));
			dataStream2.put_string("""#!/bin/sh
mkdir -p $DESTDIR/$1
if [[ -d $2 ]]; then
	cp -a $2/* $DESTDIR/$1
else
	cp -a $2 $DESTDIR/$1
fi
""");
			dataStream2.close();
			this.set_permissions("install_data.sh");
			this.install_script_created = true;
		}

		/**
		 * Creates the install_data.sh script, that allows to install data files in specific folders, with wildcards
		 * The first argument is the destination folder
		 * The second argument is the source file expresion (can have wildcards)
		 */
		public void create_schemas_script() throws GLib.Error {

			if (this.install_schemas_created) {
				return;
			}
			this.create_folder();
			var scriptPath = File.new_for_path(Path.build_filename(this.scriptPathS,"install_schemas.py"));
			if (scriptPath.query_exists()) {
				scriptPath.delete();
			}

			var dataStream2 = new DataOutputStream(scriptPath.create(FileCreateFlags.NONE));
			dataStream2.put_string("""#!/usr/bin/env python3

import os
import subprocess

schemadir = os.path.join(os.environ['MESON_INSTALL_PREFIX'], 'share', 'glib-2.0', 'schemas')

if not os.environ.get('DESTDIR'):
    print('Compiling gsettings schemas...')
    subprocess.call(['glib-compile-schemas', schemadir])""");
			dataStream2.close();
			this.set_permissions("install_schemas.py");
			this.install_schemas_created = true;
		}

		/**
		 * Creates the install_manpage_data.sh script, that allows to convert, compress and install manpage files
		 * The first argument is the destination folder
		 * The second argument is the source file expresion (can have wildcards)
		 */
		public void create_manpages_script() throws GLib.Error {

			if (this.manpage_script_created) {
				return;
			}

			this.create_folder();
			var scriptPath = File.new_for_path(Path.build_filename(this.scriptPathS,"install_manpage.sh"));
			if (scriptPath.query_exists()) {
				scriptPath.delete();
			}

			var dataStream2 = new DataOutputStream(scriptPath.create(FileCreateFlags.NONE));
			dataStream2.put_string("""#!/bin/sh

mkdir -p $DESTDIR/$MESON_INSTALL_PREFIX/$2
if [ $1 -eq '2' ]; then
pandoc ${MESON_SOURCE_ROOT}/$3 -o - -f $4 -t man -s | gzip - > $MESON_INSTALL_DESTDIR_PREFIX/$2/$5.gz
else
cat ${MESON_SOURCE_ROOT}/$3 | gzip - > $MESON_INSTALL_DESTDIR_PREFIX/$2/$5.gz
fi
""");

			dataStream2.close();
			this.set_permissions("install_data.sh");
			this.manpage_script_created = true;
		}

		/**
		 * Creates the install_library.sh script, that allows to install a library with all their files (VAPI, GIR and headers)
		 * The first argument is the library filename (libFilename)
		 * The second argument is the .gir name (girFilename)
		 */
		public void create_install_library_script() throws GLib.Error {
			if (this.install_library_script_created) {
				return;
			}

			this.create_folder();
			var scriptPath = File.new_for_path(Path.build_filename(this.scriptPathS,"install_library.sh"));
			if (scriptPath.query_exists()) {
				scriptPath.delete();
			}
			var dis = scriptPath.create(FileCreateFlags.NONE);
			var dataStream2 = new DataOutputStream(dis);
			dataStream2.put_string("""#!/bin/sh

mkdir -p "${DESTDIR}${MESON_INSTALL_PREFIX}/share/vala/vapi"
mkdir -p "${DESTDIR}${MESON_INSTALL_PREFIX}/share/gir-1.0"
mkdir -p "${DESTDIR}${MESON_INSTALL_PREFIX}/include"

install -m 644 "${MESON_BUILD_ROOT}/$1/$2.vapi" "${DESTDIR}${MESON_INSTALL_PREFIX}/share/vala/vapi"
install -m 644 "${MESON_BUILD_ROOT}/$1/$2.h" "${DESTDIR}${MESON_INSTALL_PREFIX}/include"
install -m 644 "${MESON_BUILD_ROOT}/$1/$2@sha/$3" "${DESTDIR}${MESON_INSTALL_PREFIX}/share/gir-1.0"
""");
			dataStream2.close();
			this.set_permissions("install_library.sh");
			this.install_library_script_created = true;
		}

		public void create_check_paths_script() throws GLib.Error {

			if (this.check_path_script_created) {
				return;
			}

			this.create_folder();
			var scriptPath = File.new_for_path(Path.build_filename(this.scriptPathS,"check_path.sh"));
			if (scriptPath.query_exists()) {
				scriptPath.delete();
			}
			var dis = scriptPath.create(FileCreateFlags.NONE);
			var dataStream2 = new DataOutputStream(dis);
			dataStream2.put_string("""#!/bin/sh

if [ -e $1 ]
then
	exit 0
else
	exit 1
fi
""");
			dataStream2.close();
			this.set_permissions("check_path.sh");
			this.check_path_script_created = true;
		}

		public void add_dbus_config(ConditionalText dataStream) throws Error {

			if (this.added_dbus_prefix) {
				return;
			}

			dataStream.put_string("cfg_dbus_data = configuration_data()\ncfg_dbus_data.set ('DBUS_PREFIX',get_option('prefix'))\n");
			this.added_dbus_prefix = true;
		}
	}

}
