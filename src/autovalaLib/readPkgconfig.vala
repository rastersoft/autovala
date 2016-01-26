/*
 Copyright 2013/2014 (C) Raster Software Vigo (Sergio Costas)

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
		private Gee.Map<string,string> ?paths;

		public ReadPkgConfig() {
			this.pkgconfigs = new Gee.HashSet<string>();
			this.paths = new Gee.HashMap<string,string>();
			var default_search_path=string.join(":",
					"/usr/lib",
					"/usr/lib64",
					"/usr/share",
					"/usr/lib/i386-linux-gnu",
					"/usr/lib/x86_64-linux-gnu",
					"/usr/local/lib",
					"/usr/local/lib64",
					"/usr/local/share",
					"/usr/local/lib/i386-linux-gnu",
					"/usr/local/lib/x86_64-linux-gnu");
			var env_search_path=GLib.Environment.get_variable("PKG_CONFIG_PATH");

			var search_path=(env_search_path!=null) ? env_search_path : default_search_path;
			foreach(var element in search_path.split(":")) {
				this.fill_pkgconfig_files(element);
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
					if (!this.paths.has_key(final_name)) {
						this.paths.set(final_name,Path.build_filename(basepath,"pkgconfig",fname)); // store the path found
					}
				}
			} catch (Error e) {
				return;
			}
		}
		public bool contains(string element) {
			return this.pkgconfigs.contains(element);
		}

		public string? find_path(string element) {
			if (!this.paths.has_key(element)) {
				return null;
			}
			return this.paths.get(element);
		}
	}
}
