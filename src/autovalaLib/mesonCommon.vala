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


namespace AutoVala {

	class MesonCommon : GLib.Object {

		private bool install_script_created;
		private bool install_library_script_created;
		private string scriptPathS;
		private bool added_dbus_prefix;

		public void init() {
			this.install_script_created = false;
			this.install_library_script_created = false;
			this.added_dbus_prefix = false;
			this.scriptPathS = Path.build_filename(ElementBase.globalData.projectFolder,"meson_scripts");
			ManageProject.delete_recursive(this.scriptPathS);
		}

		private void create_folder() {

			var scriptPath = File.new_for_path(this.scriptPathS);
			try {
				scriptPath.make_directory_with_parents();
			} catch(GLib.Error e) {
			}
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
			dataStream2.put_string("#!/bin/sh\n\nmkdir -p $DESTDIR/$1\n\ncp -a $2 $DESTDIR/$1\n");
			dataStream2.close();
			this.install_script_created = true;
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

install -m 644 "${MESON_BUILD_ROOT}/$1.vapi" "${DESTDIR}${MESON_INSTALL_PREFIX}/share/vala/vapi"
install -m 644 "${MESON_BUILD_ROOT}/$1.h" "${DESTDIR}${MESON_INSTALL_PREFIX}/include"
install -m 644 "${MESON_BUILD_ROOT}/$1@sha/$2" "${DESTDIR}${MESON_INSTALL_PREFIX}/share/gir-1.0"
""");
			dataStream2.close();
			this.install_library_script_created = true;
		}

		public void add_dbus_config(DataOutputStream dataStream) throws Error {

			if (this.added_dbus_prefix) {
				return;
			}

			dataStream.put_string("cfg_dbus_data = configuration_data()\ncfg_dbus_data.set ('DBUS_PREFIX',get_option('prefix'))\n");
			this.added_dbus_prefix = true;
		}
	}

}
