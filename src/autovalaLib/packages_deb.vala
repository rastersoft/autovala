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

	private class packages_deb : packages {

		private Gee.List<string> source_packages;
		private Gee.List<string> binary_packages;

		public bool create_deb_package() {

			this.source_packages = new Gee.ArrayList<string>();
			this.binary_packages = new Gee.ArrayList<string>();

			// These packages are always needed to build this package
			this.source_packages.add("cmake");
			this.source_packages.add("build-essential");
			this.source_packages.add("gettext");
			this.source_packages.add("po-debconf");

			var path = Path.build_filename(this.config.globalData.projectFolder,"debian");
			var fpath = File.new_for_path(path);

			// just in case there is a file called "debian"
			try {
				if (fpath.query_exists()) {
					fpath.delete();
				}
			} catch (Error e) {
			}

			try {
				fpath.make_directory_with_parents();
			} catch (Error e) {
			}

			this.fill_dependencies(this.source_dependencies,this.source_packages);
			this.fill_dependencies(this.extra_source_dependencies,this.source_packages);
			this.fill_dependencies(this.dependencies,this.binary_packages);
			this.fill_dependencies(this.extra_dependencies,this.binary_packages);
			this.create_control(path);

			return false;
		}

		private void fill_dependencies(Gee.List<string> origin,Gee.List<string> destination) {
			foreach (var element in origin) {
				string[] spawn_args = {"dpkg", "-S", element};
				string ls_stdout;
				int ls_status;

				try {
					if (!Process.spawn_sync (null,spawn_args,Environ.get(),SpawnFlags.SEARCH_PATH,null,out ls_stdout,null,out ls_status)) {
						ElementBase.globalData.addWarning(_("Failed to launch dpkg for the file %s").printf(element));
						return;
					}
					if (ls_status != 0) {
						ElementBase.globalData.addWarning(_("Error %d when launching dpkg for the file %s").printf(ls_status,element));
						return;
					}
				} catch (SpawnError e) {
					ElementBase.globalData.addWarning(_("Exception '%s' when launching dpkg for the file %s").printf(e.message,element));
					return;
				}
				var elements = ls_stdout.split(":");
				if (elements.length == 0) {
					ElementBase.globalData.addWarning(_("Can't find a package for the file %s").printf(element));
				} else 	if (!destination.contains(elements[0])) {
					destination.add(elements[0]);
				}
			}
		}

		private bool create_control(string path) {

			Gee.Map<string,string> source_keys = new Gee.HashMap<string,string>();
			Gee.Map<string,string> binary_keys = new Gee.HashMap<string,string>();

			var f_control = File.new_for_path(Path.build_filename(path,"control"));
			try {
				if (f_control.query_exists()) {
					/*bool source = true;
					var dis = new DataInputStream (file.read ());
					string line;
					while ((line = dis.read_line (null)) != null) {
						if (line == "") {
							source = false;
							continue;
						}
					}*/
					f_control.delete();
				}
			} catch (Error e) {
				ElementBase.globalData.addWarning(_("Failed to delete debian/control file"));
			}
			try {
				var dis = f_control.create_readwrite(GLib.FileCreateFlags.PRIVATE);
				var of = new DataOutputStream(dis.output_stream as FileOutputStream);
				bool not_first;
				
				of.put_string("Source: %s\n".printf(this.config.globalData.projectName));
				of.put_string("Maintainer: %s <%s>\n".printf(this.author_package,this.email_package));
				of.put_string("Priority: optional\n");
				of.put_string("Build-Depends: ");
				not_first = false;
				foreach(var element in this.source_packages) {
					if (not_first) {
						of.put_string(", ");
					}
					not_first = true;
					of.put_string(element);
				}

				of.put_string("\n\n");

				of.put_string("Package: %s\n".printf(this.config.globalData.projectName));
				of.put_string("Architecture: any\n");
				of.put_string("Depends: ");
				not_first = false;
				foreach(var element in this.binary_packages) {
					if (not_first) {
						of.put_string(", ");
					}
					not_first = true;
					of.put_string(element);
				}
				of.put_string("\nDescription:");
				foreach(var line in this.description.split("\n")) {
					of.put_string(" %s\n".printf(line));
				}
//				of.put_string("\n");
				dis.close();
			} catch (Error e) {
			}
			return false;
		}
	}
}
