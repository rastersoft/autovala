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

		private void print_key(DataOutputStream of,Gee.HashMultiMap<string,string> keylist,bool multiline,string key,string val) {

			Gee.Collection<string> final_value;
			if (!keylist.contains(key)) {
				final_value = new Gee.ArrayList<string>();
				final_value.add(val);
			} else {
				final_value = keylist.get(key);
			}
			foreach (var line in final_value) {
				if (line.strip() == "") {
					continue;
				}
				if (multiline) {
					of.put_string("%%%s\n%s\n".printf(key,line));
				} else {
					of.put_string("%s: %s".printf(key,line));
				}
				if (line.get_char(line.length-1) != '\n') {
					of.put_string("\n");
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
			Gee.HashMultiMap<string,string> single_keys = new Gee.HashMultiMap<string,string>();
			Gee.HashMultiMap<string,string> multi_keys = new Gee.HashMultiMap<string,string>();

            var f_control_path = Path.build_filename(path,"%s.spec".printf(this.config.globalData.projectName));
            var f_control_base_path = Path.build_filename(this.config.globalData.projectFolder,"packages","rpm.spec.base");
			var f_control = File.new_for_path(f_control_path);
			var f_control_base = File.new_for_path(f_control_base_path);
			try {
				if (f_control_base.query_exists()) {
					// store the original file to keep manually-added fields
					var dis = new DataInputStream (f_control_base.read ());
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
								print("multi: "+key+"\n");
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
						if ((key == "Requires") || (key == "BuildRequires")){
							var package = data;
							var min = data.length;
							var pos1 = data.index_of_char('=');
							var pos2 = data.index_of_char('<');
							var pos3 = data.index_of_char('>');
							if ((pos1 != -1) && (pos1 < min)) {
								min = pos1;
							}
							if ((pos2 != -1) && (pos2 < min)) {
								min = pos2;
							}
							if ((pos3 != -1) && (pos3 < min)) {
								min = pos3;
							}
							if (min != data.length) {
								package = data.substring(0,min).strip();
							}
							if (key == "Requires") {
								if (this.binary_packages.index_of(package) == -1) {
									this.binary_packages.add(package);
								}
							} else {
								if (this.source_packages.index_of(package) == -1) {
									this.source_packages.add(package);
								}
							}
						}
						single_keys.set(key,data);
					}
					if (multiline) {
						multi_keys.set(key,data);
					}
				}
			} catch (Error e) {
				ElementBase.globalData.addWarning(_("Failed to delete rpmbuild/SPECS/SPEC file (%s)").printf(e.message));
			}
			if (f_control.query_exists()) {
				f_control.delete();
			}
			try {
				var dis = f_control.create_readwrite(GLib.FileCreateFlags.PRIVATE);
				var of = new DataOutputStream(dis.output_stream as FileOutputStream);

				foreach (var def in definitions) {
					of.put_string(def+"\n");
				}
				if (definitions.length > 0) {
					of.put_string("\n");
				}

				this.print_key(of,single_keys,false,"Name",this.config.globalData.projectName);
    			of.put_string("Version: %s\n".printf(this.version));
    			this.print_key(of,single_keys,false,"Release","1");
				this.print_key(of,single_keys,false,"License","Unknown/not set");
				this.print_key(of,single_keys,false,"Summary",this.summary);

				foreach (var key in single_keys.get_keys()) {
					if ((key == "Requires") || (key == "BuildRequires") || (key == "Name") || (key == "Version") || (key == "Release") || (key == "License") || (key == "Summary")) {
						continue;
					}
					foreach (var line in single_keys.get(key)) {
						of.put_string("%s: %s\n".printf(key,line));
					}
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

				if (multi_keys.contains("description")) {
					foreach (var line in single_keys.get("description")) {
						of.put_string("%%description\n%s\n".printf(line));
					}
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

				this.print_key(of,multi_keys,true,"files","*\n");
				this.print_key(of,multi_keys,true,"build","mkdir -p ${RPM_BUILD_DIR}\ncd ${RPM_BUILD_DIR}; cmake -DCMAKE_INSTALL_PREFIX=/usr -DGSETTINGS_COMPILE=OFF -DICON_UPDATE=OFF ../..\nmake -C ${RPM_BUILD_DIR}");
				this.print_key(of,multi_keys,true,"install","make install -C ${RPM_BUILD_DIR} DESTDIR=%{buildroot}");
				var multiline = "";
				foreach(var line in this.pre_inst) {
					multiline += line+"\n";
				}
				this.print_key(of,multi_keys,true,"pre",multiline);
				multiline = "";
				foreach(var line in this.post_inst) {
					multiline += line+"\n";
				}
				this.print_key(of,multi_keys,true,"post",multiline);
				multiline = "";
				foreach(var line in this.pre_rm) {
					multiline += line+"\n";
				}
				this.print_key(of,multi_keys,true,"preun",multiline);
				multiline = "";
				foreach(var line in this.post_rm) {
					multiline += line+"\n";
				}
				this.print_key(of,multi_keys,true,"postun",multiline);
				this.print_key(of,multi_keys,true,"clean","rm -rf %{buildroot}");

				foreach (var key in multi_keys.get_keys()) {
					if ((key == "description") || (key == "files") || (key == "build") || (key == "install") || (key == "pre") || (key == "post") || (key == "preun") || (key == "postun") || (key == "clean")) {
						continue;
					}
					foreach (var line in multi_keys.get(key)) {
						of.put_string("%%%s\n%s\n".printf(key,line));
					}
				}

				dis.close();
				Posix.chmod(f_control_path,420); // 644 permissions
			} catch (Error e) {
				ElementBase.globalData.addError(_("Failed to write data to rpmbuild/SPECS/SPEC file (%s)").printf(e.message));
				return true;
			}
			return false;
		}
	}
}
