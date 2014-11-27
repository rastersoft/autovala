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

	private class packages_rpm : packages {

		private Gee.List<string> source_packages;
		private Gee.List<string> binary_packages;

		public bool create_rpm_package() {

			this.write_defaults();

			this.source_packages = new Gee.ArrayList<string>();
			this.binary_packages = new Gee.ArrayList<string>();

			// These packages are always needed to build this package
			this.source_packages.add("gcc");
			this.source_packages.add("gcc-c++");

			var path = Path.build_filename(this.config.globalData.projectFolder,"rpmbuild/SPECS");
			var fpath = File.new_for_path(path);

			try {
				fpath.make_directory_with_parents();
			} catch (Error e) {
			}

			this.fill_dependencies(this.source_dependencies,this.source_packages);
			this.fill_dependencies(this.extra_source_dependencies,this.source_packages);
			this.fill_dependencies(this.dependencies,this.binary_packages);
			this.fill_dependencies(this.extra_dependencies,this.binary_packages);

			if (this.create_spec(path)) {
				return true;
			}

			return false;
		}

		/**
		 * Uses rpm to discover to which package belongs each of the dependencies
		 * @param origin The list with the dependency files
		 * @param destination The list into which store the packages
		 */
		private void fill_dependencies(Gee.List<string> origin,Gee.List<string> destination) {

			foreach (var element in origin) {
				string[] spawn_args = {"rpm","--queryformat", "%{=NAME}\n", "-qf", element};
				string ls_stdout;
				int ls_status;

				try {
					if (!Process.spawn_sync (null,spawn_args,Environ.get(),SpawnFlags.SEARCH_PATH,null,out ls_stdout,null,out ls_status)) {
						ElementBase.globalData.addWarning(_("Failed to launch rpm for the file %s").printf(element));
						return;
					}
					if (ls_status != 0) {
						ElementBase.globalData.addWarning(_("Error %d when launching rpm for the file %s").printf(ls_status,element));
						return;
					}
				} catch (SpawnError e) {
					ElementBase.globalData.addWarning(_("Exception '%s' when launching rpm for the file %s").printf(e.message,element));
					return;
				}
				var elements = ls_stdout.split("\n");
				if (elements.length == 0) {
					ElementBase.globalData.addWarning(_("Can't find a package for the file %s").printf(element));
				} else 	if (!destination.contains(elements[0])) {
					destination.add(elements[0]);
				}
			}
		}

		/**
		 * Creates de rpmbuild/SPECS/SPEC file
		 * @param path The 'rpmbuild/SPECS' path
		 * @return false if everything went OK; true if there was an error
		 */
		private bool create_spec(string path) {

			Gee.Map<string,string> source_keys = new Gee.HashMap<string,string>();
			Gee.Map<string,string> binary_keys = new Gee.HashMap<string,string>();

			var f_control = File.new_for_path(Path.build_filename(path,"%s.spec".printf(this.config.globalData.projectName)));
			try {
				if (f_control.query_exists()) {
					bool source = true;
					var dis = new DataInputStream (f_control.read ());
					string line;
					string last_key = "";
					string? key = "";
					string data = "";
					while ((line = dis.read_line (null)) != null) {
						if (line == "") {
							source = false;
							key = null;
							continue;
						}
						if (line[0] == '#') {
							continue;
						}
						if ((line[0] == ' ') || (line[0] == '\t')) {
							if (key == null) {
								continue;
							}
							if (source) {
								data = source_keys.get(key);
							} else {
								data = binary_keys.get(key);
							}
							data += "\n"+line;
							if (source) {
								source_keys.set(key,data);
							} else {
								binary_keys.set(key,data);
							}
							continue;
						}
						var pos = line.index_of_char(':');
						if (pos == -1) {
							continue;
						}
						key = line.substring(0,pos).strip();
						data = line.substring(pos+1).strip();
						if (source) {
							source_keys.set(key,data);
						} else {
							binary_keys.set(key,data);
						}
					}
					f_control.delete();
				}
			} catch (Error e) {
				ElementBase.globalData.addWarning(_("Failed to delete rpmbuild/SPECS/SPEC file (%s)").printf(e.message));
			}
			try {
				var dis = f_control.create_readwrite(GLib.FileCreateFlags.PRIVATE);
				var of = new DataOutputStream(dis.output_stream as FileOutputStream);
				bool not_first;

				if (!source_keys.has_key("Name")) {
					of.put_string("Name: %s\n".printf(this.config.globalData.projectName));
				} else {
					of.put_string("Name: %s\n".printf(source_keys.get("Name")));
				}

				if (!source_keys.has_key("Version")) {
					of.put_string("Version: %s\n".printf(this.version));
				} else {
					of.put_string("Version: %s\n".printf(source_keys.get("Version")));
				}

				if (!source_keys.has_key("Release")) {
					of.put_string("Release: 1\n");
				} else {
					of.put_string("Release: %s\n".printf(source_keys.get("Release")));
				}

				foreach (var key in source_keys.keys) {
					if ((key == "Build-Depends") || (key == "Maintainer") || (key == "Source")) {
						continue;
					}
					of.put_string("%s: %s\n".printf(key,source_keys.get(key)));
				}

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

				foreach (var key in binary_keys.keys) {
					if ((key == "Name") || (key == "Version") || (key == "Release")) {
						continue;
					}
					of.put_string("%s: %s\n".printf(key,binary_keys.get(key)));
				}

				if (!binary_keys.has_key("Package")) {
					of.put_string("Package: %s\n".printf(this.config.globalData.projectName));
				}

				if (!binary_keys.has_key("Architecture")) {
					of.put_string("Architecture: any\n");
				}
				of.put_string("Depends: ");
				not_first = false;

				foreach(var element in this.binary_packages) {
					if (not_first) {
						of.put_string(", ");
					}
					not_first = true;
					of.put_string(element);
				}
				of.put_string("\n");

				if (!binary_keys.has_key("Description")) {
					of.put_string("Description:");
					foreach(var line in this.description.split("\n")) {
						if (line.strip() == "") {
							line = ".";
						}
						of.put_string(" %s\n".printf(line));
					}
				} else {
					of.put_string("Description: %s\n".printf(binary_keys.get("Description")));
				}

				dis.close();
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to write data to rpmbuild/SPECS/SPEC file (%s)").printf(e.message));
				return true;
			}
			return false;
		}

		/**
		 * Creates de debian/rules file
		 * @param path The 'debian' path
		 * @return false if everything went OK; true if there was an error
		 */
		private bool create_rules(string path) {

			var f_rules = File.new_for_path(Path.build_filename(path,"rules"));
			if (f_rules.query_exists()) {
				// if the file already exists, don't touch it
				return false;
			}

			try {
				var dis = f_rules.create_readwrite(GLib.FileCreateFlags.PRIVATE);
				var of = new DataOutputStream(dis.output_stream as FileOutputStream);

				var o_rules = File.new_for_path(Path.build_filename(AutoValaConstants.PKGDATADIR,"debian","rules"));
				var dis2 = new DataInputStream (o_rules.read ());

				string line;
				while ((line = dis2.read_line (null)) != null) {
					var line2 = line.replace("%(PROJECT_NAME)",this.config.globalData.projectName);
					of.put_string(line2+"\n");
				}
				dis.close();
				dis2.close();
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to write data to debian/rules file (%s)").printf(e.message));
				f_rules.delete();
				return true;
			}
			return false;
		}

		/**
		 * Creates de debian/preinst file
		 * @param path The 'debian' path
		 * @return false if everything went OK; true if there was an error
		 */
		private bool create_preinst(string path) {

			if (this.pre_inst.length == 0) {
				return false;
			}

			var f_rules = File.new_for_path(Path.build_filename(path,"preinst"));
			if (f_rules.query_exists()) {
				// if the file already exists, don't touch it
				return false;
			}

			try {
				var dis = f_rules.create_readwrite(GLib.FileCreateFlags.PRIVATE);
				var of = new DataOutputStream(dis.output_stream as FileOutputStream);

				of.put_string("#!/bin/sh\n\n");

				foreach (var line in this.pre_inst) {
					of.put_string(line+"\n");
				}
				dis.close();
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to write data to debian/preinst file (%s)").printf(e.message));
				f_rules.delete();
				return true;
			}
			return false;
		}

		/**
		 * Creates de debian/prerm file
		 * @param path The 'debian' path
		 * @return false if everything went OK; true if there was an error
		 */
		private bool create_prerm(string path) {

			if (this.pre_rm.length == 0) {
				return false;
			}

			var f_rules = File.new_for_path(Path.build_filename(path,"prerm"));
			if (f_rules.query_exists()) {
				// if the file already exists, don't touch it
				return false;
			}

			try {
				var dis = f_rules.create_readwrite(GLib.FileCreateFlags.PRIVATE);
				var of = new DataOutputStream(dis.output_stream as FileOutputStream);

				of.put_string("#!/bin/sh\n\n");

				foreach (var line in this.pre_rm) {
					of.put_string(line+"\n");
				}
				dis.close();
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to write data to debian/prerm file (%s)").printf(e.message));
				f_rules.delete();
				return true;
			}
			return false;
		}

		/**
		 * Creates de debian/postinst file
		 * @param path The 'debian' path
		 * @return false if everything went OK; true if there was an error
		 */
		private bool create_postinst(string path) {

			if (this.post_inst.length == 0) {
				return false;
			}

			var f_rules = File.new_for_path(Path.build_filename(path,"postinst"));
			if (f_rules.query_exists()) {
				// if the file already exists, don't touch it
				return false;
			}

			try {
				var dis = f_rules.create_readwrite(GLib.FileCreateFlags.PRIVATE);
				var of = new DataOutputStream(dis.output_stream as FileOutputStream);

				of.put_string("#!/bin/sh\n\n");

				foreach (var line in this.post_inst) {
					of.put_string(line+"\n");
				}
				dis.close();
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to write data to debian/postinst file (%s)").printf(e.message));
				f_rules.delete();
				return true;
			}
			return false;
		}

		/**
		 * Creates de debian/postrm file
		 * @param path The 'debian' path
		 * @return false if everything went OK; true if there was an error
		 */
		private bool create_postrm(string path) {

			if (this.post_rm.length == 0) {
				return false;
			}

			var f_rules = File.new_for_path(Path.build_filename(path,"postrm"));
			if (f_rules.query_exists()) {
				// if the file already exists, don't touch it
				return false;
			}

			try {
				var dis = f_rules.create_readwrite(GLib.FileCreateFlags.PRIVATE);
				var of = new DataOutputStream(dis.output_stream as FileOutputStream);

				of.put_string("#!/bin/sh\n\n");

				foreach (var line in this.post_rm) {
					of.put_string(line+"\n");
				}
				dis.close();
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to write data to debian/postrm file (%s)").printf(e.message));
				f_rules.delete();
				return true;
			}
			return false;
		}

	}
}
