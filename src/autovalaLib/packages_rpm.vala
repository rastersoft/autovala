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

			string[] definitions = {};
			Gee.Map<string,string> single_keys = new Gee.HashMap<string,string>();
			Gee.Map<string,string> multi_keys = new Gee.HashMap<string,string>();

			var f_control = File.new_for_path(Path.build_filename(path,"%s.spec".printf(this.config.globalData.projectName)));
			try {
				if (f_control.query_exists()) {
					// store the original file to keep manually-added fields
					bool source = true;
					var dis = new DataInputStream (f_control.read ());
					string line;
					string? key = null;
					string data = "";
					var defs = true;
					var multiline = false;

					while ((line = dis.read_line (null)) != null) {
						if (line.has_prefix("#")) {
							continue;
						}
						if (defs && (line.has_prefix("%define"))) {
							definitions += line;
							continue;
						}
						defs = false;

						if (multiline) {
							if (line == "") {
								multiline = false;
								multi_keys.set(key,data);
								data = "";
							} else {
								data += line+"\n";
							}
							continue;
						}

						if (line == "") {
							continue;
						}

						if (line[0] == '%') { // multiline entry
							key = line.substring(1);
							multiline = true;
							data = "";
							continue;
						}

						var pos = line.index_of_char(':');
						if (pos == -1) {
							continue;
						}
						key = line.substring(0,pos).strip();
						data = line.substring(pos+1).strip();
						single_keys.set(key,data);
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

				foreach (var def in definitions) {
					of.put_string(def+"\n");
				}
				if (definitions.length > 0) {
					of.put_string("\n");
				}

				if (!single_keys.has_key("Name")) {
					of.put_string("Name: %s\n".printf(this.config.globalData.projectName));
				} else {
					of.put_string("Name: %s\n".printf(single_keys.get("Name")));
				}
				if (!single_keys.has_key("Version")) {
					of.put_string("Version: %s\n".printf(this.version));
				} else {
					of.put_string("Version: %s\n".printf(single_keys.get("Version")));
				}
				if (!single_keys.has_key("Release")) {
					of.put_string("Release: 1\n");
				} else {
					of.put_string("Release: %s\n".printf(single_keys.get("Release")));
				}
				if (!single_keys.has_key("License")) {
					of.put_string("License: Unknown/not set\n");
				} else {
					of.put_string("License: %s\n".printf(single_keys.get("License")));
				}

				if (!single_keys.has_key("Summary")) {
					of.put_string("Summary: %s\n".printf(this.summary));
				} else {
					of.put_string("Summary: %s\n".printf(single_keys.get("Summary")));
				}

				foreach (var key in single_keys.keys) {
					if ((key == "Requires") || (key == "BuildRequires") || (key == "Name") || (key == "Version") || (key == "Release") || (key == "License") || (key == "Summary")) {
						continue;
					}
					of.put_string("%s: %s\n".printf(key,single_keys.get(key)));
				}
				of.put_string("\n");

				foreach(var element in this.source_packages) {
					of.put_string("BuildRequires: %s\n".printf(element));
				}
				of.put_string("\n");
				foreach(var element in this.binary_packages) {
					of.put_string("Requires: %s\n".printf(element));
				}
				of.put_string("\n");

				if (multi_keys.has_key("description")) {
					of.put_string("%%description\n%s\n".printf(multi_keys.get("description")));
				} else {
					of.put_string("%description\n");
					foreach(var line in this.description.split("\n")) {
						if (line.strip() == "") {
							line = ".";
						}
						of.put_string("%s\n".printf(line));
					}
					of.put_string("\n");
				}

				if (!multi_keys.has_key("files")) {
					of.put_string("%files\n/*\n\n");
				}

				if (!multi_keys.has_key("build")) {
					of.put_string("%build\nmkdir -p ${RPM_BUILD_DIR}\ncd ${RPM_BUILD_DIR}; cmake -DCMAKE_INSTALL_PREFIX=/usr -DGSETTINGS_COMPILE=OFF -DICON_UPDATE=OFF ../..\nmake -C ${RPM_BUILD_DIR}\n\n");
				}

				if (!multi_keys.has_key("install")) {
					of.put_string("%install\nmake install -C ${RPM_BUILD_DIR} DESTDIR=%{buildroot}\n\n");
				}

				if ((!multi_keys.has_key("pre")) && (this.pre_inst.length != 0)) {
					of.put_string("%pre\n");
					foreach(var line in this.pre_inst) {
						of.put_string(line+"\n");
					}
					of.put_string("\n");
				}

				if ((!multi_keys.has_key("post")) && (this.post_inst.length != 0)) {
					of.put_string("%post\n");
					foreach(var line in this.post_inst) {
						of.put_string(line+"\n");
					}
					of.put_string("\n");
				}

				if ((!multi_keys.has_key("preun")) && (this.pre_rm.length != 0)) {
					of.put_string("%preun\n");
					foreach(var line in this.pre_rm) {
						of.put_string(line+"\n");
					}
					of.put_string("\n");
				}

				if ((!multi_keys.has_key("postun")) && (this.post_rm.length != 0)) {
					of.put_string("%postun\n");
					foreach(var line in this.post_rm) {
						of.put_string(line+"\n");
					}
					of.put_string("\n");
				}

				if (!multi_keys.has_key("clean")) {
					of.put_string("%clean\nrm -rf %{buildroot}\n\n");
				}

				foreach (var key in multi_keys.keys) {
					if (key == "description") {
						continue;
					}
					of.put_string("%%%s\n%s\n".printf(key,multi_keys.get(key)));
				}

				dis.close();
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to write data to rpmbuild/SPECS/SPEC file (%s)").printf(e.message));
				return true;
			}
			return false;
		}
	}
}
