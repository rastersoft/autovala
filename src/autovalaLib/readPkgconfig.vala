/*
 Copyright 2013 (C) Raster Software Vigo (Sergio Costas)

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
using Gee;
using Posix;

namespace AutoVala {

	private class ReadPkgConfig {
		private Gee.Set<string> ?pkgconfigs;

		public ReadPkgConfig() {
			this.pkgconfigs=new Gee.HashSet<string>();

			this.fill_pkgconfig_files("/usr/lib");
			this.fill_pkgconfig_files("/usr/share");
			this.fill_pkgconfig_files("/usr/lib/i386-linux-gnu");
			this.fill_pkgconfig_files("/usr/lib/x86_64-linux-gnu");
			this.fill_pkgconfig_files("/usr/local/lib");
			this.fill_pkgconfig_files("/usr/local/share");
			this.fill_pkgconfig_files("/usr/local/lib/i386-linux-gnu");
			this.fill_pkgconfig_files("/usr/local/lib/x86_64-linux-gnu");
			var other_pkgconfig=GLib.Environment.get_variable("PKG_CONFIG_PATH");
			if (other_pkgconfig!=null) {
				foreach(var element in other_pkgconfig.split(":")) {
					this.fill_pkgconfig_files(element);
				}
			}
		}

		private void fill_pkgconfig_files(string basepath) {

			/**
			 * Reads all the pkgconfig files in basepath and creates a list with the libraries managed by them
			 */

			var newpath=File.new_for_path(Path.build_filename(basepath,"pkgconfig"));
			if (newpath.query_exists()==false) {
				return;
			}
			FileInfo file_info;
			FileEnumerator enumerator;
			try {
				enumerator = newpath.enumerate_children (FileAttribute.STANDARD_NAME+","+FileAttribute.STANDARD_TYPE, 0);
				while ((file_info = enumerator.next_file ()) != null) {
					var fname=file_info.get_name();
					var ftype=file_info.get_file_type();
					if (ftype==FileType.DIRECTORY) {
						continue;
					}
					if (fname.has_suffix(".pc")==false) {
						continue;
					}
					var final_name=fname.substring(0,fname.length-3); // remove .pc extension
					this.pkgconfigs.add(final_name); // add to the list
				}
			} catch (Error e) {
				return;
			}
		}
		public bool contains(string element) {
			return this.pkgconfigs.contains(element);
		}
	}
}
